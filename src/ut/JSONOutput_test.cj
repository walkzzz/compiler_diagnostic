package compiler_diagnostic.ut
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*
import compiler_diagnostic.output.*
import std.collection.*


@Test
class JSONOutputTest {
    @TestCase func testOutputEmpty(): Unit {
        let output = JSONDiagnosticOutput()
        let result = output.output(ArrayList<DiagnosticMessage>())
        @Expect(result, "{\"diagnostics\":[]}")
    }

    @TestCase func testOutputSingle(): Unit {
        let output = JSONDiagnosticOutput()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = diagnostic_from_builder(
            code: ErrorCode.ExpectedToken,
            message: "测试消息",
            span: span
        )
        let result = output.output(ArrayList<DiagnosticMessage>([diag]))
        @Expect(result.contains("\"code\":\"E0101\""), true)
        @Expect(result.contains("\"severity\":\"error\""), true)
        @Expect(result.contains("\"message\":\"测试消息\""), true)
    }

    @TestCase func testValidate(): Unit {
        let output = JSONDiagnosticOutput()
        let loc = SourceLoc(line: 10, column: 5)
        let span = Span(start: loc, end: loc)
        let diag = diagnostic_from_builder(
            code: ErrorCode.TypeMismatch,
            message: "类型不匹配",
            span: span
        )
        @Expect(output.validate(ArrayList<DiagnosticMessage>([diag])), true)
    }

    @TestCase func testEscapeControlCharacters(): Unit {
        let output = JSONDiagnosticOutput()
        let loc = SourceLoc(line: 1, column: 1)
        let span = Span(start: loc, end: loc)
        let diag = diagnostic_from_builder(
            code: ErrorCode.ExpectedType,
            message: "包含控制字符\u{01}\u{02}",
            span: span
        )
        let result = output.output(ArrayList<DiagnosticMessage>([diag]))
        @Expect(result.contains("\"message\":\""), true)
    }

    @TestCase func testEscapeBackslashAndQuote(): Unit {
        let output = JSONDiagnosticOutput()
        let loc = SourceLoc(line: 1, column: 1)
        let span = Span(start: loc, end: loc)
        let diag = diagnostic_from_builder(
            code: ErrorCode.ExpectedType,
            message: "包含反斜杠\\和引号\"",
            span: span
        )
        let result = output.output(ArrayList<DiagnosticMessage>([diag]))
        @Expect(result.contains("\\\\"), true)
        @Expect(result.contains("\\\""), true)
    }
}

private func diagnostic_from_builder(code!: ErrorCode, message!: String, span!: Span): DiagnosticMessage {
    let builder = DiagnosticBuilder(code: code, message: message, span: span)
    return builder.build()
}
