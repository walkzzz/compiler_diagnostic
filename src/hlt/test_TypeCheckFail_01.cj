package compiler_diagnostic.hlt
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*
// EXEC: cjpm build
// EXEC: cjpm test ut --filter "SemaTypeFailTest"
// EXPECT: TOTAL:.*2
@Test
class SemaTypeFailTest {
    @TestCase func testErrorCode(): Unit {
        @Expect(ErrorCode.SemaTypeCheckFail.code(), "E1001")
    }

    @TestCase func testReportMethod(): Unit {
        let sema = SemaDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = sema.reportTypeCheckFail(span: span, expectedType: "Int", actualType: "String", rootCause: "类型不兼容")
        @Expect(diag.code, ErrorCode.SemaTypeCheckFail)
        @Expect(diag.related.size, 1)
    }
}
