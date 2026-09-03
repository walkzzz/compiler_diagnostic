package compiler_diagnostic.cli
import std.collection.*
import compiler_diagnostic.diagnostics.*

/// 命令行参数解析
/// 支持模式：--diagnostic=text（默认） | --diagnostic=json | --diagnostic=lsp
public func parseArgs(args: Array<String>): String {
    for (arg in args) {
        if (arg == "--diagnostic=json") {
            return "json"
        }
        if (arg == "--diagnostic=lsp") {
            return "lsp"
        }
        if (arg == "--diagnostic=text") {
            return "text"
        }
    }
    return "text"
}

/// 生成示例诊断消息
public func generateSampleDiagnostics(): List<DiagnosticMessage> {
    let loc1 = SourceLoc(line: 10, column: 5, file: "test.cj")
    let loc2 = SourceLoc(line: 10, column: 20, file: "test.cj")
    let span1 = Span(start: loc1, end: loc2)

    let parserDiag = ParserDiagnostic()
    let semaDiag = SemaDiagnostic()

    let diag1 = parserDiag.reportUnterminatedString(span: span1)
    let diag2 = parserDiag.reportTypeMismatch(span: span1, expectedType: "Int", actualType: "String")
    let diag3 = parserDiag.reportUndefinedIdentifier(span: span1, identifier: "undefVar", candidates: ArrayList<Candidate>([Candidate(name: "var1", kind: "variable"), Candidate(name: "var2", kind: "variable")]))
    let diag4 = parserDiag.reportBracketMismatch(span: span1)
    let diag5 = parserDiag.reportExprSyntaxError(span: span1)
    let diag6 = semaDiag.reportTypeCheckFail(span: span1, expectedType: "Int", actualType: "String",
        rootCause: "类型转换失败")
    let diag7 = semaDiag.reportGenericInstantiateFail(span: span1, genericName: "List<T>",
        constraintViolation: "类型 T 不满足约束")
    let diag8 = semaDiag.reportOverloadAmbiguity(span: span1, funcName: "foo", candidates: ArrayList<Candidate>([Candidate(name: "foo(Int)", kind: "function"), Candidate(name: "foo(String)", kind: "function")]))
    let diag9 = semaDiag.reportVisibilityFail(span: span1, memberName: "privateField", accessPath: "公共访问私有成员")

    let result: List<DiagnosticMessage> = ArrayList<DiagnosticMessage>()
    result.add(diag1)
    result.add(diag2)
    result.add(diag3)
    result.add(diag4)
    result.add(diag5)
    result.add(diag6)
    result.add(diag7)
    result.add(diag8)
    result.add(diag9)

    return result
}
