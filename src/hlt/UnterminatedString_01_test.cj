package compiler_diagnostic.hlt
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*
// EXEC: cjpm build
// EXEC: cjpm test --filter "ErrorCodeTest"
// EXPECT: TOTAL:.*4
@Test
class ParserUnterminatedStringTest {
    @TestCase func testErrorCode(): Unit {
        @Expect(ErrorCode.ParserUnterminatedString.code(), "E0101")
    }

    @TestCase func testReportMethod(): Unit {
        let parser = ParserDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: SourceLoc(line: 10, column: 20))
        let diag = parser.reportUnterminatedString(span: span)
        @Expect(diag.code, ErrorCode.ParserUnterminatedString)
        @Expect(diag.fix.isSome(), true)
    }
}
