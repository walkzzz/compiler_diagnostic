package compiler_diagnostic.diagnostics
import std.collection.*

/// Parser 诊断生产者
public class ParserDiagnostic {
    public func reportUnterminatedString(span!: Span): DiagnosticMessage {
        return DiagnosticBuilder(
            code: ErrorCode.ExpectedToken,
            message: "未终止的字符串字面量",
            span: span
        )
            .setFix(Some(FixSuggestion(description: "添加结束引号", replacement: "\"")))
            .build()
    }

    public func reportTypeMismatch(span!: Span, expectedType!: String, actualType!: String): DiagnosticMessage {
        return DiagnosticBuilder(
            code: ErrorCode.TypeMismatch,
            message: "类型不匹配：期望 " + expectedType + "，实际 " + actualType,
            span: span
        )
            .build()
    }

    public func reportExprSyntaxError(span!: Span): DiagnosticMessage {
        return DiagnosticBuilder(
            code: ErrorCode.ExpectedType,
            message: "表达式语法错误",
            span: span
        )
            .build()
    }

    public func reportUndefinedIdentifier(span!: Span, identifier!: String, candidates!: List<Candidate>): DiagnosticMessage {
        return DiagnosticBuilder(
            code: ErrorCode.UndefinedSymbol,
            message: "未定义的标识符：" + identifier,
            span: span
        )
            .setCandidates(candidates)
            .build()
    }

    public func reportBracketMismatch(span!: Span): DiagnosticMessage {
        return DiagnosticBuilder(
            code: ErrorCode.ExpectedIdentifier,
            message: "括号不匹配",
            span: span
        )
            .setFix(Some(FixSuggestion(description: "检查括号匹配情况")))
            .build()
    }
}
