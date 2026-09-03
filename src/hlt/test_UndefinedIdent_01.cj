package compiler_diagnostic.hlt
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*
import std.collection.*
import std.collection.*
// EXEC: cjpm build
// EXEC: cjpm test ut --filter "ParserUndefinedIdentTest"
// EXPECT: TOTAL:.*2
@Test
class ParserUndefinedIdentTest {
    @TestCase func testErrorCode(): Unit {
        @Expect(ErrorCode.ParserUndefinedIdentifier.code(), "E0004")
    }

    @TestCase func testReportMethod(): Unit {
        let parser = ParserDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = parser.reportUndefinedIdentifier(span: span, identifier: "foo", candidates: ArrayList<Candidate>([Candidate(name: "Foo", kind: "type"), Candidate(name: "bar", kind: "function")]))
        @Expect(diag.code, ErrorCode.ParserUndefinedIdentifier)
        @Expect(diag.candidates.isSome(), true)
    }
}
