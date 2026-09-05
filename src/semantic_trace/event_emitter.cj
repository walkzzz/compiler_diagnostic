package compiler_diagnostic.semantic_trace

import std.collection.*
import std.fs.*
import compiler_diagnostic.diagnostics.SourceLoc

/// 事件发射器：本迭代如何「产生 Trace」（务实静态合成，OQ1 明确决策）。
///
/// - 真实运行时插桩（AST/IR 埋点）属 P2，本迭代不依赖任何尚不存在的 VM 能力；
/// - `scanSourceToTrace` 做轻量关键字/结构启发式扫描；
/// - `constructSampleTrace` 受控样例构造（测试 / samples 用）；
/// - `buildFromEvents` 程序化构造入口（测试与 P2 真实捕获共用）。
public class EventEmitter {

    /// 程序化构造（测试 / 未来运行时捕获共用入口）
    public static func buildFromEvents(
        events: Array<MachineEvent>,
        entry!: String,
        args!: Array<String> = Array<String>()
    ): Trace {
        let gen = GeneratorInfo(
            tool: "compiler_diagnostic/event_emitter",
            version: TRACE_SCHEMA_VERSION,
            sdk: "cangjie-1.1.3")
        let prog = ProgramInfo(entry: entry, args: args)
        return Trace(
            schemaVersion: TRACE_SCHEMA_VERSION,
            generator: gen,
            program: prog,
            machineEvents: events,
            semanticEvents: Array<SemanticEvent>())
    }

    /// 受控样例构造（samples/ 与 UT 用）。
    /// kind ∈ {"array-oob","type-mismatch","use-after-move","non-exhaustive-match"}
    public static func constructSampleTrace(kind: String): Trace {
        match (kind) {
            case "array-oob" => buildArrayOob()
            case "type-mismatch" => buildTypeMismatch()
            case "use-after-move" => buildUseAfterMove()
            case "non-exhaustive-match" => buildNonExhaustiveMatch()
            case _ => buildFromEvents(Array<MachineEvent>(), entry: "<unknown>")
        }
    }

    /// 注意：P0 在线路径务实实现：轻量静态扫描源码 -> machine-layer Trace。
    /// 文件读取失败返回空 machineEvents 的 Trace（diagnose 端走未命中回退）。
    /// std.fs 真实契约：File.readFrom(String) -> Array<UInt8>，失败抛异常（不存在 std.fs.Result）。
    public static func scanSourceToTrace(sourceFile: String): Trace {
        try {
            let bytes = File.readFrom(sourceFile)
            return scanBytes(bytes, sourceFile)
        } catch (e: Exception) {
            return buildFromEvents(Array<MachineEvent>(), entry: sourceFile)
        }
    }

    // ===== 内部：样例构造 =====

    private static func buildArrayOob(): Trace {
        let loc = SourceLoc(line: 4, column: 10, file: "samples/array_oob.cj")
        let ev = MachineEvent(
            stepId: 1,
            kind: "array-access",
            loc: loc,
            stack: Array<StackFrame>(),
            symbols: Array<SymbolValue>(),
            path: "then",
            exception: Some(ExceptionInfo(typeName: "ArrayIndexOutOfBounds", message: "数组下标越界访问")))
        return buildFromEvents(Array<MachineEvent>(1, { _ => ev }), entry: "samples/array_oob.cj")
    }

    private static func buildTypeMismatch(): Trace {
        let loc = SourceLoc(line: 6, column: 4, file: "samples/type_mismatch.cj")
        let ev = MachineEvent(
            stepId: 1,
            kind: "var-bind",
            loc: loc,
            stack: Array<StackFrame>(),
            symbols: Array<SymbolValue>(),
            path: "then",
            exception: Some(ExceptionInfo(typeName: "TypeMismatch", message: "类型不匹配：期望 Int64 实际 String")))
        return buildFromEvents(Array<MachineEvent>(1, { _ => ev }), entry: "samples/type_mismatch.cj")
    }

