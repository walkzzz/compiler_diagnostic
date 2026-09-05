package compiler_diagnostic.semantic_trace

import std.collection.*
import compiler_diagnostic.diagnostics.SourceLoc
import compiler_diagnostic.diagnostics.Span

// ===== 版本常量（加载时校验 MAJOR） =====
public let TRACE_SCHEMA_VERSION: String = "1.0.0"
public let TRACE_SCHEMA_MAJOR: Int64 = 1

// ===== 机器执行层 =====
public struct StackFrame {
    public var function: String
    public var loc: SourceLoc
    public init(function!: String, loc!: SourceLoc) {
        this.function = function
        this.loc = loc
    }
}

// 注意：`type` 是仓颉关键字（类型别名声明），作标识符必须反引号转义：
// 字段声明、形参名、具名实参、成员访问四处均需转义。JSON key 仍为 "type"，线上格式不变。
public struct SymbolValue {
    public var name: String
    public var `type`: String
    public var valueRepr: String
    public init(name!: String, typeName!: String, valueRepr!: String) {
        this.name = name
        this.`type` = typeName
        this.valueRepr = valueRepr
    }
}

public struct ExceptionInfo {
    public var `type`: String
    public var message: String
    public init(typeName!: String, message!: String) {
        this.`type` = typeName
        this.message = message
    }
}

public struct MachineEvent {
    public var stepId: Int64
    public var kind: String
    public var loc: SourceLoc
    public var stack: Array<StackFrame>
    public var symbols: Array<SymbolValue>
    public var path: String
    public var exception: Option<ExceptionInfo>
    public init(stepId!: Int64, kind!: String, loc!: SourceLoc,
                stack!: Array<StackFrame>, symbols!: Array<SymbolValue>,
                path!: String, exception!: Option<ExceptionInfo>) {
        this.stepId = stepId
        this.kind = kind
        this.loc = loc
        this.stack = stack
        this.symbols = symbols
        this.path = path
        this.exception = exception
    }
}

// ===== 仓颉语义事件层（P2 预留结构；本迭代可空数组，OQ3 确认接受） =====
public struct SemanticEvent {
    public var stepId: Int64
    public var kind: String
    public var loc: SourceLoc
    public var detail: HashMap<String, String>
    public var relatedSpan: Option<Span>
    public init(stepId!: Int64, kind!: String, loc!: SourceLoc,
                detail!: HashMap<String, String>, relatedSpan!: Option<Span>) {
        this.stepId = stepId
        this.kind = kind
        this.loc = loc
        this.detail = detail
        this.relatedSpan = relatedSpan
    }
}

// ===== 根结构元信息 =====
public struct GeneratorInfo {
    public var tool: String
    public var version: String
    public var sdk: String
    public init(tool!: String, version!: String, sdk!: String) {
        this.tool = tool
        this.version = version
        this.sdk = sdk
    }
}

public struct ProgramInfo {
    public var entry: String
    public var args: Array<String>
    public init(entry!: String, args!: Array<String>) {
        this.entry = entry
        this.args = args
    }
}

public struct Trace {
    public var schemaVersion: String
    public var generator: GeneratorInfo
    public var program: ProgramInfo
    public var machineEvents: Array<MachineEvent>
    public var semanticEvents: Array<SemanticEvent>
    public init(schemaVersion!: String, generator!: GeneratorInfo, program!: ProgramInfo,
                machineEvents!: Array<MachineEvent>, semanticEvents!: Array<SemanticEvent>) {
        this.schemaVersion = schemaVersion
        this.generator = generator
        this.program = program
        this.machineEvents = machineEvents
        this.semanticEvents = semanticEvents
    }
}
