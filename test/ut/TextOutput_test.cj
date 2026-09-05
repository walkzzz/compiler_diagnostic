package compiler_diagnostic.ut
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*
import compiler_diagnostic.output.*
import std.collection.*


@Test
class TextOutputTest {
    @TestCase func testEmptyList(): Unit {
        let output = TextOutput()
        let result = output.output(ArrayList<DiagnosticMessage>())
        @Expect(result, "")
    }

    @TestCase func testSingleDiagnostic(): Unit {
        let output = TextOutput()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = DiagnosticBuilder(
            code: ErrorCode.ParserUnterminatedString,
            message: "未终止的字符串字面量",
            span: span
        ).build()
        let result = output.output(ArrayList<DiagnosticMessage>([diag]))
        @Expect(result.contains("[E0101]"), true)
        @Expect(result.contains("未终止的字符串字面量"), true)
    }

    @TestCase func testWithFix(): Unit {
        let output = TextOutput()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = DiagnosticBuilder(
            code: ErrorCode.ParserUnterminatedString,
            message: "test",
            span: span
        ).setFix(Some(FixSuggestion(description: "添加引号"))).build()
        let result = output.output(ArrayList<DiagnosticMessage>([diag]))
        @Expect(result.contains("修复建议"), true)
        @Expect(result.contains("添加引号"), true)
    }

    @TestCase func testWithRelated(): Unit {
        let output = TextOutput()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let rel = RelatedInfo(span: span, message: "关联位置")
        let diag = DiagnosticBuilder(
            code: ErrorCode.TypeMismatch,
            message: "类型检查失败",
            span: span
        ).addRelated(rel).build()
        let result = output.output(ArrayList<DiagnosticMessage>([diag]))
        @Expect(result.contains("关联位置"), true)
    }

    @TestCase func testWithCandidates(): Unit {
        let output = TextOutput()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let cands: List<Candidate> = ArrayList<Candidate>([Candidate(name: "foo", kind: "variable"), Candidate(name: "bar", kind: "variable"), Candidate(name: "baz", kind: "function")])
        let diag = DiagnosticBuilder(
            code: ErrorCode.SemaUndefinedSymbol,
            message: "未定义标识符",
            span: span
        ).setCandidates(cands).build()
        let result = output.output(ArrayList<DiagnosticMessage>([diag]))
        @Expect(result.contains("候选符号"), true)
        @Expect(result.contains("foo"), true)
        @Expect(result.contains("bar"), true)
    }

    @TestCase func testMultipleDiagnostics(): Unit {
        let output = TextOutput()
        let loc = SourceLoc(line: 1, column: 0)
        let span = Span(start: loc, end: loc)
        let d1 = DiagnosticBuilder(code: ErrorCode.ParserUnterminatedString, message: "d1", span: span).build()
        let d2 = DiagnosticBuilder(code: ErrorCode.TypeMismatch, message: "d2", span: span).build()
        let result = output.output(ArrayList<DiagnosticMessage>([d1, d2]))
        @Expect(result.contains("[E0101]"), true)
        @Expect(result.contains("[E2001]"), true)
        @Expect(result.contains("d1"), true)
        @Expect(result.contains("d2"), true)
    }

    @TestCase func testCandidatesNone(): Unit {
        let output = TextOutput()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = DiagnosticBuilder(
            code: ErrorCode.ParserUnterminatedString,
            message: "无候选",
            span: span
        ).build()
        let result = output.output(ArrayList<DiagnosticMessage>([diag]))
        @Expect(result.contains("候选符号"), false)
    }

    @TestCase func testNegativeLineColumn(): Unit {
        let output = TextOutput()
        let loc = SourceLoc(line: -1, column: -1)
        let span = Span(start: loc, end: loc)
        let diag = DiagnosticBuilder(
            code: ErrorCode.ParserInvalidExpression,
            message: "负数位置",
            span: span
        ).build()
        let result = output.output(ArrayList<DiagnosticMessage>([diag]))
        @Expect(result.contains("[E0105]"), true)
        @Expect(result.contains("负数位置"), true)
    }
}
