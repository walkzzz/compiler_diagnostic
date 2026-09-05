// EXEC: cjpm build
// EXEC: cjpm test --filter "ParserDiag04Test"
// EXPECT: TOTAL:.*2
package compiler_diagnostic.llt
import compiler_diagnostic.diagnostics.*
import std.unittest.*
import std.unittest.testmacro.*

import compiler_diagnostic.diagnostics.ErrorCode
import std.collection.*
import compiler_diagnostic.diagnostics.SourceLoc
import compiler_diagnostic.diagnostics.Span
import compiler_diagnostic.diagnostics.ParserDiagnostic

@Test
class ParserDiag04Test {
    @TestCase func testUndefinedIdentifier(): Unit {
        let parser = ParserDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = parser.reportUndefinedIdentifier(span: span, identifier: "foo", candidates: ArrayList<Candidate>([Candidate(name: "foo", kind: "variable"), Candidate(name: "bar", kind: "function")]))
        @Expect(diag.code.code(), "E1001")
        @Expect(diag.candidates.isSome(), true)
    }
}
