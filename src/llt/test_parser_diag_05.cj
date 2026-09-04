// EXEC: cjpm build
// EXEC: cjpm test ut --filter "ParserDiag05Test"
// EXPECT: TOTAL:.*2
package compiler_diagnostic.llt
import compiler_diagnostic.diagnostics.*
import std.unittest.*
import std.unittest.testmacro.*

import compiler_diagnostic.diagnostics.ErrorCode
import compiler_diagnostic.diagnostics.SourceLoc
import compiler_diagnostic.diagnostics.Span
import compiler_diagnostic.diagnostics.ParserDiagnostic

@Test
class ParserDiag05Test {
    @TestCase func testBracketMismatch(): Unit {
        let parser = ParserDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = parser.reportBracketMismatch(span: span)
        @Expect(diag.code.code(), "E0104")
        @Expect(diag.fix.isSome(), true)
    }
}
