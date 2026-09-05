package compiler_diagnostic.hlt
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*
// EXEC: cjpm build
// EXEC: cjpm test --filter "TypeConstraintViolationTest"
// EXPECT: TOTAL:.*2
@Test
class TypeConstraintViolationTest {
    @TestCase func testErrorCode(): Unit {
        @Expect(ErrorCode.TypeConstraintViolation.code(), "E2006")
    }

    @TestCase func testReportMethod(): Unit {
        let sema = SemaDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = sema.reportGenericInstantiateFail(span: span, genericName: "List<T>", constraintViolation: "类型约束不满足")
        @Expect(diag.code, ErrorCode.TypeConstraintViolation)
    }
}
