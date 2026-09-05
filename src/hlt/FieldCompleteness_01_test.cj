package compiler_diagnostic.hlt
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*
import compiler_diagnostic.output.*
import std.collection.*
import std.collection.*
// EXEC: cjpm build
// EXEC: cjpm test --filter "JSONFieldCompletenessTest"
// EXPECT: TOTAL:.*2
@Test
class JSONFieldCompletenessTest {
    @TestCase func testOutputRequiredFields(): Unit {
        let output = JSONDiagnosticOutput()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = diagnostic_builder_for_test(
            code: ErrorCode.ParserUnterminatedString,
            message: "测试消息",
            span: span
        )
        let json = output.output(ArrayList<DiagnosticMessage>([diag]))
        @Expect(json.contains("\"code\""), true)
        @Expect(json.contains("\"message\""), true)
        @Expect(json.contains("\"span\""), true)
        @Expect(json.contains("\"severity\""), true)
    }

    @TestCase func testOutputOptionalFields(): Unit {
        let output = JSONDiagnosticOutput()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = diagnostic_builder_with_fix_for_test(span: span)
        let json = output.output(ArrayList<DiagnosticMessage>([diag]))
        @Expect(json.contains("\"fix\""), true)
        @Expect(json.contains("\"description\""), true)
    }
}

private func diagnostic_builder_for_test(code!: ErrorCode, message!: String, span!: Span): DiagnosticMessage {
    let builder = DiagnosticBuilder(code: code, message: message, span: span)
    return builder.build()
}

private func diagnostic_builder_with_fix_for_test(span!: Span): DiagnosticMessage {
    let builder = DiagnosticBuilder(
        code: ErrorCode.ParserUnterminatedString,
        message: "测试",
        span: span
    )
    return builder.setFix(Some(FixSuggestion(description: "修复", replacement: "\""))).build()
}