    private static func buildUseAfterMove(): Trace {
        let loc = SourceLoc(line: 8, column: 2, file: "samples/use_after_move.cj")
        let ev = MachineEvent(
            stepId: 1,
            kind: "var-bind",
            loc: loc,
            stack: Array<StackFrame>(),
            symbols: Array<SymbolValue>(),
            path: "then",
            exception: Some(ExceptionInfo(typeName: "UseAfterMove", message: "所有权转移后再次使用")))
        return buildFromEvents(Array<MachineEvent>(1, { _ => ev }), entry: "samples/use_after_move.cj")
    }

    private static func buildNonExhaustiveMatch(): Trace {
        let loc = SourceLoc(line: 5, column: 2, file: "samples/non_exhaustive_match.cj")
        let ev = MachineEvent(
            stepId: 1,
            kind: "branch",
            loc: loc,
            stack: Array<StackFrame>(),
            symbols: Array<SymbolValue>(),
            path: "then",
            exception: Some(ExceptionInfo(typeName: "NonExhaustiveMatch", message: "match 表达式未覆盖全部取值")))
        return buildFromEvents(Array<MachineEvent>(1, { _ => ev }), entry: "samples/non_exhaustive_match.cj")
    }

    // ===== 内部：静态扫描 =====

    private static func scanBytes(bytes: Array<Byte>, sourceFile: String): Trace {
        let text = String.fromUtf8(bytes)
        let lines = text.split("\n")
        let events = ArrayList<MachineEvent>()
        var step = 1
        var idx = 0
        for (line in lines) {
            let ln = idx
            idx = idx + 1
            if (line.contains("arr[") || line.contains("[idx]") || line.contains("[i]") ||
                (line.contains("[") && (line.contains("arr") || line.contains("index")))) {
                let loc = SourceLoc(line: ln, column: 0, file: sourceFile)
                events.add(MachineEvent(
                    stepId: step,
                    kind: "array-access",
                    loc: loc,
                    stack: Array<StackFrame>(),
                    symbols: Array<SymbolValue>(),
                    path: "then",
                    exception: Some(ExceptionInfo(typeName: "ArrayIndexOutOfBounds", message: "数组下标越界访问"))))
                step = step + 1
            } else if (line.contains("match") && !(line.contains("_ =>") || line.contains("_:"))) {
                let loc = SourceLoc(line: ln, column: 0, file: sourceFile)
                events.add(MachineEvent(
                    stepId: step,
                    kind: "branch",
                    loc: loc,
                    stack: Array<StackFrame>(),
                    symbols: Array<SymbolValue>(),
                    path: "then",
                    exception: Some(ExceptionInfo(typeName: "NonExhaustiveMatch", message: "match 表达式未覆盖全部取值"))))
                step = step + 1
            } else if (line.contains("move(")) {
                let loc = SourceLoc(line: ln, column: 0, file: sourceFile)
                events.add(MachineEvent(
                    stepId: step,
                    kind: "var-bind",
                    loc: loc,
                    stack: Array<StackFrame>(),
                    symbols: Array<SymbolValue>(),
                    path: "then",
                    exception: Some(ExceptionInfo(typeName: "UseAfterMove", message: "所有权转移后再次使用"))))
                step = step + 1
            } else if (line.contains(": Int") && line.contains("= \"")) {
                let loc = SourceLoc(line: ln, column: 0, file: sourceFile)
                events.add(MachineEvent(
                    stepId: step,
                    kind: "var-bind",
                    loc: loc,
                    stack: Array<StackFrame>(),
                    symbols: Array<SymbolValue>(),
                    path: "then",
                    exception: Some(ExceptionInfo(typeName: "TypeMismatch", message: "类型不匹配：期望 Int 实际 String"))))
                step = step + 1
            }
        }
        return buildFromEvents(events.toArray(), entry: sourceFile)
    }
}
