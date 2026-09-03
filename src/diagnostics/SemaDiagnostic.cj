package compiler_diagnostic.diagnostics
import std.collection.*

/// Sema 诊断生产者
public class SemaDiagnostic {
    public func reportTypeCheckFail(span!: Span, expectedType!: String, actualType!: String, rootCause!: String): DiagnosticMessage {
        return DiagnosticBuilder(
            code: ErrorCode.SemaTypeCheckFail,
            message: "类型检查失败：" + rootCause,
            span: span
        ).setRootCause(rootCause)
        .addRelated(RelatedInfo(span: span, message: "期望类型: " + expectedType + ", 实际类型: " + actualType)).build()
    }

    public func reportGenericInstantiateFail(span!: Span, genericName!: String, constraintViolation!: String): DiagnosticMessage {
        return DiagnosticBuilder(
            code: ErrorCode.SemaGenericInstantiateFail,
            message: "泛型实例化失败：" + genericName + "，" + constraintViolation,
            span: span
        ).build()
    }

    public func reportOverloadAmbiguity(span!: Span, funcName!: String, candidates!: List<String>): DiagnosticMessage {
        return DiagnosticBuilder(
            code: ErrorCode.SemaOverloadAmbiguity,
            message: "函数重载歧义：" + funcName + " 有多个匹配的重载",
            span: span
        ).setCandidates(candidates).build()
    }

    public func reportVisibilityFail(span!: Span, memberName!: String, accessPath!: String): DiagnosticMessage {
        return DiagnosticBuilder(
            code: ErrorCode.SemaVisibilityFail,
            message: "不可访问的成员：" + memberName + "，" + accessPath,
            span: span
        ).build()
    }
}
