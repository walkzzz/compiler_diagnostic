package compiler_diagnostic.diagnostics

import std.collection.*

/// ============================================================
/// 真实 cjc 诊断 → 本工程 ErrorCode 桥接层（C 方案）
/// ============================================================
///
/// 目标：把仓颉编译器 `cjc` 真实输出的诊断文本（stderr/stdout）映射到本工程的
/// 结构化 `ErrorCode` 体系，使下游 `fromCode` / JSON / LSP 输出、VS Code 插件
/// 能用同一套 E 码消费诊断，而不必硬编码 cjc 的内部码。
///
/// 真实 cjc 输出形态（节选自 intellij-cangjie 实测与官方文档）：
///   error: mismatched types ==> main.cj:3:10:
///       let x: Int64 = "hello"
///                   ^~~~~~~
///   note: expected `Int64`, found `String`
/// 或带内部码：
///   error[E667]: type mismatch ...
///
/// 设计：数据驱动 + 关键词/子串匹配。规则表放在 `cjc_bridge.json`（由
/// `tools/gen_vscode_map.py` 同源维护思路），此处以代码内建一条保守、确定的
/// 映射，保证不引用任何不存在的 ErrorCode 变体；无法识别时返回 None，
/// 上层可回退到原始文本。

/// 单条桥接规则：在 cjc 诊断消息（已转小写）中命中 `keyword` 子串 → 映射到 `code`。
struct CjcPattern {
    /// 用于匹配的子串（小写）
    var keyword: String
    /// 映射目标错误码变体
    var code: ErrorCode

    public init(keyword!: String, code!: ErrorCode) {
        this.keyword = keyword
        this.code = code
    }
}

/// cjc 内部码（如 E667）→ 本工程 ErrorCode 的确定性映射。
/// 来源：intellij-cangjie 仓库维护的 cjc 官方错误码语义。
struct CjcInternalCode {
    var raw: String
    var code: ErrorCode

    public init(raw!: String, code!: ErrorCode) {
        this.raw = raw
        this.code = code
    }
}

/// 构建关键词桥接表（仅引用真实存在的 ErrorCode 变体）。
func buildCjcPatterns(): ArrayList<CjcPattern> {
    let l = ArrayList<CjcPattern>()
    // Lexer / Parser
    l.add(CjcPattern(keyword: "unterminated string", code: ErrorCode.ParserUnterminatedString))
    l.add(CjcPattern(keyword: "unclosed string", code: ErrorCode.ParserUnterminatedString))
    l.add(CjcPattern(keyword: "mismatched bracket", code: ErrorCode.ParserMismatchedBracket))
    l.add(CjcPattern(keyword: "unexpected token", code: ErrorCode.ParserInvalidExpression))
    l.add(CjcPattern(keyword: "unexpected end of file", code: ErrorCode.ParserUnexpectedToken))
    l.add(CjcPattern(keyword: "duplicate import", code: ErrorCode.ParserDuplicateImport))
    // Sema / 符号解析
    l.add(CjcPattern(keyword: "undeclared identifier", code: ErrorCode.SemaUndefinedSymbol))
    l.add(CjcPattern(keyword: "cannot find", code: ErrorCode.SemaUndefinedSymbol))
    l.add(CjcPattern(keyword: "cannot infer", code: ErrorCode.TypeInferenceFailed))
    l.add(CjcPattern(keyword: "type inference", code: ErrorCode.TypeInferenceFailed))
    l.add(CjcPattern(keyword: "duplicate definition", code: ErrorCode.SemaDuplicateImportItem))
    l.add(CjcPattern(keyword: "redefinition", code: ErrorCode.SemaDuplicateImportItem))
    // Type
    l.add(CjcPattern(keyword: "mismatched types", code: ErrorCode.TypeMismatch))
    l.add(CjcPattern(keyword: "type mismatch", code: ErrorCode.TypeMismatch))
    l.add(CjcPattern(keyword: "ambiguous", code: ErrorCode.TypeAmbiguousOverload))
    l.add(CjcPattern(keyword: "constraint violated", code: ErrorCode.TypeConstraintViolation))
    l.add(CjcPattern(keyword: "trait bound", code: ErrorCode.TypeConstraintViolation))
    // Resolution / 可见性 / 导入
    l.add(CjcPattern(keyword: "private", code: ErrorCode.ResolutionPrivateAccess))
    l.add(CjcPattern(keyword: "module not found", code: ErrorCode.ResolutionModuleNotFound))
    l.add(CjcPattern(keyword: "import not found", code: ErrorCode.ResolutionImportNotFound))
    // Macro
    l.add(CjcPattern(keyword: "macro", code: ErrorCode.MacroUndefinedIdentifier))
    // Runtime / 内存
    l.add(CjcPattern(keyword: "null pointer", code: ErrorCode.RuntimeNullDereference))
    l.add(CjcPattern(keyword: "null dereference", code: ErrorCode.RuntimeNullDereference))
    // Backend / 链接
    l.add(CjcPattern(keyword: "llvm verify", code: ErrorCode.BackendLlvmVerifyFailed))
    l.add(CjcPattern(keyword: "linker", code: ErrorCode.CodegenLinkerFailed))
    return l
}

