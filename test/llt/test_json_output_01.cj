// EXEC: cjpm build
// EXEC: cjpm test ut --filter "JSONOutputTest"
// EXPECT: TOTAL:.*3
package compiler_diagnostic.llt
import compiler_diagnostic.diagnostics.*
import compiler_diagnostic.output.*
import std.unittest.*
import std.unittest.testmacro.*

import compiler_diagnostic.diagnostics.ErrorCode
import std.collection.*
import compiler_diagnostic.diagnostics.SourceLoc
import compiler_diagnostic.diagnostics.Span
import compiler_diagnostic.output.JSONDiagnosticOutput

@Test
class JSONOutputTest {
    @TestCase func testEmptyOutput(): Unit {
        let output = JSONDiagnosticOutput()
        let json = output.output(ArrayList<DiagnosticMessage>())
        @Expect(json, "{\"diagnostics\":[]}")
    }

    @TestCase func testSingleDiag(): Unit {
        let output = JSONDiagnosticOutput()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = diagnostic_builder_for_test(
            code: ErrorCode.ParserUnterminatedString,
            message: "测试消息",
            span: span
        )
        let json = output.output(ArrayList<DiagnosticMessage>([diag]))
        @Expect(json.contains("\"code\":\"E0101\""), true)
        @Expect(json.contains("\"severity\":\"error\""), true)
    }

    @TestCase func testValidate(): Unit {
        let output = JSONDiagnosticOutput()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = diagnostic_builder_for_test(
            code: ErrorCode.TypeMismatch,
            message: "类型不匹配",
            span: span
        )
        @Expect(output.validate(ArrayList<DiagnosticMessage>([diag])), true)
    }
}

private func diagnostic_builder_for_test(code!: ErrorCode, message!: String, span!: Span): DiagnosticMessage {
    let builder = DiagnosticBuilder(code: code, message: message, span: span)
    return builder.build()
}
