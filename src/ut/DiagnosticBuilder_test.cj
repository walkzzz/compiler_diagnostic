package compiler_diagnostic.ut
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*
import std.collection.*


@Test
class DiagnosticBuilderTest {
    @TestCase func testBuildBasic(): Unit {
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let builder = DiagnosticBuilder(
            code: ErrorCode.ParserUnterminatedString,
            message: "测试消息",
            span: span
        )
        let diag = builder.build()
        @Expect(diag.code, ErrorCode.ParserUnterminatedString)
        @Expect(diag.message, "测试消息")
        @Expect(diag.severity, "error")
    }

    @TestCase func testBuildWithFix(): Unit {
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let builder = DiagnosticBuilder(
            code: ErrorCode.ParserUnterminatedString,
            message: "测试消息",
            span: span
        )
        let fix = FixSuggestion(description: "添加引号")
        let diag = builder.setFix(Some(fix)).build()
        @Expect(diag.fix.isSome(), true)
    }

    @TestCase func testBuildWithRelated(): Unit {
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let builder = DiagnosticBuilder(
            code: ErrorCode.SemaTypeCheckFail,
            message: "测试消息",
            span: span
        )
        let rel = RelatedInfo(span: span, message: "关联信息")
        let diag = builder.addRelated(rel).build()
        @Expect(diag.related.size, 1)
        @Expect(diag.related[0].message, "关联信息")
    }

    @TestCase func testBuildWithCandidates(): Unit {
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let builder = DiagnosticBuilder(
            code: ErrorCode.ParserUndefinedIdentifier,
            message: "测试消息",
            span: span
        )
        let cands: List<Candidate> = ArrayList<Candidate>([Candidate(name: "foo", kind: "variable"), Candidate(name: "bar", kind: "variable")])
        let diag = builder.setCandidates(cands).build()
        @Expect(diag.candidates.isSome(), true)
    }

    @TestCase func testSeverityChain(): Unit {
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let builder = DiagnosticBuilder(
            code: ErrorCode.ParserExprSyntaxError,
            message: "测试",
            span: span
        )
        let diag = builder.setSeverity("warning").build()
        @Expect(diag.severity, "warning")
    }
}
