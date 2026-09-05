// EXEC: cjpm build
// EXEC: cjpm test --filter "SemaDiag03Test"
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
        let diag = sema.reportOverloadAmbiguity(span: span, funcName: "foo", candidates: ArrayList<Candidate>([Candidate(name: "foo(Int)", kind: "function"), Candidate(name: "foo(String)", kind: "function")]))
        @Expect(diag.code.code(), "E2004")
        @Expect(diag.candidates.isSome(), true)
    }
}
