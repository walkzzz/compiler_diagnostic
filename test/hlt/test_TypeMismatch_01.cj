package compiler_diagnostic.hlt
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*
// EXEC: cjpm build
// EXEC: cjpm test ut --filter "TypeMismatchTest"
// EXPECT: TOTAL:.*2
@Test
class TypeMismatchTest {
    @TestCase func testErrorCode(): Unit {
        @Expect(ErrorCode.TypeMismatch.code(), "E2001")
    }

    @TestCase func testReportMethod(): Unit {
        let parser = ParserDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = parser.reportTypeMismatch(span: span, expectedType: "Int", actualType: "String")
        @Expect(diag.code, ErrorCode.TypeMismatch)
        @Expect(diag.message.contains("类型不匹配"), true)
    }
}
