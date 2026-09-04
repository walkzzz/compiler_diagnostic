// EXEC: cjpm build
// EXEC: cjpm test ut --filter "SemaDiag04Test"
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
class SemaDiag04Test {
    @TestCase func testVisibilityFail(): Unit {
        let sema = SemaDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = sema.reportVisibilityFail(span: span, memberName: "privateField", accessPath: "公共访问私有成员")
        @Expect(diag.code.code(), "E3004")
        @Expect(diag.message.contains("不可访问"), true)
    }
}
