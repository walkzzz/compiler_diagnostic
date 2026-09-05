package compiler_diagnostic.hlt
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*
// EXEC: cjpm build
// EXEC: cjpm test ut --filter "ParserMismatchedBracketTest"
// EXPECT: TOTAL:.*2
@Test
class ParserMismatchedBracketTest {
    @TestCase func testErrorCode(): Unit {
        @Expect(ErrorCode.ParserMismatchedBracket.code(), "E0104")
    }

    @TestCase func testReportMethod(): Unit {
        let parser = ParserDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = parser.reportBracketMismatch(span: span)
        @Expect(diag.code, ErrorCode.ParserMismatchedBracket)
        @Expect(diag.fix.isSome(), true)
    }
}
