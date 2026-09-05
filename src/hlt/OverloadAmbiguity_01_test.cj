package compiler_diagnostic.hlt
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*
import std.collection.*
import std.collection.*
// EXEC: cjpm build
// EXEC: cjpm test --filter "TypeAmbiguousOverloadTest"
// EXPECT: TOTAL:.*2
@Test
class TypeAmbiguousOverloadTest {
    @TestCase func testErrorCode(): Unit {
        @Expect(ErrorCode.AmbiguousType.code(), "E2004")
    }

    @TestCase func testReportMethod(): Unit {
        let sema = SemaDiagnostic()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = sema.reportOverloadAmbiguity(span: span, funcName: "foo", candidates: ArrayList<Candidate>([Candidate(name: "foo(Int)", kind: "function"), Candidate(name: "foo(String)", kind: "function")]))
        @Expect(diag.code, ErrorCode.AmbiguousType)
        @Expect(diag.candidates.isSome(), true)
    }
}
