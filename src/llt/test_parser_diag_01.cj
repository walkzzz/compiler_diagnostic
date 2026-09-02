// EXEC: cjpm build
// EXEC: cjpm test ut --filter "ParserDiag01Test"
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
class ParserDiag01Test {
    @TestCase func testUnterminatedString(): Unit {
        let parser = ParserDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: SourceLoc(line: 10, column: 20))
        let diag = parser.reportUnterminatedString(span: span)
        @Expect(diag.code.code(), "E0001")
        @Expect(diag.message.contains("未终止"), true)
    }
}
