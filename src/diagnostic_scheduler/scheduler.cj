package compiler_diagnostic.diagnostic_scheduler

import std.collection.*
import compiler_diagnostic.common.*
import compiler_diagnostic.diagnostics.DiagnosticMessage
import compiler_diagnostic.diagnostics.ErrorCode
import compiler_diagnostic.diagnostics.Severity
import compiler_diagnostic.diagnostics.SourceLoc
import compiler_diagnostic.diagnostics.Span
import compiler_diagnostic.diagnostics.RelatedInfo
import compiler_diagnostic.diagnostics.FixSuggestion
import compiler_diagnostic.semantic_trace.Trace
import compiler_diagnostic.semantic_trace.TraceSerde
import compiler_diagnostic.semantic_trace.EventEmitter
import compiler_diagnostic.semantic_trace.MachineEvent
import compiler_diagnostic.local_diagnostic_lib.PatternMatcher
import compiler_diagnostic.local_diagnostic_lib.MatchResult

/// ErrorCode 映射表（复用既有码，不新增任何 ErrorCode）
func errorCodeForPattern(id: String): ErrorCode {
    match (id) {
        case "RT-ARRAY-OOB" => ErrorCode.RuntimeIndexOutOfBounds
        case "TP-TYPE-MISMATCH" => ErrorCode.TypeMismatch
        case "RT-USE-AFTER-MOVE" => ErrorCode.RuntimeUseAfterMove
        case "SE-NON-EXHAUSTIVE-MATCH" => ErrorCode.SemaNonExhaustiveMatch
        case _ => ErrorCode.SystemInternalError
    }
}

/// 诊断结果（复用 DiagnosticMessage；新增 candidateCode 字段，不侵入 diagnostic_core）
public struct DiagnosticResult {
    public var matched: Bool
    public var patternId: Option<String>
    public var message: DiagnosticMessage
    public var candidateCode: String

    // 调用方以具名实参构造，形参须带 !；无显式 init 时仓颉只提供 0 参构造。
    public init(matched!: Bool, patternId!: Option<String>, message!: DiagnosticMessage,
        candidateCode!: String) {
        this.matched = matched
        this.patternId = patternId
        this.message = message
        this.candidateCode = candidateCode
    }
}

/// 诊断调度中枢：统一管理在线 / 离线两条输入路径。
public class DiagnosticScheduler {

    /// 在线路径：静态扫描源码 -> 导出 trace（OQ1 务实实现）
    public static func run(sourceFile: String, exportTrace: String): Result<Int64> {
        let trace = EventEmitter.scanSourceToTrace(sourceFile)
        return TraceSerde.exportToFile(trace, exportTrace)
    }

    /// 离线路径：加载 trace -> 匹配 -> 构造结果
    public static func diagnose(tracePath: String): Result<DiagnosticResult> {
        let lr = TraceSerde.loadFromFile(tracePath)
        if (lr.isErr()) {
            return Err("无法加载 Trace 文件: " + tracePath)
        }
        let trace = match (lr) {
            case Ok(t) => t
            case Err(_) => EventEmitter.buildFromEvents(Array<MachineEvent>(), entry: "<none>")
        }
        let mr = PatternMatcher.`match`(trace)
        if (mr.matched) {
            return Ok(DiagnosticScheduler.buildMatched(mr))
        }
        return Ok(DiagnosticScheduler.buildUnmatched(trace))
    }

    /// 文本渲染（命中：位置/根因/修复样例；未命中：提示 + 原始信息回退）
    public static func renderText(result: DiagnosticResult): String {
        let sb = StringBuilder()
        if (result.matched) {
            sb.append("命中故障模式: ")
            sb.append(match (result.patternId) { case Some(id) => id case None => "?" })
            sb.append("\n错误码: ")
            sb.append(result.message.code.code())
            sb.append("\n严重度: ")
            sb.append(result.message.severity)
            sb.append("\n位置: ")
            sb.append(spanToText(result.message.span))
            sb.append("\n根因: ")
            sb.append(result.message.rootCause)
            sb.append("\n")
            sb.append(fixText(result))
            sb.append("\n")
        } else {
            sb.append("未命中：")
            sb.append(result.message.message)
            sb.append("\n")
        }
        return sb.toString()
    }

