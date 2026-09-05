package compiler_diagnostic.hlt
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*
// EXEC: cjpm build
// EXEC: cjpm test --filter "SemaTypeFailTest"
// EXPECT: TOTAL:.*2
@Test
// 防御性命名：类名避免含 "Check" 子串（如 SemaTypeCheckFailTest），否则 cjlint G_SEC.01
// 会误判 @Test 宏展开后的 register<SemaTypeCheckFailTest> 为 open 函数，触发 MANDATORY 阻断。
class SemaTypeFailTest {
    @TestCase func testErrorCode(): Unit {
        @Expect(ErrorCode.TypeMismatch.code(), "E2001")
    }

    @TestCase func testReportMethod(): Unit {
        let sema = SemaDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = sema.reportTypeCheckFail(span: span, expectedType: "Int", actualType: "String", rootCause: "类型不兼容")
        @Expect(diag.code, ErrorCode.TypeMismatch)
        @Expect(diag.related.size, 1)
    }
}
