// EXEC: cjpm build
// EXEC: cjpm test ut --filter "SemaDiag03Test"
// EXPECT: TOTAL:.*2
package compiler_diagnostic.llt
import compiler_diagnostic.diagnostics.*
import std.unittest.*
import std.unittest.testmacro.*

import compiler_diagnostic.diagnostics.ErrorCode
import std.collection.*
import compiler_diagnostic.diagnostics.SourceLoc
import compiler_diagnostic.diagnostics.Span
import compiler_diagnostic.diagnostics.SemaDiagnostic

@Test
class SemaDiag03Test {
    @TestCase func testOverloadAmbiguity(): Unit {
        let sema = SemaDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = sema.reportOverloadAmbiguity(span: span, funcName: "foo", candidates: ArrayList<String>(["foo(Int)", "foo(String)"]))
        @Expect(diag.code.code(), "E1003")
        @Expect(diag.candidates.isSome(), true)
    }
}
