package compiler_diagnostic.hlt
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*
// EXEC: cjpm build
// EXEC: cjpm test ut --filter "ParserBracketMismatchTest"
// EXPECT: TOTAL:.*2
@Test
class ParserBracketMismatchTest {
    @TestCase func testErrorCode(): Unit {
        @Expect(ErrorCode.ParserBracketMismatch.code(), "E0005")
    }

    @TestCase func testReportMethod(): Unit {
        let parser = ParserDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = parser.reportBracketMismatch(span: span)
        @Expect(diag.code, ErrorCode.ParserBracketMismatch)
        @Expect(diag.fix.isSome(), true)
    }
}
