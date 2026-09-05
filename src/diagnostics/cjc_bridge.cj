package compiler_diagnostic.diagnostics

import std.collection.*

/// ============================================================
/// 真实 cjc 诊断 → 本工程 ErrorCode 桥接层（生产级）
/// ============================================================
///
/// 目标：把仓颉编译器 `cjc` 真实输出的诊断文本映射到本工程的结构化
/// `ErrorCode` 体系，使下游 JSON / LSP 输出、VS Code 插件能用同一套 E 码消费
/// 诊断，而不必硬编码 cjc 的内部码。
///
/// 真实 cjc 1.1.3 文本输出形态（实测 `cjc bad.cj`）：
///   error: mismatched types
///    ==> D:\...\bad.cj:2:20:
///     | 
///   2 |     let x: Int64 = "hello"
///     |                    ^~~~~~~ expected 'Int64', found 'Struct-String'
///     | 
///
///   error: undeclared identifier 'undefined_symbol_xyz'
///    ==> D:\...\bad.cj:3:13:
///
/// 要点（生产化关键）：
/// 1. cjc 1.1.3 默认文本输出**不带** `error[Exxx]` 内部码，故内部码匹配仅作为
///    可选增强路径保留（若未来 cjc 版本开始输出内部码则自动生效）。
/// 2. 关键词匹配**仅针对 `error:` 消息行**，不再对 `^~~~~~` 片段行做子串匹配，
///    彻底消除“片段文本误命中关键词”的静默错配。
/// 3. 本文件中的映射表（CJC_PATTERNS / CJC_INTERNAL）为**权威源**；
///    `cjc_bridge.json` 是其镜像，由 `tools/check_bridge_consistency.py`
///    校验两者不漂移（CI 中强制执行）。

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

/// cjc 内部码（如 E667）→ 本工程 ErrorCode 的确定性映射（可选增强路径）。
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

/// 构建 cjc 内部码映射表（可选增强路径；cjc 1.1.3 默认不输出内部码）。
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
    for (b in s) {
        if (b >= 65u8 && b <= 90u8) {
            out.add(Rune(Int64(b) + 32))
        } else {
            out.add(Rune(Int64(b)))
        }
    }
    return String(out.toArray())
}

/// 从整段 cjc 输出中抽取每条诊断的**消息行**（不含 `^~~~~~` 片段行）。
/// 实现说明：Cangjie 1.1.3 的 `String.split` 实测仅对单字符分隔符稳定，故此处
/// 以 `split("\n")` 得到行，再筛出以 `error:` / `error[` 开头的消息行。
/// 片段行（如 `  | ^~~~~~~ expected ...`）不含 `error:`，自然被排除，避免误命中。
///
/// 关键稳健性：cjc 在诊断文本中会嵌入 ANSI 颜色转义码（实测 `error\x1b[0m: ...`），
/// 必须先 `stripAnsi` 剥离，否则 `error:` 子串被转义码隔断导致匹配失败。
func extractErrorMessages(raw: String): ArrayList<String> {
    let clean = stripAnsi(raw)
    let msgs = ArrayList<String>()
    let lines = clean.split("\n")
    var i = 0
    while (i < lines.size) {
        let line = toLower(lines[i])
        // 仅处理诊断消息行：error: <msg> 或 error[Exxx]: <msg>
        if (line.contains("error:") || line.contains("error[")) {
            msgs.add(line)
        }
        i = i + 1
    }
    return msgs
}

/// 剥离 ANSI/VT100 转义序列（CSI: ESC [ ... <final> 等），避免颜色码干扰诊断文本匹配。
/// 仅移除 `\x1b` 引导的控制序列，保留全部可见文本。
func stripAnsi(s: String): String {
    let bs = ArrayList<UInt8>()
    for (b in s) {
        bs.add(b)
    }
    let out = ArrayList<UInt8>()
    var i = 0
    let n = bs.size
    while (i < n) {
        let b = bs[i]
        if (b == 27u8) {  // ESC
            i = i + 1  // 跳过 ESC
            if (i < n && bs[i] == 91u8) { i = i + 1 }  // 跳过 '['（CSI 引导符）
            while (i < n) {
                let c = bs[i]
                if (c >= 64u8) { i = i + 1; break }  // 遇到最终字节（如 'm'）即序列结束
                i = i + 1
            }
            continue
        }
        out.add(b)
        i = i + 1
    }
    return String.fromUtf8(out.toArray())
}

/// 在单条消息上做匹配：内部码优先，其次关键词。无命中返回 None。
func matchOne(msg: String): Option<ErrorCode> {
    // 1) 内部码：形如 error[E667] / [E667]（可选增强路径）
    for (ic in CJC_INTERNAL) {
        if (msg.contains("[" + ic.raw + "]") || msg.contains("error " + ic.raw)) {
            return Some(ic.code)
        }
    }
    // 2) 关键词 / 子串匹配（顺序即优先级，越靠前越具体）
    for (p in CJC_PATTERNS) {
        if (msg.contains(p.keyword)) {
            return Some(p.code)
        }
    }
    return None
}

/// 从一条 cjc 诊断原始文本解析出本工程的 ErrorCode。
/// 匹配范围仅限 `error:` 消息行（见 `extractErrorMessages`），消息行内无命中返回 None。
/// 入参 `raw` 可是单条诊断，也可是整段 stderr 文本。
public func resolveCjc(raw: String): Option<ErrorCode> {
    let msgs = extractErrorMessages(raw)
    for (m in msgs) {
        let r = matchOne(m)
        match (r) {
            case Some(c) => return Some(c)
            case None => continue
        }
    }
    return None
}

/// 解析整段 cjc 输出为多条 ErrorCode（每个 `error:` 块一条，跳过无法识别的）。
/// 供 `from-cjc` 子命令批量产出结构化 JSON 使用。
public func parseCjcDiagnostics(raw: String): ArrayList<ErrorCode> {
    let out = ArrayList<ErrorCode>()
    let msgs = extractErrorMessages(raw)
    for (m in msgs) {
        let r = matchOne(m)
        match (r) {
            case Some(c) => out.add(c)
            case None => continue
        }
    }
    return out
}
