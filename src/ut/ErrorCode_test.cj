package compiler_diagnostic.ut
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*


@Test
class ErrorCodeTest {
    @TestCase func testEnumValues(): Unit {
        let codes: Array<ErrorCode> = [
            ErrorCode.ParserUnterminatedString,
            ErrorCode.ParserTypeMismatch,
            ErrorCode.ParserExprSyntaxError,
            ErrorCode.ParserUndefinedIdentifier,
            ErrorCode.ParserBracketMismatch,
            ErrorCode.SemaTypeCheckFail,
            ErrorCode.SemaGenericInstantiateFail,
            ErrorCode.SemaOverloadAmbiguity,
            ErrorCode.SemaVisibilityFail
        ]
        @Expect(codes.size, 9)
    }

    @TestCase func testCodeValues(): Unit {
        @Expect(ErrorCode.ParserUnterminatedString.code(), "E0001")
        @Expect(ErrorCode.ParserTypeMismatch.code(), "E0002")
        @Expect(ErrorCode.ParserExprSyntaxError.code(), "E0003")
        @Expect(ErrorCode.ParserUndefinedIdentifier.code(), "E0004")
        @Expect(ErrorCode.ParserBracketMismatch.code(), "E0005")
        @Expect(ErrorCode.SemaTypeCheckFail.code(), "E1001")
        @Expect(ErrorCode.SemaGenericInstantiateFail.code(), "E1002")
        @Expect(ErrorCode.SemaOverloadAmbiguity.code(), "E1003")
        @Expect(ErrorCode.SemaVisibilityFail.code(), "E1004")
    }

    @TestCase func testDescription(): Unit {
        @Expect(ErrorCode.ParserUnterminatedString.description(), "未终止的字符串字面量")
        @Expect(ErrorCode.SemaVisibilityFail.description(), "可见性检查失败")
        @Expect(ErrorCode.SemaOverloadAmbiguity.description(), "函数重载歧义")
    }
}
