package compiler_diagnostic.ut
import std.collection.*
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.diagnostics.*

/// 错误码体系测试（扩展后：8 大类共 120 个规范码（每类 15 个）+ 8 个向后兼容别名）
@Test
class ErrorCodeTest {
    /// 每类代表码的 code() 字符串（覆盖 Lexer/Parser/Sema/Type/Resolution/Codegen/Runtime/System 首尾）
    @TestCase func testCanonicalCodesByCategory(): Unit {
        // Lexer
        @Expect(ErrorCode.LexerUnterminatedString.code(), "E0001")
        @Expect(ErrorCode.LexerNestedCommentTooDeep.code(), "E0015")
        // Parser
        @Expect(ErrorCode.ParserUnterminatedString.code(), "E0101")
        @Expect(ErrorCode.ParserIllegalTopLevelStatement.code(), "E0115")
        // Sema
        @Expect(ErrorCode.SemaUndefinedSymbol.code(), "E1001")
        @Expect(ErrorCode.SemaUnreachableMatchArm.code(), "E1015")
        // Type
        @Expect(ErrorCode.TypeMismatch.code(), "E2001")
        @Expect(ErrorCode.TypeCyclicInference.code(), "E2015")
        // Resolution
        @Expect(ErrorCode.ResolutionModuleNotFound.code(), "E3001")
        @Expect(ErrorCode.ResolutionUncoveredCfgBranch.code(), "E3015")
        // Codegen
        @Expect(ErrorCode.CodegenUnsupportedConstruct.code(), "E4001")
        @Expect(ErrorCode.CodegenTargetFeatureUnsupported.code(), "E4015")
        // Runtime
        @Expect(ErrorCode.RuntimeNullDereference.code(), "E5001")
        @Expect(ErrorCode.RuntimeFFICallFailed.code(), "E5015")
        // System
        @Expect(ErrorCode.SystemInternalError.code(), "E9001")
        @Expect(ErrorCode.SystemInternalAssertion.code(), "E9015")
    }

    /// 向后兼容别名映射到新码（旧 9 个变体名仍可编译，code() 指向规范码）
    @TestCase func testBackwardCompatAliases(): Unit {
        @Expect(ErrorCode.ParserTypeMismatch.code(), "E2001")
        @Expect(ErrorCode.ParserExprSyntaxError.code(), "E0105")
        @Expect(ErrorCode.ParserUndefinedIdentifier.code(), "E1001")
        @Expect(ErrorCode.ParserBracketMismatch.code(), "E0104")
        @Expect(ErrorCode.SemaTypeCheckFail.code(), "E2001")
        @Expect(ErrorCode.SemaGenericInstantiateFail.code(), "E2006")
        @Expect(ErrorCode.SemaOverloadAmbiguity.code(), "E2004")
        @Expect(ErrorCode.SemaVisibilityFail.code(), "E3004")
    }

    /// 类别与严重级别映射（三级：Fatal > Error > Warning）
    @TestCase func testCategoryAndSeverity(): Unit {
        @Expect(ErrorCode.TypeMismatch.category(), ErrorCategory.Type)
        @Expect(ErrorCode.LexerInvalidUtf8Sequence.category(), ErrorCategory.Lexer)
        @Expect(ErrorCode.RuntimeNullDereference.severity(), Severity.Fatal)
        @Expect(ErrorCode.SystemInternalError.severity(), Severity.Fatal)
        @Expect(ErrorCode.LexerNumericOverflow.severity(), Severity.Warning)
        @Expect(ErrorCode.SemaUnreachableCode.severity(), Severity.Warning)
        @Expect(ErrorCode.TypeMismatch.severity(), Severity.Error)
    }

    /// 参数化模板与 fromCode 工厂（带参 / 无参）
    @TestCase func testTemplateAndFromCode(): Unit {
        @Expect(ErrorCode.TypeMismatch.template(), "类型不匹配：期望 {expected}，实际 {actual}")
        let span = Span(start: SourceLoc(line: 1, column: 1), end: SourceLoc(line: 1, column: 5))
        let params = HashMap<String, String>()
        params["expected"] = "Int"
        params["actual"] = "String"
        let d = fromCode(ErrorCode.TypeMismatch, span, params)
        @Expect(d.message, "类型不匹配：期望 Int，实际 String")
        @Expect(d.severity, "error")
        @Expect(d.code.code(), "E2001")
        let noneD = fromCode(ErrorCode.RuntimeNullDereference, span)
        @Expect(noneD.severity, "fatal")
        @Expect(noneD.message, "空指针解引用")
    }
}

/// 全量错误码一致性校验：遍历全部 128 个变体（120 规范码 + 8 向后兼容别名）。
/// 任一变体若缺失 META 条目，category()/severity()/template() 内部 META.get(...).getOrThrow() 会抛错 → 测试失败。
@Test
class ErrorCodeCompletenessTest {
    @TestCase func testAllCodesHaveMetaAndConsistent(): Unit {
        let all = ErrorCode.all()
        var count = 0
        for (c in all) {
            count = count + 1
            // 这些访问均经 META.get(...).getOrThrow()，缺条目即抛错中断本用例
            let code = c.code()
            let cat = c.category()
            let sev = c.severity()
            let tpl = c.template()
            // 码前缀必须与所属类别前缀一致（如 E00xx -> Lexer、E2001 -> Type）
            @Expect(code.startsWith(cat.codePrefix()), true)
            // 严重级别必须落在三级之内
            @Expect(sev == Severity.Fatal || sev == Severity.Error || sev == Severity.Warning, true)
            // 模板不得为空
            @Expect(tpl.size > 0, true)
        }
        // 锁定变体总数：120 规范 + 8 别名
        @Expect(count, 128)
    }
}
