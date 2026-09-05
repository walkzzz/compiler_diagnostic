package compiler_diagnostic.ut
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*
import std.collection.*


@Test
class DiagnosticCollectorTest {
    @TestCase func testAdd(): Unit {
        let collector = DiagnosticCollector()
        let loc = SourceLoc(line: 1, column: 0)
        let span = Span(start: loc, end: loc)
        let diag = DiagnosticBuilder(
            code: ErrorCode.ParserUnterminatedString,
            message: "test",
            span: span
        ).build()
        collector.add(diag)
        @Expect(collector.count(), 1)
    }

    @TestCase func testAddAll(): Unit {
        let collector = DiagnosticCollector()
        let loc = SourceLoc(line: 1, column: 0)
        let span = Span(start: loc, end: loc)
        let diag1 = DiagnosticBuilder(code: ErrorCode.ParserUnterminatedString, message: "m1", span: span).build()
        let diag2 = DiagnosticBuilder(code: ErrorCode.TypeMismatch, message: "m2", span: span).build()
        let list: List<DiagnosticMessage> = ArrayList<DiagnosticMessage>([diag1, diag2])
        collector.addAll(list)
        @Expect(collector.count(), 2)
    }

    @TestCase func testGetMessages(): Unit {
        let collector = DiagnosticCollector()
        let loc = SourceLoc(line: 1, column: 0)
        let span = Span(start: loc, end: loc)
        let diag = DiagnosticBuilder(code: ErrorCode.TypeMismatch, message: "mismatch", span: span).build()
        collector.add(diag)
        let msgs = collector.getMessages()
        @Expect(msgs.size, 1)
        @Expect(msgs[0].code, ErrorCode.TypeMismatch)
    }

    @TestCase func testCountEmpty(): Unit {
        let collector = DiagnosticCollector()
        @Expect(collector.count(), 0)
    }

    @TestCase func testClear(): Unit {
        let collector = DiagnosticCollector()
        let loc = SourceLoc(line: 1, column: 0)
        let span = Span(start: loc, end: loc)
        let diag = DiagnosticBuilder(code: ErrorCode.ParserInvalidExpression, message: "m", span: span).build()
        collector.add(diag)
        @Expect(collector.count(), 1)
        collector.clear()
        @Expect(collector.count(), 0)
    }

    @TestCase func testGroupByCode(): Unit {
        let collector = DiagnosticCollector()
        let loc = SourceLoc(line: 1, column: 0)
        let span = Span(start: loc, end: loc)
        let d1 = DiagnosticBuilder(code: ErrorCode.ParserUnterminatedString, message: "a", span: span).build()
        let d2 = DiagnosticBuilder(code: ErrorCode.ParserUnterminatedString, message: "b", span: span).build()
        let d3 = DiagnosticBuilder(code: ErrorCode.TypeMismatch, message: "c", span: span).build()
        collector.add(d1)
        collector.add(d2)
        collector.add(d3)
        let groups = collector.groupByCode()
        @Expect(groups.size, 2)
        // E0001 should have 2 entries
        let e0001List = groups.get(ErrorCode.ParserUnterminatedString.code()).getOrThrow()
        @Expect(e0001List.size, 2)
        // E1001 should have 1 entry
        let e1001List = groups.get(ErrorCode.TypeMismatch.code()).getOrThrow()
        @Expect(e1001List.size, 1)
    }
}
