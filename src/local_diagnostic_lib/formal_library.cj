package compiler_diagnostic.local_diagnostic_lib

import compiler_diagnostic.diagnostics.Severity
import compiler_diagnostic.diagnostics.ErrorCategory
import compiler_diagnostic.diagnostics.FixSuggestion
import compiler_diagnostic.diagnostics.RelatedInfo
import compiler_diagnostic.diagnostics.Span

/// 单条事件匹配条件（可序列化、可人工编辑）
public struct EventCondition {
    public var kind: Option<String>
    public var exceptionType: Option<String>
    public var hasException: Bool
    public var path: Option<String>
    public var symbolName: Option<String>
    public var symbolType: Option<String>
    public var negate: Bool
    // 具名实参构造（各形参均带默认值，故 EventCondition() 零参调用依旧可用）。
    // 采用"一次性不可变构造"而非"先 new 再逐字段赋值"：仓颉禁止 lambda 捕获 var（可变）变量，
    // 而本结构会被 Array<EventCondition>(1, { _ => c }) 的 lambda 捕获。
    public init(kind!: Option<String> = None, exceptionType!: Option<String> = None,
        hasException!: Bool = false, path!: Option<String> = None,
        symbolName!: Option<String> = None, symbolType!: Option<String> = None,
        negate!: Bool = false) {
        this.kind = kind
        this.exceptionType = exceptionType
        this.hasException = hasException
        this.path = path
        this.symbolName = symbolName
        this.symbolType = symbolType
        this.negate = negate
    }
}

/// 匹配规约：朴素序列（子串）匹配；未来可升级为图 / 时间窗
public struct MatchSpec {
    public var priority: Int64
    public var sequence: Array<EventCondition>
    public var requireAll: Bool
    public init(priority!: Int64 = 0, sequence!: Array<EventCondition>, requireAll!: Bool = true) {
        this.priority = priority
        this.sequence = sequence
        this.requireAll = requireAll
    }
}

/// 修复样例（与 FaultPattern 一一绑定）
public struct RepairSample {
    public var rootCause: String
    public var fixSuggestion: FixSuggestion
    public var candidateCode: String
    public var relatedInfo: Array<RelatedInfo>
    public var location: Option<Span>

    // 具名实参构造：调用方以 RepairSample(rootCause:..., fixSuggestion:..., ...) 形式构造，
    // 形参须带 ! 才支持具名实参；无显式 init 时仓颉只提供 0 参构造，导致 "expected 0 arguments"。
    public init(rootCause!: String, fixSuggestion!: FixSuggestion, candidateCode!: String,
        relatedInfo!: Array<RelatedInfo>, location!: Option<Span>) {
        this.rootCause = rootCause
        this.fixSuggestion = fixSuggestion
        this.candidateCode = candidateCode
        this.relatedInfo = relatedInfo
        this.location = location
    }
}

/// 故障模式
public struct FaultPattern {
    public var id: String
    public var category: ErrorCategory
    public var severity: Severity
    public var title: String
    public var description: String
    public var matchSpec: MatchSpec
    public var repair: RepairSample

    public init(id!: String, category!: ErrorCategory, severity!: Severity, title!: String,
        description!: String, matchSpec!: MatchSpec, repair!: RepairSample) {
        this.id = id
        this.category = category
        this.severity = severity
        this.title = title
        this.description = description
        this.matchSpec = matchSpec
        this.repair = repair
    }
}

/// 正式故障库（OQ4 确认：内嵌为代码常量，确定性加载，无 IO、无随机）
public class FormalLibrary {
    public static let PATTERNS: Array<FaultPattern> = [
        arrayOutOfBoundsPattern(),
        typeMismatchPattern(),
        useAfterMovePattern(),
        nonExhaustiveMatchPattern()
    ]

    public static func getPattern(id: String): Option<FaultPattern> {
        for (p in FormalLibrary.PATTERNS) {
            if (p.id == id) {
                return Some(p)
            }
        }
        return None
    }
}

