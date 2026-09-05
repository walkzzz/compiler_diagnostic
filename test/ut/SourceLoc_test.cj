package compiler_diagnostic.ut
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*


@Test
class SourceLocTest {
    @TestCase func testEquals(): Unit {
        let loc1 = SourceLoc(line: 10, column: 5, file: "test.cj")
        let loc2 = SourceLoc(line: 10, column: 5, file: "test.cj")
        @Expect(loc1.equals(loc2), true)
    }

    @TestCase func testNotEquals(): Unit {
        let loc1 = SourceLoc(line: 10, column: 5, file: "test.cj")
        let loc2 = SourceLoc(line: 11, column: 5, file: "test.cj")
        @Expect(loc1.equals(loc2), false)
    }

    @TestCase func testIsBefore(): Unit {
        let loc1 = SourceLoc(line: 5, column: 3, file: "a.cj")
        let loc2 = SourceLoc(line: 10, column: 5, file: "a.cj")
        @Expect(loc1.isBefore(loc2), true)
        @Expect(loc2.isBefore(loc1), false)
    }

    @TestCase func testIsBeforeSameLine(): Unit {
        let loc1 = SourceLoc(line: 5, column: 3, file: "a.cj")
        let loc2 = SourceLoc(line: 5, column: 10, file: "a.cj")
        @Expect(loc1.isBefore(loc2), true)
    }

    @TestCase func testSpanLineCount(): Unit {
        let start = SourceLoc(line: 10, column: 0, file: "test.cj")
        let end = SourceLoc(line: 15, column: 20, file: "test.cj")
        let span = Span(start: start, end: end)
        @Expect(span.lineCount(), 6)
    }

    @TestCase func testSpanSingleLine(): Unit {
        let start = SourceLoc(line: 5, column: 0, file: "test.cj")
        let end = SourceLoc(line: 5, column: 10, file: "test.cj")
        let span = Span(start: start, end: end)
        @Expect(span.lineCount(), 1)
    }
}
