package compiler_diagnostic.diagnostics
import std.collection.*

/// 诊断消息构建器，采用 Builder 模式
public class DiagnosticBuilder {
    private var code: ErrorCode
    private var message: String
    private var span: Span
    private var severity: String = "error"
    private var fix: Option<FixSuggestion> = None
    private var related: List<RelatedInfo> = ArrayList<RelatedInfo>()
    private var candidates: Option<List<String>> = None

    public init(code!: ErrorCode, message!: String, span!: Span) {
        this.code = code
        this.message = message
        this.span = span
    }

    public func setSeverity(sev: String): DiagnosticBuilder {
        this.severity = sev
        return this
    }

    /// 设置修复建议
    /// 调用方负责包装为 Option<FixSuggestion>
    public func setFix(fix: Option<FixSuggestion>): DiagnosticBuilder {
        this.fix = fix
        return this
    }

    public func addRelated(info: RelatedInfo): DiagnosticBuilder {
        this.related.add(info)
        return this
    }

    public func setCandidates(cands: List<String>): DiagnosticBuilder {
        this.candidates = Some(cands)
        return this
    }

    public func build(): DiagnosticMessage {
        return DiagnosticMessage(
            code: this.code,
            message: this.message,
            span: this.span,
            severity: this.severity,
            fix: this.fix,
            related: this.related,
            candidates: this.candidates
        )
    }
}
