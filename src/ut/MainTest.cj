package compiler_diagnostic.ut
import compiler_diagnostic.diagnostics.*
import compiler_diagnostic.cli.*
import std.collection.*
import std.unittest.testmacro.*
import std.unittest.*

import compiler_diagnostic.diagnostics.DiagnosticMessage

@Test
class MainTest {
    @TestCase func testParseArgsJson(): Unit {
        let result = parseArgs(["--diagnostic=json"])
        @Expect(result, "json")
    }

    @TestCase func testParseArgsText(): Unit {
        let result = parseArgs(["--diagnostic=text"])
        @Expect(result, "text")
    }

    @TestCase func testParseArgsDefault(): Unit {
        let result = parseArgs([])
        @Expect(result, "text")
    }

    @TestCase func testParseArgsInvalid(): Unit {
        let result = parseArgs(["--invalid"])
        @Expect(result, "text")
    }

    @TestCase func testGenerateSampleDiagnostics(): Unit {
        let diags = generateSampleDiagnostics()
        @Expect(diags.size, 9)
        @Expect(diags[0].code.code(), "E0001")
        @Expect(diags[8].code.code(), "E1004")
    }
}