/// 构建 cjc 内部码映射表。
func buildCjcInternalCodes(): ArrayList<CjcInternalCode> {
    let l = ArrayList<CjcInternalCode>()
    // 下列 raw 为 cjc 官方内部码（intellij-cangjie 语义），右侧为本工程 ErrorCode。
    l.add(CjcInternalCode(raw: "e667", code: ErrorCode.TypeMismatch))          // type mismatch
    l.add(CjcInternalCode(raw: "e75", code: ErrorCode.SemaUndefinedSymbol))    // undeclared identifier
    l.add(CjcInternalCode(raw: "e673", code: ErrorCode.SemaDuplicateImportItem)) // duplicate definition
    l.add(CjcInternalCode(raw: "e488", code: ErrorCode.ResolutionModuleNotFound)) // package/module not found
    l.add(CjcInternalCode(raw: "e671", code: ErrorCode.TypeInferenceFailed))   // cannot infer type
    return l
}

let CJC_PATTERNS: ArrayList<CjcPattern> = buildCjcPatterns()
let CJC_INTERNAL: ArrayList<CjcInternalCode> = buildCjcInternalCodes()

/// ASCII 大小写不敏感匹配辅助：将字符串转换为小写（仅 ASCII 字母 A-Z）。
/// 说明：Cangjie 1.1.3 的 `String` 没有 `toLowerCase()` 成员，且 `for (b in s)` 得到的是
/// UInt8（UTF-8 字节）而非 Rune；这里按字节做 A-Z→a-z 映射后由 UTF-8 字节重建 String。
func toLower(s: String): String {
    let out = ArrayList<Rune>()
    // Cangjie 1.1.3：`for (b in s)` 得到的是 UInt8（UTF-8 字节），`String` 由 `Array<Rune>` 构造。
    // 'A' 是 String 字面量而非 Rune，故用 ASCII 码点（65/90）比较，再经 Int64 构造 Rune。
    // 对 ASCII 诊断文本完全正确；非 ASCII 字节会被逐字节映射，但不影响关键词匹配。
    for (b in s) {
        if (b >= 65u8 && b <= 90u8) {
            out.add(Rune(Int64(b) + 32))
        } else {
            out.add(Rune(Int64(b)))
        }
    }
    return String(out.toArray())
}

/// 从一条 cjc 诊断原始文本解析出本工程的 ErrorCode。
/// 匹配优先级：内部码（error[Exxx]）> 关键词子串。无法识别返回 None。
///
/// 入参 `raw` 可是单条诊断（含 `error:` 行），也可是整段 stderr 文本。
public func resolveCjc(raw: String): Option<ErrorCode> {
    let low = toLower(raw)
    // 1) 内部码：匹配形如 error[E667] / [E667]
    for (ic in CJC_INTERNAL) {
        if (low.contains("[" + ic.raw + "]") || low.contains("error " + ic.raw)) {
            return Some(ic.code)
        }
    }
    // 2) 关键词 / 子串匹配（顺序即优先级，越靠前越具体）
    for (p in CJC_PATTERNS) {
        if (low.contains(p.keyword)) {
            return Some(p.code)
        }
    }
    return None
}