    /// JSON 渲染（复用 escapeJson 风格，附加 candidateCode / patternId）
    public static func renderJson(result: DiagnosticResult): String {
        let sb = StringBuilder()
        sb.append("{")
        sb.append("\"matched\":")
        sb.append(boolToJson(result.matched))
        sb.append(",\"patternId\":")
        sb.append(match (result.patternId) {
            case Some(id) => "\"" + TraceSerde.escapeJson(id) + "\""
            case None => "null"
        })
        sb.append(",\"code\":\"")
        sb.append(result.message.code.code())
        sb.append("\",\"severity\":\"")
        sb.append(result.message.severity)
        sb.append("\",\"location\":\"")
        sb.append(TraceSerde.escapeJson(spanToText(result.message.span)))
        sb.append("\"")
        sb.append(",\"rootCause\":\"")
        sb.append(TraceSerde.escapeJson(result.message.rootCause))
        sb.append("\"")
        sb.append(",\"candidateCode\":\"")
        sb.append(TraceSerde.escapeJson(result.candidateCode))
        sb.append("\"")
        sb.append("}")
        return sb.toString()
    }

    // ===== 内部 =====

    private static func buildMatched(mr: MatchResult): DiagnosticResult {
        let code = errorCodeForPattern(match (mr.patternId) { case Some(v) => v case None => "" })
        let sev = match (mr.severity) { case Some(s) => s.label() case None => "error" }
        let loc = match (mr.location) {
            case Some(sp) => sp
            case None => Span(start: SourceLoc(line: 0, column: 0), end: SourceLoc(line: 0, column: 0))
        }
        let root = match (mr.rootCause) { case Some(r) => r case None => "" }
        // None 是泛型构造子，match 两臂间无法反推类型，须显式给出类型实参。
        let fix = match (mr.fixSuggestion) { case Some(f) => Some(f) case None => None<FixSuggestion> }
        let cand = match (mr.candidateCode) { case Some(c) => c case None => "" }
        let msg = DiagnosticMessage(
            code: code,
            message: root,
            span: loc,
            severity: sev,
            fix: fix,
            related: arrayToList(mr.relatedInfo),
            candidates: None,
            rootCause: root)
        return DiagnosticResult(matched: true, patternId: mr.patternId, message: msg, candidateCode: cand)
    }

    private static func buildUnmatched(trace: Trace): DiagnosticResult {
        let excType = firstExceptionType(trace)
        let excMsg = firstExceptionMessage(trace)
        let entry = trace.program.entry
        let fb = "本地故障模式库暂未覆盖该故障 (exception.type=" + excType +
            ", message=" + excMsg + ", program=" + entry + ")"
        let span = Span(start: SourceLoc(line: 0, column: 0), end: SourceLoc(line: 0, column: 0))
        let msg = DiagnosticMessage(
            code: ErrorCode.SystemInternalError,
            message: fb,
            span: span,
            severity: "warning",
            fix: None,
            related: ArrayList<RelatedInfo>(),
            candidates: None,
            rootCause: fb)
        return DiagnosticResult(matched: false, patternId: None, message: msg, candidateCode: "")
    }

    private static func firstExceptionType(trace: Trace): String {
        var result = ""
        for (e in trace.machineEvents) {
            let t = match (e.exception) { case Some(exc) => exc.`type` case None => "" }
            if (t != "") {
                result = t
                break
            }
        }
        return result
    }

    private static func firstExceptionMessage(trace: Trace): String {
        var result = ""
        for (e in trace.machineEvents) {
            let m = match (e.exception) { case Some(exc) => exc.message case None => "" }
            if (m != "") {
                result = m
                break
            }
        }
        return result
    }

    private static func arrayToList(arr: Array<RelatedInfo>): List<RelatedInfo> {
        let l = ArrayList<RelatedInfo>()
        for (r in arr) {
            l.add(r)
        }
        return l
    }

    private static func spanToText(span: Span): String {
        return span.start.file + ":" + span.start.line.toString() + ":" + span.start.column.toString()
    }

    private static func fixText(result: DiagnosticResult): String {
        match (result.message.fix) {
            case Some(f) => "修复建议: " + f.description + "\n参考代码:\n" + result.candidateCode
            case None => ""
        }
    }

    private static func boolToJson(b: Bool): String {
        if (b) {
            "true"
        } else {
            "false"
        }
    }
}
