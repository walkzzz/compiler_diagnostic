package compiler_diagnostic.hlt
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*
// EXEC: cjpm build
// EXEC: cjpm test ut --filter "SemaVisibilityFailTest"
// EXPECT: TOTAL:.*2
@Test
class SemaVisibilityFailTest {
    @TestCase func testErrorCode(): Unit {
        @Expect(ErrorCode.SemaVisibilityFail.code(), "E3004")
    }

    @TestCase func testReportMethod(): Unit {
        let sema = SemaDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = sema.reportVisibilityFail(span: span, memberName: "privateField", accessPath: "公共访问私有成员")
        @Expect(diag.code, ErrorCode.SemaVisibilityFail)
    }
}
