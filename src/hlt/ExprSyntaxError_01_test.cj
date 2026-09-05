package compiler_diagnostic.hlt
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*
// EXEC: cjpm build
// EXEC: cjpm test --filter "ParserInvalidExpressionTest"
// EXPECT: TOTAL:.*2
@Test
class ParserInvalidExpressionTest {
    @TestCase func testErrorCode(): Unit {
        @Expect(ErrorCode.ExpectedType.code(), "E0105")
    }

    @TestCase func testReportMethod(): Unit {
        let parser = ParserDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = parser.reportExprSyntaxError(span: span)
        @Expect(diag.code, ErrorCode.ExpectedType)
    }
}
