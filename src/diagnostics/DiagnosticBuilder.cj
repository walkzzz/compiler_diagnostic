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
    private var candidates: Option<List<Candidate>> = None
    private var rootCause: String = ""

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

    public func setCandidates(cands: List<Candidate>): DiagnosticBuilder {
        this.candidates = Some(cands)
        return this
    }

    /// 追加单个候选符号（name + 类型/种类），便于逐条累积候选
    public func addCandidate(name: String, kind: String): DiagnosticBuilder {
        match (this.candidates) {
            case Some(c) => c.add(Candidate(name: name, kind: kind))
            case None => this.candidates = Some(ArrayList<Candidate>([Candidate(name: name, kind: kind)]))
        }
        return this
    }

    /// 设置结构化根本原因（从 message 文本抽离）
    public func setRootCause(rc: String): DiagnosticBuilder {
        this.rootCause = rc
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
            candidates: this.candidates,
            rootCause: this.rootCause
        )
    }
}
