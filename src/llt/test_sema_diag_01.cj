// EXEC: cjpm build
// EXEC: cjpm test ut --filter "SemaDiag01Test"
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
class SemaDiag01Test {
    @TestCase func testTypeCheckFail(): Unit {
        let sema = SemaDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = sema.reportTypeCheckFail(span: span, expectedType: "Int", actualType: "String", rootCause: "类型不兼容")
        @Expect(diag.code.code(), "E1001")
        @Expect(diag.related.size, 1)
    }
}
