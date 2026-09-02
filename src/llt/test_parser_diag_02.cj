// EXEC: cjpm build
// EXEC: cjpm test ut --filter "ParserDiag02Test"
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
class ParserDiag02Test {
    @TestCase func testTypeMismatch(): Unit {
        let parser = ParserDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = parser.reportTypeMismatch(span: span, expectedType: "Int", actualType: "String")
        @Expect(diag.code.code(), "E0002")
        @Expect(diag.message.contains("Int"), true)
        @Expect(diag.message.contains("String"), true)
    }
}
