// EXEC: cjpm build
// EXEC: cjpm test --filter "CjcBridgeIngestTest"
// EXPECT: TOTAL:.*
package compiler_diagnostic.llt
import compiler_diagnostic.diagnostics.*
import std.unittest.*
import std.unittest.testmacro.*
import std.collection.*

@Test
class CjcBridgeIngestTest {
    @TestCase func testTypeMismatch(): Unit {
        let raw = "error: mismatched types\n ==> a.cj:2:20:\n"
        match (resolveCjc(raw)) {
            case Some(c) => @Expect(c == ErrorCode.TypeMismatch, true)
            case None => @Expect(false, true)
        }
    }

    @TestCase func testUndeclaredIdentifier(): Unit {
        let raw = "error: undeclared identifier 'foo'\n ==> a.cj:3:13:\n"
        match (resolveCjc(raw)) {
            case Some(c) => @Expect(c == ErrorCode.SemaUndefinedSymbol, true)
            case None => @Expect(false, true)
        }
    }

    @TestCase func testSnippetNoFalsePositive(): Unit {
        // 'private' 仅出现在片段行，不应误命中 ResolutionPrivateAccess
        let raw = "error: mismatched types\n ==> a.cj:2:20:\n  | privateField\n  | ^\n"
        match (resolveCjc(raw)) {
            case Some(c) => @Expect(c == ErrorCode.TypeMismatch, true)
            case None => @Expect(false, true)
        }
    }

    @TestCase func testMultipleDiagnostics(): Unit {
        let raw = "error: mismatched types\n ==> a.cj:2:20:\n\nerror: undeclared identifier 'x'\n ==> a.cj:3:13:\n"
        let codes = parseCjcDiagnostics(raw)
        @Expect(codes.size, 2)
        @Expect(codes.contains(ErrorCode.TypeMismatch), true)
        @Expect(codes.contains(ErrorCode.SemaUndefinedSymbol), true)
    }

    @TestCase func testUnknownReturnsNone(): Unit {
        let raw = "error: some totally unknown compiler complaint\n ==> a.cj:1:1:\n"
        match (resolveCjc(raw)) {
            case Some(_) => @Expect(false, true)
            case None => @Expect(true, true)
        }
    }

    @TestCase func testNoErrorLineReturnsNone(): Unit {
        match (resolveCjc("clean build, no diagnostics")) {
            case Some(_) => @Expect(false, true)
            case None => @Expect(true, true)
        }
    }
}
