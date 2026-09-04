// EXEC: cjpm build
// EXEC: cjpm test ut --filter "SemaDiag02Test"
// EXPECT: TOTAL:.*2
package compiler_diagnostic.llt
import compiler_diagnostic.diagnostics.*
import std.unittest.*
import std.unittest.testmacro.*

import compiler_diagnostic.diagnostics.ErrorCode
import compiler_diagnostic.diagnostics.SourceLoc
import compiler_diagnostic.diagnostics.Span
import compiler_diagnostic.diagnostics.SemaDiagnostic

@Test
class SemaDiag02Test {
    @TestCase func testGenericInstantiateFail(): Unit {
        let sema = SemaDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = sema.reportGenericInstantiateFail(span: span, genericName: "List<T>", constraintViolation: "类型约束不满足")
        @Expect(diag.code.code(), "E2006")
        @Expect(diag.message.contains("泛型实例化失败"), true)
    }
}