// ===== 4 类种子（取自《覆盖缺口清单.md》真实场景） =====

func arrayOutOfBoundsPattern(): FaultPattern {
    let c = EventCondition(exceptionType: Some("ArrayIndexOutOfBounds"), hasException: true)
    let spec = MatchSpec(sequence: Array<EventCondition>(1, { _ => c }))
    let fix = FixSuggestion(description: RT_ARRAY_OOB_FIX_DESC, replacement: RT_ARRAY_OOB_CANDIDATE)
    let repair = RepairSample(
        rootCause: RT_ARRAY_OOB_ROOT_CAUSE,
        fixSuggestion: fix,
        candidateCode: RT_ARRAY_OOB_CANDIDATE,
        relatedInfo: Array<RelatedInfo>(),
        location: None)
    return FaultPattern(
        id: "RT-ARRAY-OOB",
        category: ErrorCategory.Runtime,
        severity: Severity.Fatal,
        title: "数组下标越界",
        description: "运行时数组下标越界访问",
        matchSpec: spec,
        repair: repair)
}

func typeMismatchPattern(): FaultPattern {
    let c = EventCondition(exceptionType: Some("TypeMismatch"), hasException: true)
    let spec = MatchSpec(sequence: Array<EventCondition>(1, { _ => c }))
    let fix = FixSuggestion(description: TP_TYPE_MISMATCH_FIX_DESC, replacement: TP_TYPE_MISMATCH_CANDIDATE)
    let repair = RepairSample(
        rootCause: TP_TYPE_MISMATCH_ROOT_CAUSE,
        fixSuggestion: fix,
        candidateCode: TP_TYPE_MISMATCH_CANDIDATE,
        relatedInfo: Array<RelatedInfo>(),
        location: None)
    return FaultPattern(
        id: "TP-TYPE-MISMATCH",
        category: ErrorCategory.Type,
        severity: Severity.Error,
        title: "类型不匹配",
        description: "赋值或传参时类型不一致",
        matchSpec: spec,
        repair: repair)
}

func useAfterMovePattern(): FaultPattern {
    let c = EventCondition(exceptionType: Some("UseAfterMove"), hasException: true)
    let spec = MatchSpec(sequence: Array<EventCondition>(1, { _ => c }))
    let fix = FixSuggestion(description: RT_USE_AFTER_MOVE_FIX_DESC, replacement: RT_USE_AFTER_MOVE_CANDIDATE)
    let repair = RepairSample(
        rootCause: RT_USE_AFTER_MOVE_ROOT_CAUSE,
        fixSuggestion: fix,
        candidateCode: RT_USE_AFTER_MOVE_CANDIDATE,
        relatedInfo: Array<RelatedInfo>(),
        location: None)
    return FaultPattern(
        id: "RT-USE-AFTER-MOVE",
        category: ErrorCategory.Runtime,
        severity: Severity.Fatal,
        title: "所有权误用（move 后使用）",
        description: "所有权转移后再次使用",
        matchSpec: spec,
        repair: repair)
}

func nonExhaustiveMatchPattern(): FaultPattern {
    let c = EventCondition(exceptionType: Some("NonExhaustiveMatch"), hasException: true)
    let spec = MatchSpec(sequence: Array<EventCondition>(1, { _ => c }))
    let fix = FixSuggestion(description: SE_NONEXHAUSTIVE_FIX_DESC, replacement: SE_NONEXHAUSTIVE_CANDIDATE)
    let repair = RepairSample(
        rootCause: SE_NONEXHAUSTIVE_ROOT_CAUSE,
        fixSuggestion: fix,
        candidateCode: SE_NONEXHAUSTIVE_CANDIDATE,
        relatedInfo: Array<RelatedInfo>(),
        location: None)
    return FaultPattern(
        id: "SE-NON-EXHAUSTIVE-MATCH",
        category: ErrorCategory.Sema,
        severity: Severity.Error,
        title: "模式匹配遗漏分支",
        description: "match 表达式未覆盖全部取值",
        matchSpec: spec,
        repair: repair)
}
