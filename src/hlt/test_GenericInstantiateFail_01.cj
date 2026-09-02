package compiler_diagnostic.hlt
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*
// EXEC: cjpm build
// EXEC: cjpm test ut --filter "SemaGenericInstantiateFailTest"
// EXPECT: TOTAL:.*2
@Test
class SemaGenericInstantiateFailTest {
    @TestCase func testErrorCode(): Unit {
        @Expect(ErrorCode.SemaGenericInstantiateFail.code(), "E1002")
    }

    @TestCase func testReportMethod(): Unit {
        let sema = SemaDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = sema.reportGenericInstantiateFail(span: span, genericName: "List<T>", constraintViolation: "类型约束不满足")
        @Expect(diag.code, ErrorCode.SemaGenericInstantiateFail)
    }
}
