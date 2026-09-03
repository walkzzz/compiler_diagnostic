package compiler_diagnostic.diagnostics
import std.collection.*

/// 源码位置信息，对应 LSP Position 规范
public struct SourceLoc {
    /// 行号（从 0 开始）
    public var line: Int64
    /// 列号（从 0 开始）
    public var column: Int64
    /// 文件名
    public var file: String

    /// 构造函数：完整参数
    public init(line!: Int64, column!: Int64, file!: String) {
        this.line = line
        this.column = column
        this.file = file
    }

    public init(line!: Int64, column!: Int64) {
        this.line = line
        this.column = column
        this.file = ""
    }

    public init() {
        this.line = 0
        this.column = 0
        this.file = ""
    }

    public func equals(other: SourceLoc): Bool {
        return this.line == other.line && this.column == other.column && this.file == other.file
    }

    public func isBefore(other: SourceLoc): Bool {
        if (this.line != other.line) {
            return this.line < other.line
        }
        return this.column < other.column
    }
}

/// 源码范围（对应 LSP Range）
public struct Span {
    public var start: SourceLoc
    public var end: SourceLoc

    public init(start!: SourceLoc, end!: SourceLoc) {
        this.start = start
        this.end = end
    }

    public func lineCount(): Int64 {
        return this.end.line - this.start.line + 1
    }
}

/// 关联位置信息
public struct RelatedInfo {
    public var span: Span
    public var message: String

    public init(span!: Span, message!: String) {
        this.span = span
        this.message = message
    }
}

/// 修复建议，对应 LSP CodeAction
public struct FixSuggestion {
    public var description: String
    public var replacement: String
    public var span: Option<Span>

    public init(description!: String) {
        this.description = description
        this.replacement = ""
        this.span = None
    }

    public init(description!: String, replacement!: String) {
        this.description = description
        this.replacement = replacement
        this.span = None
    }

    public init(description!: String, replacement!: String, span!: Span) {
        this.description = description
        this.replacement = replacement
        this.span = Some(span)
    }
}

/// 错误码枚举
public enum ErrorCode <: Equatable<ErrorCode> {
    | ParserUnterminatedString
    | ParserTypeMismatch
    | ParserExprSyntaxError
    | ParserUndefinedIdentifier
    | ParserBracketMismatch
    | SemaTypeCheckFail
    | SemaGenericInstantiateFail
    | SemaOverloadAmbiguity
    | SemaVisibilityFail

    public func code(): String {
        return match (this) {
            case ErrorCode.ParserUnterminatedString => "E0001"
            case ErrorCode.ParserTypeMismatch => "E0002"
            case ErrorCode.ParserExprSyntaxError => "E0003"
            case ErrorCode.ParserUndefinedIdentifier => "E0004"
            case ErrorCode.ParserBracketMismatch => "E0005"
            case ErrorCode.SemaTypeCheckFail => "E1001"
            case ErrorCode.SemaGenericInstantiateFail => "E1002"
            case ErrorCode.SemaOverloadAmbiguity => "E1003"
            case ErrorCode.SemaVisibilityFail => "E1004"
        }
    }

    public func description(): String {
        return match (this) {
            case ErrorCode.ParserUnterminatedString => "未终止的字符串字面量"
            case ErrorCode.ParserTypeMismatch => "类型不匹配"
            case ErrorCode.ParserExprSyntaxError => "表达式语法错误"
            case ErrorCode.ParserUndefinedIdentifier => "未定义的标识符"
            case ErrorCode.ParserBracketMismatch => "括号不匹配"
            case ErrorCode.SemaTypeCheckFail => "类型检查失败"
            case ErrorCode.SemaGenericInstantiateFail => "泛型实例化失败"
            case ErrorCode.SemaOverloadAmbiguity => "函数重载歧义"
            case ErrorCode.SemaVisibilityFail => "可见性检查失败"
        }
    }

    public operator func ==(other: ErrorCode): Bool {
        return this.code() == other.code()
    }
}

/// 核心诊断消息结构
public struct DiagnosticMessage {
    /// 错误码
    public var code: ErrorCode
    /// 严重级别（error/warning/info）
    public var severity: String
    /// 诊断消息文本
    public var message: String
    /// 源码位置范围
    public var span: Span
    /// 修复建议（None 表示无建议）
    public var fix: Option<FixSuggestion>
    /// 关联位置信息列表
    public var related: List<RelatedInfo>
    /// 候选符号列表（None 表示无候选）
    public var candidates: Option<List<String>>
    /// 结构化根本原因（从 message 文本抽离，便于工具/IDE 机器消费）
    public var rootCause: String

    /// 构造函数：最小参数（默认 severity 为 "error"）
    public init(code!: ErrorCode, message!: String, span!: Span) {
        this.code = code
        this.severity = "error"
        this.message = message
        this.span = span
        this.fix = None
        this.related = ArrayList<RelatedInfo>()
        this.candidates = None
        this.rootCause = ""
    }

    public init(code!: ErrorCode, message!: String, span!: Span, severity!: String) {
        this.code = code
        this.severity = severity
        this.message = message
        this.span = span
        this.fix = None
        this.related = ArrayList<RelatedInfo>()
        this.candidates = None
        this.rootCause = ""
    }

    public init(code!: ErrorCode, message!: String, span!: Span, severity!: String, fix!: Option<FixSuggestion>) {
        this.code = code
        this.severity = severity
        this.message = message
        this.span = span
        this.fix = fix
        this.related = ArrayList<RelatedInfo>()
        this.candidates = None
        this.rootCause = ""
    }

    public init(code!: ErrorCode, message!: String, span!: Span, severity!: String, fix!: Option<FixSuggestion>,
        related!: List<RelatedInfo>) {
        this.code = code
        this.severity = severity
        this.message = message
        this.span = span
        this.fix = fix
        this.related = related
        this.candidates = None
        this.rootCause = ""
    }

    public init(code!: ErrorCode, message!: String, span!: Span, severity!: String, fix!: Option<FixSuggestion>,
        related!: List<RelatedInfo>, candidates!: Option<List<String>>, rootCause!: String) {
        this.code = code
        this.severity = severity
        this.message = message
        this.span = span
        this.fix = fix
        this.related = related
        this.candidates = candidates
        this.rootCause = rootCause
    }
}

/// 获取错误码字符串
public func getCodeStr(code: ErrorCode): String {
    return code.code()
}
