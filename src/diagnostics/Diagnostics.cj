package compiler_diagnostic.diagnostics
import std.collection.*

/// 源码位置信息，对应 LSP Position 规范
public struct SourceLoc {
    /// 行号（从 0 开始）
    public var line: Int64
    /// 列号（从 0 开始）
    public var column: Int64
    /// 文件名
    public var file: String

    /// 构造函数：完整参数
    public init(line!: Int64, column!: Int64, file!: String) {
        this.line = line
        this.column = column
        this.file = file
    }

    public init(line!: Int64, column!: Int64) {
        this.line = line
        this.column = column
        this.file = ""
    }

    public init() {
        this.line = 0
        this.column = 0
        this.file = ""
    }

    public func equals(other: SourceLoc): Bool {
        return this.line == other.line && this.column == other.column && this.file == other.file
    }

    public func isBefore(other: SourceLoc): Bool {
        if (this.line != other.line) {
            return this.line < other.line
        }
        return this.column < other.column
    }
}

/// 源码范围（对应 LSP Range）
public struct Span {
    public var start: SourceLoc
    public var end: SourceLoc

    public init(start!: SourceLoc, end!: SourceLoc) {
        this.start = start
        this.end = end
    }

    public func lineCount(): Int64 {
        return this.end.line - this.start.line + 1
    }
}

/// 关联位置信息
public struct RelatedInfo {
    public var span: Span
    public var message: String

    public init(span!: Span, message!: String) {
        this.span = span
        this.message = message
    }
}

/// 诊断关联备注模板（结构性字段：把 "在此声明 / 在此使用" 等静态说明与运行时 span 角色绑定）
public struct DiagnosticNote {
    /// 备注文本（纯文本，避免与模板 {placeholder} 混淆；可写 "在此声明" 等）
    public var message: String
    /// 该备注对应的源码位置角色名（如 "declaredHere" / "usedHere" / "primary"），生产者据角色解析真实 Span
    public var spanRole: String

    public init(message!: String, spanRole!: String) {
        this.message = message
        this.spanRole = spanRole
    }
}

/// 修复建议，对应 LSP CodeAction
public struct FixSuggestion {
    public var description: String
    public var replacement: String
    public var span: Option<Span>

    public init(description!: String) {
        this.description = description
        this.replacement = ""
        this.span = None
    }

    public init(description!: String, replacement!: String) {
        this.description = description
        this.replacement = replacement
        this.span = None
    }

    public init(description!: String, replacement!: String, span!: Span) {
        this.description = description
        this.replacement = replacement
        this.span = Some(span)
    }
}

/// 结构化候选符号（指标 B：候选符号及其类型/种类，便于 IDE 显示「foo: Int64」式提示）
public struct Candidate {
    /// 候选符号名称
    public var name: String
    /// 候选符号的类型或种类（如 "variable" / "function" / "type" / 具体类型 "Int64"）
    public var kind: String

    public init(name!: String, kind!: String) {
        this.name = name
        this.kind = kind
    }
}

/// 严重级别（Fatal > Error > Warning），映射到 LSP DiagnosticSeverity
public enum Severity <: Equatable<Severity> {
    | Fatal
    | Error
    | Warning

    /// 人类可读标签（用于默认 JSON 模式与文本输出）
    public func label(): String {
        match (this) {
            case Severity.Fatal => "fatal"
            case Severity.Error => "error"
            case Severity.Warning => "warning"
        }
    }

    /// 映射到 LSP DiagnosticSeverity：Fatal/Error -> 1，Warning -> 2
    public func toLspSeverity(): Int64 {
        match (this) {
            case Severity.Fatal => 1
            case Severity.Error => 1
            case Severity.Warning => 2
        }
    }

    public operator func ==(other: Severity): Bool {
        return this.label() == other.label()
    }
}

/// 错误码类别（按编译前端到后端流水线划分，共 8 大类）
public enum ErrorCategory <: Equatable<ErrorCategory> {
    | Lexer
    | Parser
    | Sema
    | Type
    | Resolution
    | Codegen
    | Runtime
    | System

    /// 编码前缀（便于按区间批量过滤与 IDE 分组展示）
    | Macro
    | Trait
    | Borrow
    | Lifetime
    | Generic
    | Module
    | Backend
    | Opt
    | Linker
    | Abi
    | Concurrency
    | Mem
    | Os
    | Lsp
    | Incremental
    | Pkg
    | Build
    | Debug
    | Dist
    | Plugin
    | Tgt
    | Simd
    | Embed
    | Test
    | Doc
    | Lint
    | Sec
    | Conf
    | Telem
    | Xcompile
    | Wasm
    | Gpu
    public func codePrefix(): String {
        match (this) {
            case ErrorCategory.Macro => "E02"
            case ErrorCategory.Trait => "E03"
            case ErrorCategory.Borrow => "E04"
            case ErrorCategory.Lifetime => "E05"
            case ErrorCategory.Generic => "E06"
            case ErrorCategory.Module => "E07"
            case ErrorCategory.Backend => "E11"
            case ErrorCategory.Opt => "E12"
            case ErrorCategory.Linker => "E13"
            case ErrorCategory.Abi => "E14"
            case ErrorCategory.Concurrency => "E51"
            case ErrorCategory.Mem => "E52"
            case ErrorCategory.Os => "E53"
            case ErrorCategory.Lsp => "E60"
            case ErrorCategory.Incremental => "E61"
            case ErrorCategory.Pkg => "E62"
            case ErrorCategory.Build => "E63"
            case ErrorCategory.Debug => "E64"
            case ErrorCategory.Dist => "E65"
            case ErrorCategory.Plugin => "E66"
            case ErrorCategory.Tgt => "E67"
            case ErrorCategory.Simd => "E68"
            case ErrorCategory.Embed => "E69"
            case ErrorCategory.Test => "E70"
            case ErrorCategory.Doc => "E71"
            case ErrorCategory.Lint => "E72"
            case ErrorCategory.Sec => "E73"
            case ErrorCategory.Conf => "E74"
            case ErrorCategory.Telem => "E75"
            case ErrorCategory.Xcompile => "E76"
            case ErrorCategory.Wasm => "E77"
            case ErrorCategory.Gpu => "E78"

            case ErrorCategory.Lexer => "E00"
            case ErrorCategory.Parser => "E01"
            case ErrorCategory.Sema => "E10"
            case ErrorCategory.Type => "E20"
            case ErrorCategory.Resolution => "E30"
            case ErrorCategory.Codegen => "E40"
            case ErrorCategory.Runtime => "E50"
            case ErrorCategory.System => "E90"
        }
    }

    /// 所处阶段
    public func stage(): String {
        match (this) {
            case ErrorCategory.Macro => "中端"
            case ErrorCategory.Trait => "中端"
            case ErrorCategory.Borrow => "中端"
            case ErrorCategory.Lifetime => "中端"
            case ErrorCategory.Generic => "中端"
            case ErrorCategory.Module => "中端"
            case ErrorCategory.Backend => "后端"
            case ErrorCategory.Opt => "后端"
            case ErrorCategory.Linker => "后端"
            case ErrorCategory.Abi => "后端"
            case ErrorCategory.Concurrency => "运行期"
            case ErrorCategory.Mem => "运行期"
            case ErrorCategory.Os => "运行期"
            case ErrorCategory.Lsp => "全阶段"
            case ErrorCategory.Incremental => "全阶段"
            case ErrorCategory.Pkg => "全阶段"
            case ErrorCategory.Build => "全阶段"
            case ErrorCategory.Debug => "全阶段"
            case ErrorCategory.Dist => "全阶段"
            case ErrorCategory.Plugin => "全阶段"
            case ErrorCategory.Tgt => "后端"
            case ErrorCategory.Simd => "后端"
            case ErrorCategory.Embed => "后端"
            case ErrorCategory.Test => "全阶段"
            case ErrorCategory.Doc => "全阶段"
            case ErrorCategory.Lint => "全阶段"
            case ErrorCategory.Sec => "全阶段"
            case ErrorCategory.Conf => "全阶段"
            case ErrorCategory.Telem => "全阶段"
            case ErrorCategory.Xcompile => "后端"
            case ErrorCategory.Wasm => "后端"
            case ErrorCategory.Gpu => "后端"

            case ErrorCategory.Lexer => "前端"
            case ErrorCategory.Parser => "前端"
            case ErrorCategory.Sema => "中端"
            case ErrorCategory.Type => "中端"
            case ErrorCategory.Resolution => "中端"
            case ErrorCategory.Codegen => "后端"
            case ErrorCategory.Runtime => "运行期"
            case ErrorCategory.System => "全阶段"
        }
    }

    /// 类别展示名
    public func displayName(): String {
        match (this) {
            case ErrorCategory.Macro => "Macro（宏系统）"
            case ErrorCategory.Trait => "Trait（特质/接口）"
            case ErrorCategory.Borrow => "Borrow（所有权/借用）"
            case ErrorCategory.Lifetime => "Lifetime（生命周期）"
            case ErrorCategory.Generic => "Generic（泛型）"
            case ErrorCategory.Module => "Module（模块系统）"
            case ErrorCategory.Backend => "Backend（后端/LLVM）"
            case ErrorCategory.Opt => "Optimizer（优化器）"
            case ErrorCategory.Linker => "Linker（链接器）"
            case ErrorCategory.Abi => "ABI/FFI（二进制接口）"
            case ErrorCategory.Concurrency => "Concurrency（并发/协程）"
            case ErrorCategory.Mem => "Memory（内存/GC）"
            case ErrorCategory.Os => "OS（系统调用）"
            case ErrorCategory.Lsp => "LSP/IDE（编辑器协议）"
            case ErrorCategory.Incremental => "Incremental（增量编译）"
            case ErrorCategory.Pkg => "Package（包管理）"
            case ErrorCategory.Build => "Build（构建系统）"
            case ErrorCategory.Debug => "Debugger（调试信息）"
            case ErrorCategory.Dist => "Distributed（分布式编译）"
            case ErrorCategory.Plugin => "Plugin（插件扩展）"
            case ErrorCategory.Tgt => "Target（目标平台）"
            case ErrorCategory.Simd => "SIMD（向量化）"
            case ErrorCategory.Embed => "Embedded（嵌入式/CGO）"
            case ErrorCategory.Test => "Test（测试框架）"
            case ErrorCategory.Doc => "Doc（文档/Doctest）"
            case ErrorCategory.Lint => "Lint（静态检查）"
            case ErrorCategory.Sec => "Security（安全）"
            case ErrorCategory.Conf => "Config（配置/Profile）"
            case ErrorCategory.Telem => "Telemetry（可观测）"
            case ErrorCategory.Xcompile => "CrossCompile（交叉编译）"
            case ErrorCategory.Wasm => "WASM（WebAssembly）"
            case ErrorCategory.Gpu => "GPU（并行计算）"

            case ErrorCategory.Lexer => "Lexer（词法分析）"
            case ErrorCategory.Parser => "Parser（语法分析）"
            case ErrorCategory.Sema => "Sema（语义分析）"
            case ErrorCategory.Type => "Type（类型系统）"
            case ErrorCategory.Resolution => "Resolution（名称解析）"
            case ErrorCategory.Codegen => "Codegen（代码生成）"
            case ErrorCategory.Runtime => "Runtime（运行时）"
            case ErrorCategory.System => "System（系统/内部）"
        }
    }

    public operator func ==(other: ErrorCategory): Bool {
        return this.codePrefix() == other.codePrefix()
    }
}

/// 错误码元数据（集中存放，避免在每个访问方法中重复 match）
struct ErrorMeta {
    var code: String
    var category: ErrorCategory
    var severity: Severity
    var template: String
    var fix: Option<FixSuggestion>
    /// 结构化关联备注（B 方案：related notes / secondary labels）。每条绑定一个 span 角色名，
    /// 由诊断生产者据角色解析真实 Span；无角色绑定时作为纯文本备注展示。
    var notes: ArrayList<DiagnosticNote> = ArrayList<DiagnosticNote>()
    /// 主位置角色名（默认 "primary"），生产者据此解析主 Span
    var primarySpanRole: String = "primary"

    public init(code!: String, category!: ErrorCategory, severity!: Severity, template!: String, fix!: Option<FixSuggestion>) {
        this.code = code
        this.category = category
        this.severity = severity
        this.template = template
        this.fix = fix
    }

    /// 含结构性备注的构造重载（B 方案）
    public init(code!: String, category!: ErrorCategory, severity!: Severity, template!: String, fix!: Option<FixSuggestion>,
        notes!: ArrayList<DiagnosticNote>, primarySpanRole!: String) {
        this.code = code
        this.category = category
        this.severity = severity
        this.template = template
        this.fix = fix
        this.notes = notes
        this.primarySpanRole = primarySpanRole
    }

    /// 将 notes 模板按角色解析为 RelatedInfo 列表（角色无法解析时退化为零位置备注）
    public func relatedNotes(resolve: (String) -> Option<Span>): List<RelatedInfo> {
        let out = ArrayList<RelatedInfo>()
        let zero = Span(start: SourceLoc(line: 0, column: 0), end: SourceLoc(line: 0, column: 0))
        for (n in this.notes) {
            let span = match (resolve(n.spanRole)) {
                case Some(s) => s
                case None => zero
            }
            out.add(RelatedInfo(span: span, message: n.message))
        }
        return out
    }
}

/// 全部错误码元数据表（key 为错误码字符串）
let META: Map<String, ErrorMeta> = buildMeta()

func buildMeta(): Map<String, ErrorMeta> {
    let m = HashMap<String, ErrorMeta>()
    // 拆分为多个子函数：1519 条元数据集中在单一函数会超出 cjc 的栈帧上限（1MB），
    // 按错误类别分组填充，可显著降低单帧大小（原因见 docs/诊断报告.md）。
    buildMetaPart1(m)
    buildMetaPart2(m)
    buildMetaPart3(m)
    buildMetaPart4(m)
    buildMetaPart5(m)
    buildMetaPart6(m)
    buildMetaPart7(m)
    buildMetaPart8(m)
    return m
}

/// 填充错误码元数据第 1 组（Lexer .. Resolution），共 5 个类别。
func buildMetaPart1(m: HashMap<String, ErrorMeta>) {
    m["E0001"] = ErrorMeta(code: "E0001", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "字符串字面量未闭合，缺少结束引号", fix: Some(FixSuggestion(description: "添加结束引号", replacement: "\"")))
    m["E0002"] = ErrorMeta(code: "E0002", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "块注释未闭合，缺少 */", fix: Some(FixSuggestion(description: "补充 */", replacement: "*/")))
    m["E0003"] = ErrorMeta(code: "E0003", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "非法转义字符：{escape}", fix: Some(FixSuggestion(description: "使用合法转义序列或原始字符串")))
    m["E0004"] = ErrorMeta(code: "E0004", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "数字字面量格式错误：{literal}", fix: Some(FixSuggestion(description: "检查进制前缀或小数格式")))
    m["E0005"] = ErrorMeta(code: "E0005", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "遇到无法识别的字符：{char}", fix: Some(FixSuggestion(description: "删除非法字符或检查文件编码")))
    m["E0006"] = ErrorMeta(code: "E0006", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "标识符包含非法字符：{name}", fix: Some(FixSuggestion(description: "重命名标识符")))
    m["E0007"] = ErrorMeta(code: "E0007", category: ErrorCategory.Lexer, severity: Severity.Warning,
        template: "数字字面量超出类型范围：{literal}", fix: Some(FixSuggestion(description: "改用更大类型或添加字面量后缀")))
    m["E0008"] = ErrorMeta(code: "E0008", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "字符字面量未闭合，缺少单引号", fix: Some(FixSuggestion(description: "添加单引号", replacement: "'")))
    m["E0009"] = ErrorMeta(code: "E0009", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "空字符字面量", fix: Some(FixSuggestion(description: "填入字符或使用转义")))
    m["E0010"] = ErrorMeta(code: "E0010", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "源文件含非法 UTF-8 序列", fix: Some(FixSuggestion(description: "修正文件编码为 UTF-8")))
    m["E0011"] = ErrorMeta(code: "E0011", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "非法的数字字面量后缀：{suffix}", fix: Some(FixSuggestion(description: "检查字面量后缀拼写")))
    m["E0012"] = ErrorMeta(code: "E0012", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "字符串字面量中出现裸换行", fix: Some(FixSuggestion(description: "用转义序列或字符串拼接替代裸换行")))
    m["E0013"] = ErrorMeta(code: "E0013", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "标识符以非法字符开头：{char}", fix: Some(FixSuggestion(description: "以字母或下划线开头")))
    m["E0014"] = ErrorMeta(code: "E0014", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "非法的原始字符串定界符", fix: Some(FixSuggestion(description: "使用成对的 # 定界符")))
    m["E0015"] = ErrorMeta(code: "E0015", category: ErrorCategory.Lexer, severity: Severity.Warning,
        template: "嵌套注释层数过深", fix: Some(FixSuggestion(description: "减少注释嵌套层级")))
    m["E0016"] = ErrorMeta(code: "E0016", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "非法 Unicode 转义序列：{seq}", fix: Some(FixSuggestion(description: "使用合法 \\uXXXX 转义")))
    m["E0017"] = ErrorMeta(code: "E0017", category: ErrorCategory.Lexer, severity: Severity.Warning,
        template: "整数字面量含前导零：{literal}", fix: Some(FixSuggestion(description: "移除前导零或显式标注进制")))
    m["E0018"] = ErrorMeta(code: "E0018", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "字符字面量包含多余字符", fix: Some(FixSuggestion(description: "只保留单个字符")))
    m["E0019"] = ErrorMeta(code: "E0019", category: ErrorCategory.Lexer, severity: Severity.Warning,
        template: "检测到非标准换行符（如单独 \\r）", fix: Some(FixSuggestion(description: "统一使用 \\n 换行")))
    m["E0020"] = ErrorMeta(code: "E0020", category: ErrorCategory.Lexer, severity: Severity.Warning,
        template: "源码含 BOM 且编码声明冲突", fix: Some(FixSuggestion(description: "移除 BOM 或统一编码声明")))
    m["E0021"] = ErrorMeta(code: "E0021", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "数值字面量中的分隔符(_)位置非法", fix: Some(FixSuggestion(description: "移除或仅将 _ 用于分组数字")))
    m["E0022"] = ErrorMeta(code: "E0022", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "原生(raw)字符串字面量未闭合", fix: Some(FixSuggestion(description: "补全结束定界符")))
    m["E0023"] = ErrorMeta(code: "E0023", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "字符串前缀非法（不支持的编码或类型前缀）", fix: None)
    m["E0024"] = ErrorMeta(code: "E0024", category: ErrorCategory.Lexer, severity: Severity.Warning,
        template: "源码文件编码声明与 BOM 冲突", fix: Some(FixSuggestion(description: "统一编码声明与 BOM")))
    m["E0025"] = ErrorMeta(code: "E0025", category: ErrorCategory.Lexer, severity: Severity.Warning,
        template: "源码含零宽字符，可能导致不可见错误", fix: Some(FixSuggestion(description: "删除零宽字符")))
    m["E0026"] = ErrorMeta(code: "E0026", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "浮点/科学计数法字面量格式错误：{literal}", fix: Some(FixSuggestion(description: "按规范书写浮点或指数部分")))
    m["E0027"] = ErrorMeta(code: "E0027", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "基数前缀字面量（0x/0o/0b）格式错误：{literal}", fix: Some(FixSuggestion(description: "检查基数前缀后的有效数字")))
    m["E0028"] = ErrorMeta(code: "E0028", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "字面量长度超过限制：{name}", fix: Some(FixSuggestion(description: "拆分为多个字面量或缩短")))
    m["E0029"] = ErrorMeta(code: "E0029", category: ErrorCategory.Lexer, severity: Severity.Error,
        template: "多字节字符被截断（无效 UTF-8 续字节）", fix: None)
    // ---------------- Parser 语法分析（E01xx） ----------------
    m["E0101"] = ErrorMeta(code: "E0101", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "字符串字面量未闭合", fix: Some(FixSuggestion(description: "添加结束引号", replacement: "\"")))
    m["E0102"] = ErrorMeta(code: "E0102", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "遇到非预期 Token：{token}", fix: Some(FixSuggestion(description: "检查缺失或多余的符号")))
    m["E0103"] = ErrorMeta(code: "E0103", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "缺少分号", fix: Some(FixSuggestion(description: "在语句末尾补充分号", replacement: ";")))
    m["E0104"] = ErrorMeta(code: "E0104", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "括号不匹配", fix: Some(FixSuggestion(description: "补全或删除多余的括号")))
    m["E0105"] = ErrorMeta(code: "E0105", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "表达式语法不合法", fix: Some(FixSuggestion(description: "修正运算符或操作数")))
    m["E0106"] = ErrorMeta(code: "E0106", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "缺少冒号", fix: Some(FixSuggestion(description: "补充冒号", replacement: ":")))
    m["E0107"] = ErrorMeta(code: "E0107", category: ErrorCategory.Parser, severity: Severity.Warning,
        template: "重复修饰符：{modifier}", fix: Some(FixSuggestion(description: "删除重复的修饰符")))
    m["E0108"] = ErrorMeta(code: "E0108", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "声明语法错误", fix: Some(FixSuggestion(description: "修正声明格式")))
    m["E0109"] = ErrorMeta(code: "E0109", category: ErrorCategory.Parser, severity: Severity.Warning,
        template: "不允许的尾随逗号", fix: Some(FixSuggestion(description: "删除多余的逗号")))
    m["E0110"] = ErrorMeta(code: "E0110", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "文件意外结束", fix: Some(FixSuggestion(description: "补全未闭合的结构")))
    m["E0111"] = ErrorMeta(code: "E0111", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "运算符缺少操作数", fix: Some(FixSuggestion(description: "补充缺失的操作数")))
    m["E0112"] = ErrorMeta(code: "E0112", category: ErrorCategory.Parser, severity: Severity.Warning,
        template: "修饰符顺序非法", fix: Some(FixSuggestion(description: "按规范顺序调整修饰符")))
    m["E0113"] = ErrorMeta(code: "E0113", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "重复的导入声明：{name}", fix: Some(FixSuggestion(description: "删除重复导入")))
    m["E0114"] = ErrorMeta(code: "E0114", category: ErrorCategory.Parser, severity: Severity.Warning,
        template: "非预期的表达式语句", fix: Some(FixSuggestion(description: "将结果绑定到 _ 或显式忽略")))
    m["E0115"] = ErrorMeta(code: "E0115", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "非法的顶层语句", fix: Some(FixSuggestion(description: "将语句移入函数或 init 块")))
    m["E0116"] = ErrorMeta(code: "E0116", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "期望标识符，却得到 {token}", fix: Some(FixSuggestion(description: "检查是否为关键字误用")))
    m["E0117"] = ErrorMeta(code: "E0117", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "缺少类型注解：{name}", fix: Some(FixSuggestion(description: "为声明显式标注类型")))
    m["E0118"] = ErrorMeta(code: "E0118", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "泛型参数列表未闭合", fix: Some(FixSuggestion(description: "补上 >")))
    m["E0119"] = ErrorMeta(code: "E0119", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "函数参数名重复：{name}", fix: Some(FixSuggestion(description: "重命名重复参数")))
    m["E0120"] = ErrorMeta(code: "E0120", category: ErrorCategory.Parser, severity: Severity.Warning,
        template: "标注（annotation）位置非法", fix: Some(FixSuggestion(description: "将标注移至允许的声明位置")))
    m["E0121"] = ErrorMeta(code: "E0121", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "泛型约束语法非法", fix: None)
    m["E0122"] = ErrorMeta(code: "E0122", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "函数声明缺少返回类型标注", fix: Some(FixSuggestion(description: "补充返回类型标注")))
    m["E0123"] = ErrorMeta(code: "E0123", category: ErrorCategory.Parser, severity: Severity.Warning,
        template: "文档注释未附着到任何声明", fix: None)
    m["E0124"] = ErrorMeta(code: "E0124", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "属性注解应用到了不支持的目标", fix: None)
    m["E0125"] = ErrorMeta(code: "E0125", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "可变性修饰符相互冲突（mut 与不可变注解并存）", fix: None)
    m["E0126"] = ErrorMeta(code: "E0126", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "模式（pattern）语法非法", fix: Some(FixSuggestion(description: "检查解构/通配符位置")))
    m["E0127"] = ErrorMeta(code: "E0127", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "结构体/枚举/接口成员声明语法非法", fix: Some(FixSuggestion(description: "检查成员声明与分隔符")))
    m["E0128"] = ErrorMeta(code: "E0128", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "lambda/闭包表达式语法非法", fix: Some(FixSuggestion(description: "检查参数列表与箭头")))
    m["E0129"] = ErrorMeta(code: "E0129", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "字符串插值 \${} 语法非法", fix: Some(FixSuggestion(description: "补全插值表达式或转义 $")))
    m["E0130"] = ErrorMeta(code: "E0130", category: ErrorCategory.Parser, severity: Severity.Error,
        template: "条件表达式缺少 else 分支", fix: Some(FixSuggestion(description: "补充 else 分支")))
    m["E0131"] = ErrorMeta(code: "E0131", category: ErrorCategory.Parser, severity: Severity.Warning,
        template: "运算符优先级/结合性可能产生歧义", fix: Some(FixSuggestion(description: "使用括号显式分组")))
    // ---------------- Sema 语义分析（E10xx） ----------------
    m["E1001"] = ErrorMeta(code: "E1001", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "使用了未定义的符号：{name}", fix: Some(FixSuggestion(description: "检查拼写或补充定义")),
        notes: ArrayList<DiagnosticNote>([DiagnosticNote(message: "在作用域内未找到该符号的声明，请确认拼写或导入", spanRole: "declaredHere")]),
        primarySpanRole: "useSite")
    m["E1002"] = ErrorMeta(code: "E1002", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "符号重复声明：{name}", fix: Some(FixSuggestion(description: "重命名或删除重复声明")))
    m["E1003"] = ErrorMeta(code: "E1003", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "函数实参数量不匹配：期望 {expected}，实际 {actual}", fix: Some(FixSuggestion(description: "调整调用处的参数数量")))
    m["E1004"] = ErrorMeta(code: "E1004", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "对不可变变量赋值：{name}", fix: Some(FixSuggestion(description: "改为可变声明或移除赋值")))
    m["E1005"] = ErrorMeta(code: "E1005", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "声明前使用：{name}", fix: Some(FixSuggestion(description: "调整声明顺序")))
    m["E1006"] = ErrorMeta(code: "E1006", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "break/continue 出现在循环外", fix: Some(FixSuggestion(description: "移入循环或删除")))
    m["E1007"] = ErrorMeta(code: "E1007", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "函数缺少返回语句", fix: Some(FixSuggestion(description: "补充 return 或更改返回类型")))
    m["E1008"] = ErrorMeta(code: "E1008", category: ErrorCategory.Sema, severity: Severity.Warning,
        template: "不可达代码", fix: Some(FixSuggestion(description: "删除死代码")))
    m["E1009"] = ErrorMeta(code: "E1009", category: ErrorCategory.Sema, severity: Severity.Warning,
        template: "变量遮蔽外层作用域：{name}", fix: Some(FixSuggestion(description: "重命名以提升可读性")))
    m["E1010"] = ErrorMeta(code: "E1010", category: ErrorCategory.Sema, severity: Severity.Warning,
        template: "使用了已废弃的 API：{name}", fix: Some(FixSuggestion(description: "迁移至推荐的 API")))
    m["E1011"] = ErrorMeta(code: "E1011", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "常量未初始化：{name}", fix: Some(FixSuggestion(description: "为常量提供初始值")))
    m["E1012"] = ErrorMeta(code: "E1012", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "导入项重复定义：{name}", fix: Some(FixSuggestion(description: "使用别名或全限定名")))
    m["E1013"] = ErrorMeta(code: "E1013", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "非法的递归调用：{name}", fix: Some(FixSuggestion(description: "重构为迭代或尾递归")))
    m["E1014"] = ErrorMeta(code: "E1014", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "match 表达式未覆盖全部分支", fix: Some(FixSuggestion(description: "补充缺失分支或使用通配臂")))
    m["E1015"] = ErrorMeta(code: "E1015", category: ErrorCategory.Sema, severity: Severity.Warning,
        template: "不可达的 match 分支", fix: Some(FixSuggestion(description: "删除不可达分支")))
    m["E1016"] = ErrorMeta(code: "E1016", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "泛型实例类型推导失败：{name}", fix: Some(FixSuggestion(description: "显式指定泛型实参")))
    m["E1017"] = ErrorMeta(code: "E1017", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "对不可变对象执行修改：{name}", fix: Some(FixSuggestion(description: "改为可变声明或移除修改")))
    m["E1018"] = ErrorMeta(code: "E1018", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "运算符重载签名不兼容：{op}", fix: Some(FixSuggestion(description: "调整运算符函数签名")))
    m["E1019"] = ErrorMeta(code: "E1019", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "接口默认实现冲突：{name}", fix: Some(FixSuggestion(description: "显式实现以消除歧义")))
    m["E1020"] = ErrorMeta(code: "E1020", category: ErrorCategory.Sema, severity: Severity.Warning,
        template: "主构造函数参数未使用：{name}", fix: Some(FixSuggestion(description: "移除未使用参数或使用下划线")))
    m["E1021"] = ErrorMeta(code: "E1021", category: ErrorCategory.Sema, severity: Severity.Warning,
        template: "循环体不可达（条件恒假）", fix: Some(FixSuggestion(description: "检查循环条件")))
    m["E1022"] = ErrorMeta(code: "E1022", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "类型转换的安全性标注非法", fix: Some(FixSuggestion(description: "使用受支持的转换标注")))
    m["E1023"] = ErrorMeta(code: "E1023", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "程序缺少入口 main 函数", fix: Some(FixSuggestion(description: "补充 main 函数")))
    m["E1024"] = ErrorMeta(code: "E1024", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "同一 trait 存在相互冲突的实现", fix: Some(FixSuggestion(description: "移除冲突的实现")))
    m["E1025"] = ErrorMeta(code: "E1025", category: ErrorCategory.Sema, severity: Severity.Warning,
        template: "检测到不安全的逃逸（escape）", fix: Some(FixSuggestion(description: "审查逃逸点安全性")))
    m["E1026"] = ErrorMeta(code: "E1026", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "trait 实现缺少方法：{name}", fix: Some(FixSuggestion(description: "补全缺失的 trait 方法")))
    m["E1027"] = ErrorMeta(code: "E1027", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "闭包捕获了不可捕获的变量：{name}", fix: Some(FixSuggestion(description: "改为值拷贝或调整捕获方式")))
    m["E1028"] = ErrorMeta(code: "E1028", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "没有匹配的重载：{name}", fix: Some(FixSuggestion(description: "检查实参类型或补充重载")))
    m["E1029"] = ErrorMeta(code: "E1029", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "命名/默认实参不匹配：{name}", fix: Some(FixSuggestion(description: "核对形参与默认实参名")))
    m["E1030"] = ErrorMeta(code: "E1030", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "可变性传播冲突：{name}", fix: Some(FixSuggestion(description: "统一可变性标注")))
    m["E1031"] = ErrorMeta(code: "E1031", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "非法的异步上下文（await/suspend 位置错误）", fix: Some(FixSuggestion(description: "将 await 移入异步函数")))
    m["E1032"] = ErrorMeta(code: "E1032", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "递归初始化循环：{name}", fix: Some(FixSuggestion(description: "拆分初始化依赖")))
    // ---------------- Type 类型系统（E20xx） ----------------
    m["E2001"] = ErrorMeta(code: "E2001", category: ErrorCategory.Type, severity: Severity.Error,
        template: "类型不匹配：期望 {expected}，实际 {actual}", fix: Some(FixSuggestion(description: "强制转换或修正变量类型")),
        notes: ArrayList<DiagnosticNote>([DiagnosticNote(message: "期望类型的来源位置", spanRole: "expectedHere"), DiagnosticNote(message: "实际表达式的位置", spanRole: "actualHere")]),
        primarySpanRole: "actualHere")
    m["E2002"] = ErrorMeta(code: "E2002", category: ErrorCategory.Type, severity: Severity.Error,
        template: "无法推断类型：{name}", fix: Some(FixSuggestion(description: "显式标注类型")))
    m["E2003"] = ErrorMeta(code: "E2003", category: ErrorCategory.Type, severity: Severity.Error,
        template: "非法类型转换：{from} → {to}", fix: Some(FixSuggestion(description: "检查转换兼容性")))
    m["E2004"] = ErrorMeta(code: "E2004", category: ErrorCategory.Type, severity: Severity.Error,
        template: "重载调用歧义：{name}", fix: Some(FixSuggestion(description: "显式指定参数类型")))
    m["E2005"] = ErrorMeta(code: "E2005", category: ErrorCategory.Type, severity: Severity.Error,
        template: "缺少泛型实参：{name}", fix: Some(FixSuggestion(description: "补充类型参数")))
    m["E2006"] = ErrorMeta(code: "E2006", category: ErrorCategory.Type, severity: Severity.Error,
        template: "泛型约束不满足：{name}", fix: Some(FixSuggestion(description: "修正类型参数或放宽约束")))
    m["E2007"] = ErrorMeta(code: "E2007", category: ErrorCategory.Type, severity: Severity.Error,
        template: "递归类型别名无大小：{name}", fix: Some(FixSuggestion(description: "引入间接层（指针/盒类型）")))
    m["E2008"] = ErrorMeta(code: "E2008", category: ErrorCategory.Type, severity: Severity.Error,
        template: "栈上放置不定长类型：{name}", fix: Some(FixSuggestion(description: "改用指针或动态分配")))
    m["E2009"] = ErrorMeta(code: "E2009", category: ErrorCategory.Type, severity: Severity.Warning,
        template: "隐式转换可能丢失精度：{from} → {to}", fix: Some(FixSuggestion(description: "显式转换并确认")))
    m["E2010"] = ErrorMeta(code: "E2010", category: ErrorCategory.Type, severity: Severity.Error,
        template: "型变不兼容（协变/逆变）：{name}", fix: Some(FixSuggestion(description: "修正泛型声明")))
    m["E2011"] = ErrorMeta(code: "E2011", category: ErrorCategory.Type, severity: Severity.Error,
        template: "型变标注位置非法：{name}", fix: Some(FixSuggestion(description: "在允许的协变/逆变位置标注")))
    m["E2012"] = ErrorMeta(code: "E2012", category: ErrorCategory.Type, severity: Severity.Error,
        template: "where 约束不满足：{name}", fix: Some(FixSuggestion(description: "修正类型参数以满足约束")))
    m["E2013"] = ErrorMeta(code: "E2013", category: ErrorCategory.Type, severity: Severity.Error,
        template: "闭包类型不匹配：期望 {expected}，实际 {actual}", fix: Some(FixSuggestion(description: "调整闭包签名")))
    m["E2014"] = ErrorMeta(code: "E2014", category: ErrorCategory.Type, severity: Severity.Error,
        template: "借用冲突：{name}", fix: Some(FixSuggestion(description: "调整可变/不可变借用范围")))
    m["E2015"] = ErrorMeta(code: "E2015", category: ErrorCategory.Type, severity: Severity.Error,
        template: "类型推断出现循环", fix: Some(FixSuggestion(description: "为变量显式标注类型")))
    m["E2016"] = ErrorMeta(code: "E2016", category: ErrorCategory.Type, severity: Severity.Error,
        template: "协变返回类型不兼容：{name}", fix: Some(FixSuggestion(description: "调整返回类型以支持协变")))
    m["E2017"] = ErrorMeta(code: "E2017", category: ErrorCategory.Type, severity: Severity.Error,
        template: "枚举不含任何成员：{name}", fix: Some(FixSuggestion(description: "添加枚举变体或改用 unit")))
    m["E2018"] = ErrorMeta(code: "E2018", category: ErrorCategory.Type, severity: Severity.Error,
        template: "不安全的 trait 向上转换：{name}", fix: Some(FixSuggestion(description: "使用受检转换或 as?")))
    m["E2019"] = ErrorMeta(code: "E2019", category: ErrorCategory.Type, severity: Severity.Error,
        template: "泛型实参与约束数量不匹配：{name}", fix: Some(FixSuggestion(description: "补上缺失的泛型实参")))
    m["E2020"] = ErrorMeta(code: "E2020", category: ErrorCategory.Type, severity: Severity.Error,
        template: "接口存在循环继承：{name}", fix: Some(FixSuggestion(description: "打断循环继承关系")))
    m["E2021"] = ErrorMeta(code: "E2021", category: ErrorCategory.Type, severity: Severity.Error,
        template: "返回类型与声明不兼容：{expected}", fix: Some(FixSuggestion(description: "修正返回表达式或返回类型")))
    m["E2022"] = ErrorMeta(code: "E2022", category: ErrorCategory.Type, severity: Severity.Error,
        template: "关联类型无法解析：{name}", fix: Some(FixSuggestion(description: "提供关联类型绑定")))
    m["E2023"] = ErrorMeta(code: "E2023", category: ErrorCategory.Type, severity: Severity.Error,
        template: "self 类型在当前上下文中非法", fix: Some(FixSuggestion(description: "仅在允许的位置使用 self")))
    m["E2024"] = ErrorMeta(code: "E2024", category: ErrorCategory.Type, severity: Severity.Error,
        template: "高阶量化边界（HRTB）不满足", fix: Some(FixSuggestion(description: "调整生命周期/类型边界")))
    m["E2025"] = ErrorMeta(code: "E2025", category: ErrorCategory.Type, severity: Severity.Warning,
        template: "幽灵类型(phantom)参数不匹配", fix: Some(FixSuggestion(description: "统一 phantom 类型实参")))
    m["E2026"] = ErrorMeta(code: "E2026", category: ErrorCategory.Type, severity: Severity.Error,
        template: "编译期常量求值失败：{name}", fix: Some(FixSuggestion(description: "简化常量表达式")))
    m["E2027"] = ErrorMeta(code: "E2027", category: ErrorCategory.Type, severity: Severity.Error,
        template: "编译期常量溢出：{name}", fix: Some(FixSuggestion(description: "降低常量值或改用更大类型")))
    m["E2028"] = ErrorMeta(code: "E2028", category: ErrorCategory.Type, severity: Severity.Error,
        template: "对可空类型直接解包而未判空：{name}", fix: Some(FixSuggestion(description: "先判空再解包")))
    m["E2029"] = ErrorMeta(code: "E2029", category: ErrorCategory.Type, severity: Severity.Error,
        template: "元组/数组元素类型不匹配：{expected}", fix: Some(FixSuggestion(description: "统一元素类型")))
    m["E2030"] = ErrorMeta(code: "E2030", category: ErrorCategory.Type, severity: Severity.Error,
        template: "函数指针类型不兼容：{name}", fix: Some(FixSuggestion(description: "核对签名与返回类型")))
    m["E2031"] = ErrorMeta(code: "E2031", category: ErrorCategory.Type, severity: Severity.Error,
        template: "字面量类型歧义：{name}", fix: Some(FixSuggestion(description: "显式标注字面量类型")))
    // ---------------- Resolution 名称解析（E30xx） ----------------
    m["E3001"] = ErrorMeta(code: "E3001", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "模块未找到：{name}", fix: Some(FixSuggestion(description: "检查模块路径或依赖配置")))
    m["E3002"] = ErrorMeta(code: "E3002", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "导入项不存在：{name}", fix: Some(FixSuggestion(description: "修正导入名称")))
    m["E3003"] = ErrorMeta(code: "E3003", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "导入名称冲突：{name}", fix: Some(FixSuggestion(description: "使用全限定名或别名")))
    m["E3004"] = ErrorMeta(code: "E3004", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "访问私有成员：{name}", fix: Some(FixSuggestion(description: "调整可见性或提供访问接口")),
        notes: ArrayList<DiagnosticNote>([DiagnosticNote(message: "该成员在此处声明为私有", spanRole: "declaredHere")]),
        primarySpanRole: "useSite")
    m["E3005"] = ErrorMeta(code: "E3005", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "路径无法解析：{path}", fix: Some(FixSuggestion(description: "检查模块层级")))
    m["E3006"] = ErrorMeta(code: "E3006", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "循环导入", fix: Some(FixSuggestion(description: "重构依赖关系")))
    m["E3007"] = ErrorMeta(code: "E3007", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "未实现必需的接口/特征：{name}", fix: Some(FixSuggestion(description: "补全方法实现")))
    m["E3008"] = ErrorMeta(code: "E3008", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "super 调用非法", fix: Some(FixSuggestion(description: "检查继承关系")))
    m["E3009"] = ErrorMeta(code: "E3009", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "顶层名称冲突：{name}", fix: Some(FixSuggestion(description: "重命名或使用命名空间")))
    m["E3010"] = ErrorMeta(code: "E3010", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "依赖版本不兼容：{name}", fix: Some(FixSuggestion(description: "升级或降级依赖版本")))
    m["E3011"] = ErrorMeta(code: "E3011", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "宏展开失败：{name}", fix: Some(FixSuggestion(description: "检查宏定义与参数")))
    m["E3012"] = ErrorMeta(code: "E3012", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "类型别名解析循环：{name}", fix: Some(FixSuggestion(description: "打断循环引用")))
    m["E3013"] = ErrorMeta(code: "E3013", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "导出符号缺失：{name}", fix: Some(FixSuggestion(description: "在源模块中导出该符号")))
    m["E3014"] = ErrorMeta(code: "E3014", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "传递可见性违规：{name}", fix: Some(FixSuggestion(description: "放宽中间符号可见性")))
    m["E3015"] = ErrorMeta(code: "E3015", category: ErrorCategory.Resolution, severity: Severity.Warning,
        template: "条件编译分支未覆盖：{key}", fix: Some(FixSuggestion(description: "补充缺失的编译条件分支")))
    m["E3016"] = ErrorMeta(code: "E3016", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "宏导入路径不存在：{path}", fix: Some(FixSuggestion(description: "检查宏模块路径")))
    m["E3017"] = ErrorMeta(code: "E3017", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "重导出符号冲突：{name}", fix: Some(FixSuggestion(description: "使用别名消除冲突")))
    m["E3018"] = ErrorMeta(code: "E3018", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "包初始化存在循环依赖", fix: Some(FixSuggestion(description: "重构初始化顺序")))
    m["E3019"] = ErrorMeta(code: "E3019", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "条件编译符号未定义：{key}", fix: Some(FixSuggestion(description: "定义该编译符号或条件编译")))
    m["E3020"] = ErrorMeta(code: "E3020", category: ErrorCategory.Resolution, severity: Severity.Warning,
        template: "可见性提升可能导致 API 破坏：{name}", fix: Some(FixSuggestion(description: "收紧可见性或显式导出")))
    m["E3021"] = ErrorMeta(code: "E3021", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "导入别名冲突：{name}", fix: Some(FixSuggestion(description: "重命名导入别名")))
    m["E3022"] = ErrorMeta(code: "E3022", category: ErrorCategory.Resolution, severity: Severity.Warning,
        template: "调用了不稳定的 API（需显式启用）", fix: Some(FixSuggestion(description: "启用对应的不稳定特性开关")))
    m["E3023"] = ErrorMeta(code: "E3023", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "缺少启用该能力所需的特性标志", fix: Some(FixSuggestion(description: "在配置中开启对应 feature")))
    m["E3024"] = ErrorMeta(code: "E3024", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "符号优先级解析冲突", fix: Some(FixSuggestion(description: "使用显式限定消除歧义")))
    m["E3025"] = ErrorMeta(code: "E3025", category: ErrorCategory.Resolution, severity: Severity.Warning,
        template: "孤立的实现(impl)未被任何 trait 引用", fix: None)
    m["E3026"] = ErrorMeta(code: "E3026", category: ErrorCategory.Resolution, severity: Severity.Warning,
        template: "通配导入（*）引入的名称存在歧义：{name}", fix: Some(FixSuggestion(description: "改为显式导入")))
    m["E3027"] = ErrorMeta(code: "E3027", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "宏卫生性冲突：{name}", fix: Some(FixSuggestion(description: "重命名宏内标识符")))
    m["E3028"] = ErrorMeta(code: "E3028", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "可见性层级违规（pub/包内/内部）：{name}", fix: Some(FixSuggestion(description: "调整可见性标注")))
    m["E3029"] = ErrorMeta(code: "E3029", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "trait 方法解析顺序冲突：{name}", fix: Some(FixSuggestion(description: "使用显式限定调用")))
    m["E3030"] = ErrorMeta(code: "E3030", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "条件编译 cfg 表达式求值错误：{key}", fix: Some(FixSuggestion(description: "检查 cfg 布尔组合")))
    // ---------------- Codegen 代码生成（E40xx） ----------------
}

/// 填充错误码元数据第 2 组（Codegen .. Trait），共 5 个类别。
func buildMetaPart2(m: HashMap<String, ErrorMeta>) {
    m["E4001"] = ErrorMeta(code: "E4001", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "不支持的语言结构：{construct}", fix: Some(FixSuggestion(description: "改写为支持的写法")))
    m["E4002"] = ErrorMeta(code: "E4002", category: ErrorCategory.Codegen, severity: Severity.Warning,
        template: "检测到栈溢出风险", fix: Some(FixSuggestion(description: "改为迭代或增加栈大小")))
    m["E4003"] = ErrorMeta(code: "E4003", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "内部函数调用非法：{name}", fix: Some(FixSuggestion(description: "检查内置函数参数")))
    m["E4004"] = ErrorMeta(code: "E4004", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "链接符号冲突：{name}", fix: Some(FixSuggestion(description: "检查重复定义或 extern 声明")))
    m["E4005"] = ErrorMeta(code: "E4005", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "ABI 不兼容", fix: Some(FixSuggestion(description: "对齐调用约定")))
    m["E4006"] = ErrorMeta(code: "E4006", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "优化阶段内部失败", fix: Some(FixSuggestion(description: "降低优化级别后重试")))
    m["E4007"] = ErrorMeta(code: "E4007", category: ErrorCategory.Codegen, severity: Severity.Warning,
        template: "未初始化使用：{name}", fix: Some(FixSuggestion(description: "显式初始化")))
    m["E4008"] = ErrorMeta(code: "E4008", category: ErrorCategory.Codegen, severity: Severity.Warning,
        template: "常量过大超出目标限制：{name}", fix: Some(FixSuggestion(description: "拆分常量或动态加载")))
    m["E4009"] = ErrorMeta(code: "E4009", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "目标平台不支持：{target}", fix: Some(FixSuggestion(description: "切换目标或使用条件编译")))
    m["E4010"] = ErrorMeta(code: "E4010", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "代码发射被中断", fix: Some(FixSuggestion(description: "检查磁盘空间或权限")))
    m["E4011"] = ErrorMeta(code: "E4011", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "寄存器分配失败", fix: Some(FixSuggestion(description: "减少局部变量或降低优化级别")))
    m["E4012"] = ErrorMeta(code: "E4012", category: ErrorCategory.Codegen, severity: Severity.Warning,
        template: "不支持的尾调用", fix: Some(FixSuggestion(description: "改写为显式循环")))
    m["E4013"] = ErrorMeta(code: "E4013", category: ErrorCategory.Codegen, severity: Severity.Warning,
        template: "内联失败：{name}", fix: Some(FixSuggestion(description: "放宽内联约束")))
    m["E4014"] = ErrorMeta(code: "E4014", category: ErrorCategory.Codegen, severity: Severity.Warning,
        template: "常量折叠溢出：{name}", fix: Some(FixSuggestion(description: "改用更大类型或动态计算")))
    m["E4015"] = ErrorMeta(code: "E4015", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "目标特性不支持该指令：{feature}", fix: Some(FixSuggestion(description: "启用对应目标特性或条件编译")))
    m["E4016"] = ErrorMeta(code: "E4016", category: ErrorCategory.Codegen, severity: Severity.Warning,
        template: "检测到不可达代码块（优化后）", fix: Some(FixSuggestion(description: "删除死代码")))
    m["E4017"] = ErrorMeta(code: "E4017", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "虚表布局溢出：{name}", fix: Some(FixSuggestion(description: "拆分类型或扁平化继承")))
    m["E4018"] = ErrorMeta(code: "E4018", category: ErrorCategory.Codegen, severity: Severity.Warning,
        template: "异常处理表过大", fix: Some(FixSuggestion(description: "减少嵌套异常或拆分函数")))
    m["E4019"] = ErrorMeta(code: "E4019", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "不支持的内联汇编语法", fix: Some(FixSuggestion(description: "使用受支持的汇编方言")))
    m["E4020"] = ErrorMeta(code: "E4020", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "目标架构不支持该对齐指令：{align}", fix: Some(FixSuggestion(description: "改用软件对齐或条件编译")))
    m["E4021"] = ErrorMeta(code: "E4021", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "目标平台不支持该 SIMD 指令", fix: None)
    m["E4022"] = ErrorMeta(code: "E4022", category: ErrorCategory.Codegen, severity: Severity.Warning,
        template: "调试信息生成失败", fix: None)
    m["E4023"] = ErrorMeta(code: "E4023", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "目标段(section)超出平台大小限制", fix: None)
    m["E4024"] = ErrorMeta(code: "E4024", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "不支持的重定位类型", fix: None)
    m["E4025"] = ErrorMeta(code: "E4025", category: ErrorCategory.Codegen, severity: Severity.Warning,
        template: "性能采样插桩失败", fix: None)
    m["E4026"] = ErrorMeta(code: "E4026", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "泛型单态化失败：{name}", fix: Some(FixSuggestion(description: "检查泛型实参是否可实例化")))
    m["E4027"] = ErrorMeta(code: "E4027", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "链接器执行失败：{message}", fix: Some(FixSuggestion(description: "检查库路径与链接参数")))
    m["E4028"] = ErrorMeta(code: "E4028", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "内建函数（builtin）在当前目标不支持：{name}", fix: Some(FixSuggestion(description: "改用目标支持的等价实现")))
    m["E4029"] = ErrorMeta(code: "E4029", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "调用约定不匹配：{name}", fix: Some(FixSuggestion(description: "统一调用约定标注")))
    m["E4030"] = ErrorMeta(code: "E4030", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "线程局部存储（TLS）在该目标不支持：{name}", fix: Some(FixSuggestion(description: "改用非 TLS 方案")))
    m["E4031"] = ErrorMeta(code: "E4031", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "FFI 调用签名与 C ABI 不匹配：{name}", fix: Some(FixSuggestion(description: "核对 C 侧签名")))
    m["E4032"] = ErrorMeta(code: "E4032", category: ErrorCategory.Codegen, severity: Severity.Error,
        template: "目标 triple 无效或无法识别：{target}", fix: Some(FixSuggestion(description: "检查目标三元组拼写")))
    m["E4033"] = ErrorMeta(code: "E4033", category: ErrorCategory.Codegen, severity: Severity.Warning,
        template: "调试信息格式（DWARF）生成异常：{name}", fix: None)
    // ---------------- Runtime 运行时（E50xx） ----------------
    m["E5001"] = ErrorMeta(code: "E5001", category: ErrorCategory.Runtime, severity: Severity.Fatal,
        template: "空指针解引用", fix: Some(FixSuggestion(description: "增加空值检查")),
        notes: ArrayList<DiagnosticNote>([DiagnosticNote(message: "可能为 null 的赋值位置", spanRole: "nullAssignedHere")]),
        primarySpanRole: "derefSite")
    m["E5002"] = ErrorMeta(code: "E5002", category: ErrorCategory.Runtime, severity: Severity.Fatal,
        template: "数组越界：索引 {index}", fix: Some(FixSuggestion(description: "检查索引范围")))
    m["E5003"] = ErrorMeta(code: "E5003", category: ErrorCategory.Runtime, severity: Severity.Fatal,
        template: "除零错误", fix: Some(FixSuggestion(description: "增加除数检查")))
    m["E5004"] = ErrorMeta(code: "E5004", category: ErrorCategory.Runtime, severity: Severity.Fatal,
        template: "运行时栈溢出", fix: Some(FixSuggestion(description: "改为迭代或优化递归")))
    m["E5005"] = ErrorMeta(code: "E5005", category: ErrorCategory.Runtime, severity: Severity.Error,
        template: "整数溢出：{name}", fix: Some(FixSuggestion(description: "使用溢出检查或更大的整数类型")))
    m["E5006"] = ErrorMeta(code: "E5006", category: ErrorCategory.Runtime, severity: Severity.Error,
        template: "运行时类型转换失败：{name}", fix: Some(FixSuggestion(description: "增加类型判断")))
    m["E5007"] = ErrorMeta(code: "E5007", category: ErrorCategory.Runtime, severity: Severity.Error,
        template: "资源耗尽（内存/句柄）", fix: Some(FixSuggestion(description: "释放资源或增加配额")))
    m["E5008"] = ErrorMeta(code: "E5008", category: ErrorCategory.Runtime, severity: Severity.Error,
        template: "检测到死锁", fix: Some(FixSuggestion(description: "调整锁顺序或设置超时")))
    m["E5009"] = ErrorMeta(code: "E5009", category: ErrorCategory.Runtime, severity: Severity.Error,
        template: "断言失败：{message}", fix: Some(FixSuggestion(description: "检查不变量是否成立")))
    m["E5010"] = ErrorMeta(code: "E5010", category: ErrorCategory.Runtime, severity: Severity.Fatal,
        template: "异常展开被中止", fix: Some(FixSuggestion(description: "检查析构函数中的异常")))
    m["E5011"] = ErrorMeta(code: "E5011", category: ErrorCategory.Runtime, severity: Severity.Error,
        template: "移动后使用：{name}", fix: Some(FixSuggestion(description: "在移动前复制或重新获取所有权")))
    m["E5012"] = ErrorMeta(code: "E5012", category: ErrorCategory.Runtime, severity: Severity.Error,
        template: "检测到数据竞争：{name}", fix: Some(FixSuggestion(description: "使用同步原语保护共享状态")))
    m["E5013"] = ErrorMeta(code: "E5013", category: ErrorCategory.Runtime, severity: Severity.Error,
        template: "缓冲区溢出：{name}", fix: Some(FixSuggestion(description: "检查边界与长度")))
    m["E5014"] = ErrorMeta(code: "E5014", category: ErrorCategory.Runtime, severity: Severity.Fatal,
        template: "检测到无限递归", fix: Some(FixSuggestion(description: "添加终止条件")))
    m["E5015"] = ErrorMeta(code: "E5015", category: ErrorCategory.Runtime, severity: Severity.Error,
        template: "平台调用（FFI）失败：{name}", fix: Some(FixSuggestion(description: "检查原生函数签名与参数")))
    m["E5016"] = ErrorMeta(code: "E5016", category: ErrorCategory.Runtime, severity: Severity.Fatal,
        template: "析构函数中抛出异常", fix: None)
    m["E5017"] = ErrorMeta(code: "E5017", category: ErrorCategory.Runtime, severity: Severity.Error,
        template: "访问已失效的弱引用：{name}", fix: Some(FixSuggestion(description: "在使用前检查并重新获取")))
    m["E5018"] = ErrorMeta(code: "E5018", category: ErrorCategory.Runtime, severity: Severity.Error,
        template: "数组负索引：{index}", fix: Some(FixSuggestion(description: "检查索引非负")))
    m["E5019"] = ErrorMeta(code: "E5019", category: ErrorCategory.Runtime, severity: Severity.Error,
        template: "非法的协程挂起点", fix: Some(FixSuggestion(description: "仅在 suspend 上下文调用")))
    m["E5020"] = ErrorMeta(code: "E5020", category: ErrorCategory.Runtime, severity: Severity.Fatal,
        template: "内存对齐错误", fix: None)
    m["E5021"] = ErrorMeta(code: "E5021", category: ErrorCategory.Runtime, severity: Severity.Warning,
        template: "资源未被释放（可能泄漏）", fix: None)
    m["E5022"] = ErrorMeta(code: "E5022", category: ErrorCategory.Runtime, severity: Severity.Error,
        template: "运行时契约(contract)被破坏", fix: None)
    m["E5023"] = ErrorMeta(code: "E5023", category: ErrorCategory.Runtime, severity: Severity.Error,
        template: "操作超过运行时时限", fix: None)
    m["E5024"] = ErrorMeta(code: "E5024", category: ErrorCategory.Runtime, severity: Severity.Fatal,
        template: "检测到栈内存损坏", fix: None)
    m["E5025"] = ErrorMeta(code: "E5025", category: ErrorCategory.Runtime, severity: Severity.Fatal,
        template: "未知运行时错误（兜底）", fix: None)
    m["E5026"] = ErrorMeta(code: "E5026", category: ErrorCategory.Runtime, severity: Severity.Fatal,
        template: "检测到重复释放（double free）：{name}", fix: None)
    m["E5027"] = ErrorMeta(code: "E5027", category: ErrorCategory.Runtime, severity: Severity.Fatal,
        template: "释放后使用（use-after-free）：{name}", fix: None)
    m["E5028"] = ErrorMeta(code: "E5028", category: ErrorCategory.Runtime, severity: Severity.Error,
        template: "向已关闭的信道/actor 发送消息：{name}", fix: Some(FixSuggestion(description: "发送前检查信道状态")))
    m["E5029"] = ErrorMeta(code: "E5029", category: ErrorCategory.Runtime, severity: Severity.Error,
        template: "原子操作误用（非原子访问/内存序错误）：{name}", fix: Some(FixSuggestion(description: "统一使用原子操作")))
    m["E5030"] = ErrorMeta(code: "E5030", category: ErrorCategory.Runtime, severity: Severity.Error,
        template: "线程/协程数量超过上限：{name}", fix: Some(FixSuggestion(description: "复用线程池或降低并发")))
    m["E5031"] = ErrorMeta(code: "E5031", category: ErrorCategory.Runtime, severity: Severity.Error,
        template: "内存映射（mmap）失败：{name}", fix: Some(FixSuggestion(description: "检查映射大小与权限")))
    // ---------------- System 系统/内部（E90xx） ----------------
    m["E9001"] = ErrorMeta(code: "E9001", category: ErrorCategory.System, severity: Severity.Fatal,
        template: "编译器内部错误（ICE）", fix: None)
    m["E9002"] = ErrorMeta(code: "E9002", category: ErrorCategory.System, severity: Severity.Error,
        template: "文件读写失败：{path}", fix: Some(FixSuggestion(description: "检查路径/权限/磁盘空间")))
    m["E9003"] = ErrorMeta(code: "E9003", category: ErrorCategory.System, severity: Severity.Fatal,
        template: "编译器内存不足", fix: None)
    m["E9004"] = ErrorMeta(code: "E9004", category: ErrorCategory.System, severity: Severity.Error,
        template: "编译超时", fix: Some(FixSuggestion(description: "简化代码或增加超时阈值")))
    m["E9005"] = ErrorMeta(code: "E9005", category: ErrorCategory.System, severity: Severity.Error,
        template: "配置参数非法：{key}", fix: Some(FixSuggestion(description: "修正编译配置")))
    m["E9006"] = ErrorMeta(code: "E9006", category: ErrorCategory.System, severity: Severity.Error,
        template: "插件加载失败：{name}", fix: Some(FixSuggestion(description: "检查插件版本与依赖")))
    m["E9007"] = ErrorMeta(code: "E9007", category: ErrorCategory.System, severity: Severity.Error,
        template: "缓存损坏", fix: Some(FixSuggestion(description: "清理缓存后重试")))
    m["E9008"] = ErrorMeta(code: "E9008", category: ErrorCategory.System, severity: Severity.Error,
        template: "网络操作失败：{message}", fix: Some(FixSuggestion(description: "检查网络或镜像源")))
    m["E9009"] = ErrorMeta(code: "E9009", category: ErrorCategory.System, severity: Severity.Error,
        template: "权限不足：{path}", fix: Some(FixSuggestion(description: "调整文件权限")))
    m["E9010"] = ErrorMeta(code: "E9010", category: ErrorCategory.System, severity: Severity.Fatal,
        template: "未分类系统错误", fix: None)
    m["E9011"] = ErrorMeta(code: "E9011", category: ErrorCategory.System, severity: Severity.Error,
        template: "并发编译数超过限制", fix: Some(FixSuggestion(description: "降低并行任务数")))
    m["E9012"] = ErrorMeta(code: "E9012", category: ErrorCategory.System, severity: Severity.Error,
        template: "诊断序列化失败", fix: Some(FixSuggestion(description: "检查输出通道权限")))
    m["E9013"] = ErrorMeta(code: "E9013", category: ErrorCategory.System, severity: Severity.Error,
        template: "编译器版本不兼容：{version}", fix: Some(FixSuggestion(description: "升级或锁定兼容版本")))
    m["E9014"] = ErrorMeta(code: "E9014", category: ErrorCategory.System, severity: Severity.Error,
        template: "缺少环境变量：{key}", fix: Some(FixSuggestion(description: "设置所需环境变量")))
    m["E9015"] = ErrorMeta(code: "E9015", category: ErrorCategory.System, severity: Severity.Fatal,
        template: "编译器内部断言失败", fix: None)
    m["E9016"] = ErrorMeta(code: "E9016", category: ErrorCategory.System, severity: Severity.Error,
        template: "临时目录不可写：{path}", fix: Some(FixSuggestion(description: "检查目录权限")))
    m["E9017"] = ErrorMeta(code: "E9017", category: ErrorCategory.System, severity: Severity.Error,
        template: "诊断输出通道被占用", fix: Some(FixSuggestion(description: "关闭占用进程或重试")))
    m["E9018"] = ErrorMeta(code: "E9018", category: ErrorCategory.System, severity: Severity.Error,
        template: "编译器插件版本不匹配：{name}", fix: Some(FixSuggestion(description: "升级或锁定兼容插件版本")))
    m["E9019"] = ErrorMeta(code: "E9019", category: ErrorCategory.System, severity: Severity.Fatal,
        template: "中断信号导致编译中止", fix: None)
    m["E9020"] = ErrorMeta(code: "E9020", category: ErrorCategory.System, severity: Severity.Fatal,
        template: "未知内部错误（兜底）", fix: None)
    m["E9021"] = ErrorMeta(code: "E9021", category: ErrorCategory.System, severity: Severity.Error,
        template: "系统资源达到上限", fix: None)
    m["E9022"] = ErrorMeta(code: "E9022", category: ErrorCategory.System, severity: Severity.Error,
        template: "当前平台/配置不支持该特性", fix: None)
    m["E9023"] = ErrorMeta(code: "E9023", category: ErrorCategory.System, severity: Severity.Fatal,
        template: "收到致命信号（如 SIGSEGV）", fix: None)
    m["E9024"] = ErrorMeta(code: "E9024", category: ErrorCategory.System, severity: Severity.Fatal,
        template: "进入不可恢复的内部状态", fix: None)
    m["E9025"] = ErrorMeta(code: "E9025", category: ErrorCategory.System, severity: Severity.Warning,
        template: "已请求关闭（正常退出路径）", fix: None)
    m["E9026"] = ErrorMeta(code: "E9026", category: ErrorCategory.System, severity: Severity.Warning,
        template: "增量编译缓存失效，已回退全量编译", fix: None)
    m["E9027"] = ErrorMeta(code: "E9027", category: ErrorCategory.System, severity: Severity.Error,
        template: "远程/分布式编译失败：{message}", fix: Some(FixSuggestion(description: "检查远程节点与网络")))
    m["E9028"] = ErrorMeta(code: "E9028", category: ErrorCategory.System, severity: Severity.Error,
        template: "沙箱/容器资源限制触发：{name}", fix: Some(FixSuggestion(description: "放宽容器资源配额")))
    m["E0201"] = ErrorMeta(code: "E0201", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "宏展开时标识符未定义：{name}", fix: Some(FixSuggestion(description: "检查宏参数与导入")))
    m["E0202"] = ErrorMeta(code: "E0202", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "宏实参数量不匹配：期望 {expected} 个，得到 {got} 个", fix: Some(FixSuggestion(description: "核对宏调用实参")))
    m["E0203"] = ErrorMeta(code: "E0203", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "宏递归展开未终止（可能的无限展开）", fix: Some(FixSuggestion(description: "为宏增加展开边界条件")))
    m["E0204"] = ErrorMeta(code: "E0204", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "宏卫生性冲突：捕获了调用方的标识符 {name}", fix: Some(FixSuggestion(description: "重命名宏内绑定")))
    m["E0205"] = ErrorMeta(code: "E0205", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "宏输入不是合法的 token 树", fix: Some(FixSuggestion(description: "检查宏输入语法")))
    m["E0206"] = ErrorMeta(code: "E0206", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "未找到宏定义：{name}", fix: Some(FixSuggestion(description: "导入或定义该宏")))
    m["E0207"] = ErrorMeta(code: "E0207", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "宏 {name} 被重复定义", fix: Some(FixSuggestion(description: "删除重复定义")))
    m["E0208"] = ErrorMeta(code: "E0208", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "宏片段类型不匹配（expr/stmt/ty/item）", fix: Some(FixSuggestion(description: "使用正确的片段说明符")))
    m["E0209"] = ErrorMeta(code: "E0209", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "同一元变量在宏规则中被重复绑定：{name}", fix: Some(FixSuggestion(description: "重命名元变量")))
    m["E0210"] = ErrorMeta(code: "E0210", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "没有任何宏规则匹配输入", fix: Some(FixSuggestion(description: "调整输入或新增宏规则")))
    m["E0211"] = ErrorMeta(code: "E0211", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "宏使用了保留的元变量名：{name}", fix: Some(FixSuggestion(description: "改用非保留名")))
    m["E0212"] = ErrorMeta(code: "E0212", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "宏内出现上下文关键字误用：{kw}", fix: Some(FixSuggestion(description: "检查关键字上下文")))
    m["E0213"] = ErrorMeta(code: "E0213", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "宏展开深度超过上限（{limit}）", fix: Some(FixSuggestion(description: "简化嵌套宏调用")))
    m["E0214"] = ErrorMeta(code: "E0214", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "属性宏参数格式非法", fix: Some(FixSuggestion(description: "检查属性宏参数")))
    m["E0215"] = ErrorMeta(code: "E0215", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "derive 宏生成代码与手写代码冲突：{trait}", fix: Some(FixSuggestion(description: "移除冲突实现")))
    m["E0216"] = ErrorMeta(code: "E0216", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "过程宏执行异常终止", fix: Some(FixSuggestion(description: "修复过程宏实现")))
    m["E0217"] = ErrorMeta(code: "E0217", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "过程宏执行超时", fix: Some(FixSuggestion(description: "优化过程宏性能")))
    m["E0218"] = ErrorMeta(code: "E0218", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "过程宏访问文件系统失败", fix: Some(FixSuggestion(description: "避免过程宏做 IO")))
    m["E0219"] = ErrorMeta(code: "E0219", category: ErrorCategory.Macro, severity: Severity.Warning,
        template: "quote! 生成的代码丢失源码位置", fix: Some(FixSuggestion(description: "使用 span 传递")))
    m["E0220"] = ErrorMeta(code: "E0220", category: ErrorCategory.Macro, severity: Severity.Warning,
        template: "宏规则存在歧义，多处可匹配", fix: Some(FixSuggestion(description: "细化宏规则优先级")))
    m["E0221"] = ErrorMeta(code: "E0221", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "宏重复匹配为空但要求至少一次", fix: Some(FixSuggestion(description: "检查重复分隔符")))
    m["E0222"] = ErrorMeta(code: "E0222", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "宏重复分隔符不匹配：期望 {sep}", fix: Some(FixSuggestion(description: "使用正确分隔符")))
    m["E0223"] = ErrorMeta(code: "E0223", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "宏 token 树括号不平衡", fix: Some(FixSuggestion(description: "补全括号")))
    m["E0224"] = ErrorMeta(code: "E0224", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "宏片段引用的外部符号未解析：{name}", fix: Some(FixSuggestion(description: "导入对应符号")))
    m["E0225"] = ErrorMeta(code: "E0225", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "内建宏在当前目标不支持：{name}", fix: Some(FixSuggestion(description: "改用等价实现")))
    m["E0226"] = ErrorMeta(code: "E0226", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "在常量上下文使用非常量宏", fix: Some(FixSuggestion(description: "改用在运行时求值")))
    m["E0227"] = ErrorMeta(code: "E0227", category: ErrorCategory.Macro, severity: Severity.Warning,
        template: "cfg 宏分支全部被禁用，无可用分支", fix: Some(FixSuggestion(description: "检查 cfg 条件")))
    m["E0228"] = ErrorMeta(code: "E0228", category: ErrorCategory.Macro, severity: Severity.Warning,
        template: "文档宏（如 html_root_url）参数非法", fix: Some(FixSuggestion(description: "修正文档宏参数")))
    m["E0229"] = ErrorMeta(code: "E0229", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "format! 宏格式串解析失败：{spec}", fix: Some(FixSuggestion(description: "检查占位符与参数")))
    m["E0230"] = ErrorMeta(code: "E0230", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "日志宏级别非法：{level}", fix: Some(FixSuggestion(description: "使用合法日志级别")))
    m["E0231"] = ErrorMeta(code: "E0231", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "assert! 宏消息参数类型非法", fix: Some(FixSuggestion(description: "消息须为字符串或格式化串")))
    m["E0232"] = ErrorMeta(code: "E0232", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "vec! 宏元素类型不一致", fix: Some(FixSuggestion(description: "统一元素类型")))
    m["E0233"] = ErrorMeta(code: "E0233", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "include! 宏读取文件失败：{path}", fix: Some(FixSuggestion(description: "检查文件路径与权限")))
    m["E0234"] = ErrorMeta(code: "E0234", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "concat! 宏拼接结果类型非法", fix: Some(FixSuggestion(description: "确保拼接为合法字面量")))
    m["E0235"] = ErrorMeta(code: "E0235", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "env! 宏读取的环境变量不存在：{var}", fix: Some(FixSuggestion(description: "设置环境变量")))
    m["E0236"] = ErrorMeta(code: "E0236", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "select! 宏分支模式冲突", fix: Some(FixSuggestion(description: "统一分支类型")))
    m["E0237"] = ErrorMeta(code: "E0237", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "宏定义本身递归引用自身", fix: Some(FixSuggestion(description: "断开宏定义循环")))
    m["E0238"] = ErrorMeta(code: "E0238", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "泛型宏参数未推导：{name}", fix: Some(FixSuggestion(description: "补充类型标注")))
    m["E0239"] = ErrorMeta(code: "E0239", category: ErrorCategory.Macro, severity: Severity.Error,
        template: "宏展开产生了不安全的代码但缺少 unsafe 块", fix: Some(FixSuggestion(description: "添加 unsafe 块")))
    m["E0240"] = ErrorMeta(code: "E0240", category: ErrorCategory.Macro, severity: Severity.Warning,
        template: "宏展开生成的源码跨度超过编译器限制", fix: Some(FixSuggestion(description: "拆分宏生成代码")))
    m["E0301"] = ErrorMeta(code: "E0301", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "trait {trait} 的方法 {method} 未实现", fix: Some(FixSuggestion(description: "补全缺失的 trait 方法")))
    m["E0302"] = ErrorMeta(code: "E0302", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "trait 方法 {method} 的实现签名不匹配", fix: Some(FixSuggestion(description: "对齐参数与返回类型")))
    m["E0303"] = ErrorMeta(code: "E0303", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "缺少父 trait {super} 的实现", fix: Some(FixSuggestion(description: "实现父 trait")))
    m["E0304"] = ErrorMeta(code: "E0304", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "为同一类型实现了冲突的 trait {trait}", fix: Some(FixSuggestion(description: "移除其中一个实现")))
    m["E0305"] = ErrorMeta(code: "E0305", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "实现违反了孤儿规则（类型与 trait 均非本地）", fix: Some(FixSuggestion(description: "将实现移到定义侧")))
    m["E0306"] = ErrorMeta(code: "E0306", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "否定实现与正向实现冲突：{trait}", fix: Some(FixSuggestion(description: "移除冲突实现")))
    m["E0307"] = ErrorMeta(code: "E0307", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "试图在 crate 外实现封闭 trait {trait}", fix: Some(FixSuggestion(description: "仅在 crate 内实现")))
    m["E0308"] = ErrorMeta(code: "E0308", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "trait {trait} 的关联类型 {assoc} 未指定", fix: Some(FixSuggestion(description: "提供关联类型")))
    m["E0309"] = ErrorMeta(code: "E0309", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "关联类型不满足 bound：{bound}", fix: Some(FixSuggestion(description: "调整关联类型约束")))
    m["E0310"] = ErrorMeta(code: "E0310", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "默认实现与具体实现冲突：{method}", fix: Some(FixSuggestion(description: "移除重复实现")))
    m["E0311"] = ErrorMeta(code: "E0311", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "标记 trait {trait} 不应有方法体", fix: Some(FixSuggestion(description: "改为纯标记 trait")))
    m["E0312"] = ErrorMeta(code: "E0312", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "trait {trait} 不是对象安全的，不能用于 dyn", fix: Some(FixSuggestion(description: "移除不安全的成员")))
    m["E0313"] = ErrorMeta(code: "E0313", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "泛型 trait 不能直接用于 dyn（需指定实参）", fix: Some(FixSuggestion(description: "提供泛型实参")))
    m["E0314"] = ErrorMeta(code: "E0314", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "类型 {ty} 不满足 trait bound {trait}", fix: Some(FixSuggestion(description: "为类型实现该 trait")))
    m["E0315"] = ErrorMeta(code: "E0315", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "高阶 trait bound 推导失败", fix: Some(FixSuggestion(description: "显式标注生命周期")))
    m["E0316"] = ErrorMeta(code: "E0316", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "trait 别名存在循环引用", fix: Some(FixSuggestion(description: "打破别名循环")))
    m["E0317"] = ErrorMeta(code: "E0317", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "不能对泛型 bound 参数直接 impl trait", fix: Some(FixSuggestion(description: "改用具体类型")))
    m["E0318"] = ErrorMeta(code: "E0318", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "特化实现冲突（更具体的实现未生效）", fix: Some(FixSuggestion(description: "检查特化层级")))
    m["E0319"] = ErrorMeta(code: "E0319", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "自动 trait {trait} 未能自动推导", fix: Some(FixSuggestion(description: "检查含非自动字段")))
    m["E0320"] = ErrorMeta(code: "E0320", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "自动 trait 推导与显式实现冲突", fix: Some(FixSuggestion(description: "统一实现策略")))
    m["E0321"] = ErrorMeta(code: "E0321", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "联动 trait（coherence）判定歧义", fix: Some(FixSuggestion(description: "明确实现归属")))
    m["E0322"] = ErrorMeta(code: "E0322", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "不安全 trait 实现缺少 unsafe 标注", fix: Some(FixSuggestion(description: "添加 unsafe 实现块")))
    m["E0323"] = ErrorMeta(code: "E0323", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "trait 方法可见性低于实现要求", fix: Some(FixSuggestion(description: "提升方法可见性")))
    m["E0324"] = ErrorMeta(code: "E0324", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "impl 块的 where 子句不满足", fix: Some(FixSuggestion(description: "补全 where 约束")))
    m["E0325"] = ErrorMeta(code: "E0325", category: ErrorCategory.Trait, severity: Severity.Error,
        template: " blanket 实现与其他实现冲突", fix: Some(FixSuggestion(description: "缩小 blanket 范围")))
    m["E0326"] = ErrorMeta(code: "E0326", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "trait 对象协变非法", fix: Some(FixSuggestion(description: "使用不变类型参数")))
    m["E0327"] = ErrorMeta(code: "E0327", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "关联类型投影失败：{assoc}", fix: Some(FixSuggestion(description: "检查类型投影路径")))
    m["E0328"] = ErrorMeta(code: "E0328", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "trait 方法含默认参数但不被支持", fix: Some(FixSuggestion(description: "改用重载或 option")))
    m["E0329"] = ErrorMeta(code: "E0329", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "当前不支持 async trait 方法 {method}", fix: Some(FixSuggestion(description: "改用返回 Future 的同步签名")))
    m["E0330"] = ErrorMeta(code: "E0330", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "trait 方法泛型与实现泛型冲突", fix: Some(FixSuggestion(description: "对齐泛型参数")))
    m["E0331"] = ErrorMeta(code: "E0331", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "关联常量 {name} 被重复定义", fix: Some(FixSuggestion(description: "删除重复定义")))
    m["E0332"] = ErrorMeta(code: "E0332", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "关联常量类型不匹配：期望 {expected}", fix: Some(FixSuggestion(description: "统一关联常量类型")))
    m["E0333"] = ErrorMeta(code: "E0333", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "按名取 trait 方法失败：{method}", fix: Some(FixSuggestion(description: "检查方法可见性")))
    m["E0334"] = ErrorMeta(code: "E0334", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "impl 的泛型参数数量不匹配", fix: Some(FixSuggestion(description: "核对泛型实参")))
    m["E0335"] = ErrorMeta(code: "E0335", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "trait 需求形成循环依赖", fix: Some(FixSuggestion(description: "打破循环依赖")))
    m["E0336"] = ErrorMeta(code: "E0336", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "trait 方法静态/动态分发解析失败", fix: Some(FixSuggestion(description: "显式指定分发方式")))
    m["E0337"] = ErrorMeta(code: "E0337", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "试图重写非虚 trait 方法", fix: Some(FixSuggestion(description: "使用 virtual 方法")))
    m["E0338"] = ErrorMeta(code: "E0338", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "晚绑定参数在 impl 中无法确定", fix: Some(FixSuggestion(description: "提供具体类型")))
    m["E0339"] = ErrorMeta(code: "E0339", category: ErrorCategory.Trait, severity: Severity.Warning,
        template: "trait 继承层级过深", fix: Some(FixSuggestion(description: "扁平化 trait 层级")))
    m["E0340"] = ErrorMeta(code: "E0340", category: ErrorCategory.Trait, severity: Severity.Error,
        template: "为 Self 类型实现自身 trait 冲突", fix: Some(FixSuggestion(description: "调整实现类型")))
}

/// 填充错误码元数据第 3 组（Borrow .. Backend），共 5 个类别。
func buildMetaPart3(m: HashMap<String, ErrorMeta>) {
    m["E0401"] = ErrorMeta(code: "E0401", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "从已借用的值中移动：{name}", fix: Some(FixSuggestion(description: "先结束借用再移动")))
    m["E0402"] = ErrorMeta(code: "E0402", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "在值被移动后继续借用：{name}", fix: Some(FixSuggestion(description: "调整借用顺序")))
    m["E0403"] = ErrorMeta(code: "E0403", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "存在可变借用时又产生其他借用", fix: Some(FixSuggestion(description: "确保同一时刻仅一种借用")))
    m["E0404"] = ErrorMeta(code: "E0404", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "存在多个可变别名借用", fix: Some(FixSuggestion(description: "使用单一可变引用")))
    m["E0405"] = ErrorMeta(code: "E0405", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "借用逃出其生命周期范围：{name}", fix: Some(FixSuggestion(description: "缩短借用或延长所有者")))
    m["E0406"] = ErrorMeta(code: "E0406", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "使用了已被移动的值：{name}", fix: Some(FixSuggestion(description: "在使用前克隆或避免移动")))
    m["E0407"] = ErrorMeta(code: "E0407", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "对结构体部分字段移动后整体不可用", fix: Some(FixSuggestion(description: "移动前完成所需访问")))
    m["E0408"] = ErrorMeta(code: "E0408", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "在 match guard 中移动值导致后续不可用", fix: Some(FixSuggestion(description: "改用引用匹配")))
    m["E0409"] = ErrorMeta(code: "E0409", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "闭包按值捕获了被借用的变量", fix: Some(FixSuggestion(description: "改用引用捕获")))
    m["E0410"] = ErrorMeta(code: "E0410", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "返回了对局部变量的引用", fix: Some(FixSuggestion(description: "返回拥有的值或延长生命周期")))
    m["E0411"] = ErrorMeta(code: "E0411", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "临时值生命周期不足：{name}", fix: Some(FixSuggestion(description: "绑定到具名变量")))
    m["E0412"] = ErrorMeta(code: "E0412", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "借用了已被移动的结构体字段", fix: Some(FixSuggestion(description: "避免部分移动")))
    m["E0413"] = ErrorMeta(code: "E0413", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "方法中对 self 同时发生可变与不可变借用", fix: Some(FixSuggestion(description: "拆分方法调用")))
    m["E0414"] = ErrorMeta(code: "E0414", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "重新借用失败：{name}", fix: Some(FixSuggestion(description: "调整借用来源")))
    m["E0415"] = ErrorMeta(code: "E0415", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "期望类型可 Copy 但实际未实现 Copy", fix: Some(FixSuggestion(description: "为类型实现 Copy 或改用引用")))
    m["E0416"] = ErrorMeta(code: "E0416", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "在借用期间显式 drop 导致悬垂", fix: Some(FixSuggestion(description: "结束借用后再 drop")))
    m["E0417"] = ErrorMeta(code: "E0417", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "match 臂中借用与移动冲突", fix: Some(FixSuggestion(description: "统一臂内使用方式")))
    m["E0418"] = ErrorMeta(code: "E0418", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "对同一值两次可变借用", fix: Some(FixSuggestion(description: "复用同一可变引用")))
    m["E0419"] = ErrorMeta(code: "E0419", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "由不可变借用派生了可变借用", fix: Some(FixSuggestion(description: "从源头使用可变借用")))
    m["E0420"] = ErrorMeta(code: "E0420", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "闭包参数借用与调用方借用冲突", fix: Some(FixSuggestion(description: "调整闭包签名")))
    m["E0421"] = ErrorMeta(code: "E0421", category: ErrorCategory.Borrow, severity: Severity.Warning,
        template: "unsafe 代码绕过了借用检查但不安全", fix: Some(FixSuggestion(description: "审查 unsafe 借用")))
    m["E0422"] = ErrorMeta(code: "E0422", category: ErrorCategory.Borrow, severity: Severity.Warning,
        template: "PhantomData 导致意外的借用约束", fix: Some(FixSuggestion(description: "调整 PhantomData 参数")))
    m["E0423"] = ErrorMeta(code: "E0423", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "循环中借用随迭代失效", fix: Some(FixSuggestion(description: "将借用移出循环体")))
    m["E0424"] = ErrorMeta(code: "E0424", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "字段借用逃逸出包含结构体的生命周期", fix: Some(FixSuggestion(description: "缩短字段借用")))
    m["E0425"] = ErrorMeta(code: "E0425", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "泛型借用约束无法满足", fix: Some(FixSuggestion(description: "放宽或显式标注借用")))
    m["E0426"] = ErrorMeta(code: "E0426", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "在 await 点移动了非 Send 值", fix: Some(FixSuggestion(description: "确保跨 await 的值可 Send")))
    m["E0427"] = ErrorMeta(code: "E0427", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "借用包含 Drop 实现的类型导致约束冲突", fix: Some(FixSuggestion(description: "调整借用范围")))
    m["E0428"] = ErrorMeta(code: "E0428", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "返回的借用与参数生命周期不匹配", fix: Some(FixSuggestion(description: "使用生命周期参数关联")))
    m["E0429"] = ErrorMeta(code: "E0429", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "检测到自引用结构（借用自身字段）", fix: Some(FixSuggestion(description: "使用 heap 间接或重构")))
    m["E0430"] = ErrorMeta(code: "E0430", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "async 块按移动捕获了被借用的变量", fix: Some(FixSuggestion(description: "改用 Arc/引用")))
    m["E0431"] = ErrorMeta(code: "E0431", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "match guard 借用与主体借用冲突", fix: Some(FixSuggestion(description: "合并借用作用域")))
    m["E0432"] = ErrorMeta(code: "E0432", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "静态变量借用违反初始化顺序", fix: Some(FixSuggestion(description: "改用 lazy 初始化")))
    m["E0433"] = ErrorMeta(code: "E0433", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "内部可变性在借用检查下仍竞争", fix: Some(FixSuggestion(description: "使用同步内部可变类型")))
    m["E0434"] = ErrorMeta(code: "E0434", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "尝试借用未定长（unsized）类型", fix: Some(FixSuggestion(description: "使用指针或定长容器")))
    m["E0435"] = ErrorMeta(code: "E0435", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "借用结束点推断错误导致提前释放", fix: Some(FixSuggestion(description: "显式绑定借用")))
    m["E0436"] = ErrorMeta(code: "E0436", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "闭包内移动了外部仍需使用的值", fix: Some(FixSuggestion(description: "克隆或改用引用")))
    m["E0437"] = ErrorMeta(code: "E0437", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "guard 与 arm 对同一值的不同借用", fix: Some(FixSuggestion(description: "统一借用模式")))
    m["E0438"] = ErrorMeta(code: "E0438", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "临时借用在语句结束前被丢弃", fix: Some(FixSuggestion(description: "绑定到具名变量")))
    m["E0439"] = ErrorMeta(code: "E0439", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "trait 对象借用约束无法满足", fix: Some(FixSuggestion(description: "使用具体类型或泛型")))
    m["E0440"] = ErrorMeta(code: "E0440", category: ErrorCategory.Borrow, severity: Severity.Error,
        template: "借用强制转换（&T -> &U）失败", fix: Some(FixSuggestion(description: "检查类型可转换性")))
    m["E0501"] = ErrorMeta(code: "E0501", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "生命周期参数缺少约束（可能为 'static 误用）", fix: Some(FixSuggestion(description: "添加生命周期 bound")))
    m["E0502"] = ErrorMeta(code: "E0502", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "生命周期 {a} 与 {b} 不匹配", fix: Some(FixSuggestion(description: "统一生命周期标注")))
    m["E0503"] = ErrorMeta(code: "E0503", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "引用返回缺少生命周期标注", fix: Some(FixSuggestion(description: "为引用添加生命周期参数")))
    m["E0504"] = ErrorMeta(code: "E0504", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "匿名生命周期推断冲突", fix: Some(FixSuggestion(description: "显式标注生命周期")))
    m["E0505"] = ErrorMeta(code: "E0505", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "期望 'static 但实际生命周期更短", fix: Some(FixSuggestion(description: "延长生命周期或使用 'static")))
    m["E0506"] = ErrorMeta(code: "E0506", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "类型别名中的生命周期未绑定", fix: Some(FixSuggestion(description: "在别名处标注生命周期")))
    m["E0507"] = ErrorMeta(code: "E0507", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "生命周期型变（variance）非法", fix: Some(FixSuggestion(description: "调整型变标注")))
    m["E0508"] = ErrorMeta(code: "E0508", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "高阶生命周期（for<'a>）推导失败", fix: Some(FixSuggestion(description: "显式标注 for<'a>")))
    m["E0509"] = ErrorMeta(code: "E0509", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "生命周期省略规则无法应用", fix: Some(FixSuggestion(description: "手动标注生命周期")))
    m["E0510"] = ErrorMeta(code: "E0510", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "结构体字段生命周期约束不一致", fix: Some(FixSuggestion(description: "统一字段生命周期")))
    m["E0511"] = ErrorMeta(code: "E0511", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "借用的生命周期短于使用者", fix: Some(FixSuggestion(description: "延长所有者生命周期")))
    m["E0512"] = ErrorMeta(code: "E0512", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "生命周期 {a} 未超出（outlive）{b}", fix: Some(FixSuggestion(description: "调整生命周期关系")))
    m["E0513"] = ErrorMeta(code: "E0513", category: ErrorCategory.Lifetime, severity: Severity.Warning,
        template: "PhantomData 生命周期参数冗余或缺失", fix: Some(FixSuggestion(description: "校正 PhantomData 标注")))
    m["E0514"] = ErrorMeta(code: "E0514", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "async 块捕获了短生命周期引用", fix: Some(FixSuggestion(description: "避免捕获短生命周期")))
    m["E0515"] = ErrorMeta(code: "E0515", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "闭包捕获的引用生命周期不足", fix: Some(FixSuggestion(description: "延长被捕获引用")))
    m["E0516"] = ErrorMeta(code: "E0516", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "迭代器关联生命周期不匹配", fix: Some(FixSuggestion(description: "检查 Item 生命周期")))
    m["E0517"] = ErrorMeta(code: "E0517", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "trait 对象默认生命周期推断错误", fix: Some(FixSuggestion(description: "显式指定 + 'a 或 'static")))
    m["E0518"] = ErrorMeta(code: "E0518", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "返回的引用生命周期无法关联参数", fix: Some(FixSuggestion(description: "使用输入生命周期参数")))
    m["E0519"] = ErrorMeta(code: "E0519", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "impl 中 Self 的生命周期约束冲突", fix: Some(FixSuggestion(description: "调整 impl 生命周期")))
    m["E0520"] = ErrorMeta(code: "E0520", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "泛型生命周期 bound 无法满足", fix: Some(FixSuggestion(description: "放宽 bound")))
    m["E0521"] = ErrorMeta(code: "E0521", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "协变返回类型生命周期不兼容", fix: Some(FixSuggestion(description: "使用不变生命周期")))
    m["E0522"] = ErrorMeta(code: "E0522", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "impl Trait 中的生命周期约束失败", fix: Some(FixSuggestion(description: "显式标注隐藏类型生命周期")))
    m["E0523"] = ErrorMeta(code: "E0523", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "嵌套生命周期推断循环", fix: Some(FixSuggestion(description: "手动标注内层生命周期")))
    m["E0524"] = ErrorMeta(code: "E0524", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "捕获了 'static 但要求更短生命周期", fix: Some(FixSuggestion(description: "改为短生命周期引用")))
    m["E0525"] = ErrorMeta(code: "E0525", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "Drop 实现中生命周期约束冲突", fix: Some(FixSuggestion(description: "简化 Drop 逻辑")))
    m["E0526"] = ErrorMeta(code: "E0526", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "子类型生命周期关系不成立", fix: Some(FixSuggestion(description: "调整生命周期层级")))
    m["E0527"] = ErrorMeta(code: "E0527", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "早绑定与晚绑定生命周期混用错误", fix: Some(FixSuggestion(description: "统一绑定时机")))
    m["E0528"] = ErrorMeta(code: "E0528", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "const 上下文中生命周期标注无效", fix: Some(FixSuggestion(description: "移除 const 中的生命周期")))
    m["E0529"] = ErrorMeta(code: "E0529", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "生成器（yield）生命周期不一致", fix: Some(FixSuggestion(description: "统一生成器生命周期")))
    m["E0530"] = ErrorMeta(code: "E0530", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "拆分借用导致生命周期分裂", fix: Some(FixSuggestion(description: "使用单一借用")))
    m["E0531"] = ErrorMeta(code: "E0531", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "函数指针引用生命周期不匹配", fix: Some(FixSuggestion(description: "检查函数签名生命周期")))
    m["E0532"] = ErrorMeta(code: "E0532", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "数组元素引用生命周期冲突", fix: Some(FixSuggestion(description: "统一元素生命周期")))
    m["E0533"] = ErrorMeta(code: "E0533", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "联合体字段引用生命周期不安全", fix: Some(FixSuggestion(description: "避免在 union 中使用引用")))
    m["E0534"] = ErrorMeta(code: "E0534", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "trait 方法生命周期与实现不一致", fix: Some(FixSuggestion(description: "对齐生命周期标注")))
    m["E0535"] = ErrorMeta(code: "E0535", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "生命周期参数名 {name} 重复", fix: Some(FixSuggestion(description: "重命名生命周期参数")))
    m["E0536"] = ErrorMeta(code: "E0536", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "RAII 资源生命周期过早结束", fix: Some(FixSuggestion(description: "延长资源所有者")))
    m["E0537"] = ErrorMeta(code: "E0537", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "关联类型生命周期 bound 失败", fix: Some(FixSuggestion(description: "添加关联类型生命周期")))
    m["E0538"] = ErrorMeta(code: "E0538", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "对临时值的引用生命周期不足", fix: Some(FixSuggestion(description: "绑定到具名变量")))
    m["E0539"] = ErrorMeta(code: "E0539", category: ErrorCategory.Lifetime, severity: Severity.Error,
        template: "trait 自身生命周期参数使用非法", fix: Some(FixSuggestion(description: "移除或修正 trait 生命周期")))
    m["E0601"] = ErrorMeta(code: "E0601", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型实参数量不匹配：期望 {expected}，得到 {got}", fix: Some(FixSuggestion(description: "核对泛型实参")))
    m["E0602"] = ErrorMeta(code: "E0602", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型类型实参无法推导", fix: Some(FixSuggestion(description: "显式标注泛型实参")))
    m["E0603"] = ErrorMeta(code: "E0603", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型约束不满足：{bound}", fix: Some(FixSuggestion(description: "满足泛型约束")))
    m["E0604"] = ErrorMeta(code: "E0604", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型类型缺少 trait bound {trait}", fix: Some(FixSuggestion(description: "为泛型添加 bound")))
    m["E0605"] = ErrorMeta(code: "E0605", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型别名存在递归且无大小", fix: Some(FixSuggestion(description: "打破别名递归")))
    m["E0606"] = ErrorMeta(code: "E0606", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型单态化失败：{name}", fix: Some(FixSuggestion(description: "检查泛型实参是否可实例化")))
    m["E0607"] = ErrorMeta(code: "E0607", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "单态化生成代码量超过限制（{limit}）", fix: Some(FixSuggestion(description: "减少泛型实例化组合")))
    m["E0608"] = ErrorMeta(code: "E0608", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "高阶泛型 bound 推导失败", fix: Some(FixSuggestion(description: "显式标注 bound")))
    m["E0609"] = ErrorMeta(code: "E0609", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型默认实参缺失", fix: Some(FixSuggestion(description: "提供默认实参或显式指定")))
    m["E0610"] = ErrorMeta(code: "E0610", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型默认实参与显式实参冲突", fix: Some(FixSuggestion(description: "统一实参来源")))
    m["E0611"] = ErrorMeta(code: "E0611", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型型变标注与用法冲突", fix: Some(FixSuggestion(description: "调整型变标注")))
    m["E0612"] = ErrorMeta(code: "E0612", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型参数要求定长但传入未定长类型", fix: Some(FixSuggestion(description: "添加 Sized bound")))
    m["E0613"] = ErrorMeta(code: "E0613", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型关联类型未绑定", fix: Some(FixSuggestion(description: "指定关联类型")))
    m["E0614"] = ErrorMeta(code: "E0614", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "当前不支持泛型关联类型（GAT）", fix: Some(FixSuggestion(description: "改用具体关联类型")))
    m["E0615"] = ErrorMeta(code: "E0615", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "常量泛型实参不匹配：期望 {expected}", fix: Some(FixSuggestion(description: "核对常量泛型值")))
    m["E0616"] = ErrorMeta(code: "E0616", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "常量泛型实参不是编译期常量", fix: Some(FixSuggestion(description: "使用编译期常量")))
    m["E0617"] = ErrorMeta(code: "E0617", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "常量泛型求值溢出", fix: Some(FixSuggestion(description: "降低常量值")))
    m["E0618"] = ErrorMeta(code: "E0618", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型 trait 对象无法直接构建", fix: Some(FixSuggestion(description: "指定泛型实参")))
    m["E0619"] = ErrorMeta(code: "E0619", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型 impl 与具体 impl 冲突", fix: Some(FixSuggestion(description: "移除冲突实现")))
    m["E0620"] = ErrorMeta(code: "E0620", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型 blanket 实现与具体实现冲突", fix: Some(FixSuggestion(description: "缩小 blanket 范围")))
    m["E0621"] = ErrorMeta(code: "E0621", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型方法重载解析失败", fix: Some(FixSuggestion(description: "显式指定泛型实参")))
    m["E0622"] = ErrorMeta(code: "E0622", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型类型参数 {name} 被遮蔽", fix: Some(FixSuggestion(description: "重命名类型参数")))
    m["E0623"] = ErrorMeta(code: "E0623", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "枚举泛型约束无法满足", fix: Some(FixSuggestion(description: "放宽枚举泛型 bound")))
    m["E0624"] = ErrorMeta(code: "E0624", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型函数指针类型不兼容", fix: Some(FixSuggestion(description: "对齐泛型签名")))
    m["E0625"] = ErrorMeta(code: "E0625", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型特化实现未生效", fix: Some(FixSuggestion(description: "检查特化层级")))
    m["E0626"] = ErrorMeta(code: "E0626", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "PhantomData 泛型参数不匹配", fix: Some(FixSuggestion(description: "校正 PhantomData 类型")))
    m["E0627"] = ErrorMeta(code: "E0627", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "where 子句约束未满足", fix: Some(FixSuggestion(description: "补全 where 约束")))
    m["E0628"] = ErrorMeta(code: "E0628", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "impl 泛型参数数量不一致", fix: Some(FixSuggestion(description: "核对泛型参数")))
    m["E0629"] = ErrorMeta(code: "E0629", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型类型别名循环引用", fix: Some(FixSuggestion(description: "打破别名循环")))
    m["E0630"] = ErrorMeta(code: "E0630", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "否定实现与泛型实现歧义", fix: Some(FixSuggestion(description: "明确实现边界")))
    m["E0631"] = ErrorMeta(code: "E0631", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "结构体泛型字段约束冲突", fix: Some(FixSuggestion(description: "统一字段泛型 bound")))
    m["E0632"] = ErrorMeta(code: "E0632", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "类型内高阶泛型推导失败", fix: Some(FixSuggestion(description: "显式标注泛型")))
    m["E0633"] = ErrorMeta(code: "E0633", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型 trait bound 多重冲突", fix: Some(FixSuggestion(description: "精简 trait bound")))
    m["E0634"] = ErrorMeta(code: "E0634", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "存在类型泛型标注非法", fix: Some(FixSuggestion(description: "修正存在类型")))
    m["E0635"] = ErrorMeta(code: "E0635", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型默认实参形成循环", fix: Some(FixSuggestion(description: "打破默认实参循环")))
    m["E0636"] = ErrorMeta(code: "E0636", category: ErrorCategory.Generic, severity: Severity.Warning,
        template: "泛型实现存在不健全（unsound）风险", fix: Some(FixSuggestion(description: "审查泛型约束")))
    m["E0637"] = ErrorMeta(code: "E0637", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型实现的连贯性（coherence）判定失败", fix: Some(FixSuggestion(description: "明确实现归属")))
    m["E0638"] = ErrorMeta(code: "E0638", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "元组泛型元素类型不匹配", fix: Some(FixSuggestion(description: "统一元组元素类型")))
    m["E0639"] = ErrorMeta(code: "E0639", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "数组泛型长度不匹配：期望 {expected}", fix: Some(FixSuggestion(description: "核对数组长度")))
    m["E0640"] = ErrorMeta(code: "E0640", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "impl Trait 位置不支持（仅允许参数/返回）", fix: Some(FixSuggestion(description: "调整 impl Trait 位置")))
    m["E0641"] = ErrorMeta(code: "E0641", category: ErrorCategory.Generic, severity: Severity.Error,
        template: "泛型内联展开形成循环", fix: Some(FixSuggestion(description: "打破内联循环")))
    m["E0701"] = ErrorMeta(code: "E0701", category: ErrorCategory.Module, severity: Severity.Error,
        template: "模块 {module} 未找到", fix: Some(FixSuggestion(description: "检查模块路径或创建模块")))
    m["E0702"] = ErrorMeta(code: "E0702", category: ErrorCategory.Module, severity: Severity.Error,
        template: "模块文件 {file} 不存在", fix: Some(FixSuggestion(description: "创建对应源文件")))
    m["E0703"] = ErrorMeta(code: "E0703", category: ErrorCategory.Module, severity: Severity.Error,
        template: "模块依赖存在循环", fix: Some(FixSuggestion(description: "打破模块循环依赖")))
    m["E0704"] = ErrorMeta(code: "E0704", category: ErrorCategory.Module, severity: Severity.Error,
        template: "模块 {module} 被重复定义", fix: Some(FixSuggestion(description: "删除重复模块声明")))
    m["E0705"] = ErrorMeta(code: "E0705", category: ErrorCategory.Module, severity: Severity.Error,
        template: "模块内私有项被跨模块访问：{name}", fix: Some(FixSuggestion(description: "调整可见性")))
    m["E0706"] = ErrorMeta(code: "E0706", category: ErrorCategory.Module, severity: Severity.Error,
        template: "重导出（pub use）冲突：{name}", fix: Some(FixSuggestion(description: "移除冲突重导出")))
    m["E0707"] = ErrorMeta(code: "E0707", category: ErrorCategory.Module, severity: Severity.Warning,
        template: "通配重导出（pub use *）引入歧义", fix: Some(FixSuggestion(description: "改用显式重导出")))
    m["E0708"] = ErrorMeta(code: "E0708", category: ErrorCategory.Module, severity: Severity.Error,
        template: "声明位置与模块树结构不符", fix: Some(FixSuggestion(description: "调整文件/目录结构")))
    m["E0709"] = ErrorMeta(code: "E0709", category: ErrorCategory.Module, severity: Severity.Error,
        template: "匿名模块（目录无 mod 声明）无法解析", fix: Some(FixSuggestion(description: "为目录添加 mod 声明")))
    m["E0710"] = ErrorMeta(code: "E0710", category: ErrorCategory.Module, severity: Severity.Error,
        template: "模块名与已有项冲突：{name}", fix: Some(FixSuggestion(description: "重命名模块")))
    m["E0711"] = ErrorMeta(code: "E0711", category: ErrorCategory.Module, severity: Severity.Warning,
        template: "模块嵌套层级过深（{depth}）", fix: Some(FixSuggestion(description: "扁平化模块结构")))
    m["E0712"] = ErrorMeta(code: "E0712", category: ErrorCategory.Module, severity: Severity.Error,
        template: "宏可见性作用域不足（需 #[macro_use]）", fix: Some(FixSuggestion(description: "调整宏导出作用域")))
    m["E0713"] = ErrorMeta(code: "E0713", category: ErrorCategory.Module, severity: Severity.Error,
        template: "路径 {path} 无法解析", fix: Some(FixSuggestion(description: "检查路径拼写与导入")))
    m["E0714"] = ErrorMeta(code: "E0714", category: ErrorCategory.Module, severity: Severity.Error,
        template: "super 路径指向模块树根之外", fix: Some(FixSuggestion(description: "修正 super 使用位置")))
    m["E0715"] = ErrorMeta(code: "E0715", category: ErrorCategory.Module, severity: Severity.Error,
        template: "crate 根模块缺失", fix: Some(FixSuggestion(description: "添加 lib/main 入口")))
    m["E0716"] = ErrorMeta(code: "E0716", category: ErrorCategory.Module, severity: Severity.Error,
        template: "内联模块与文件模块定义冲突", fix: Some(FixSuggestion(description: "统一模块定义方式")))
    m["E0717"] = ErrorMeta(code: "E0717", category: ErrorCategory.Module, severity: Severity.Error,
        template: "外部 crate {crate} 未声明依赖", fix: Some(FixSuggestion(description: "在配置中添加依赖")))
    m["E0718"] = ErrorMeta(code: "E0718", category: ErrorCategory.Module, severity: Severity.Error,
        template: "外部 crate 版本不满足：期望 {expected}", fix: Some(FixSuggestion(description: "调整依赖版本")))
    m["E0719"] = ErrorMeta(code: "E0719", category: ErrorCategory.Module, severity: Severity.Error,
        template: "模块需特性开关（feature）但未开启", fix: Some(FixSuggestion(description: "开启对应特性")))
    m["E0720"] = ErrorMeta(code: "E0720", category: ErrorCategory.Module, severity: Severity.Error,
        template: "私有模块被公开重导出", fix: Some(FixSuggestion(description: "移除公开重导出")))
    m["E0721"] = ErrorMeta(code: "E0721", category: ErrorCategory.Module, severity: Severity.Error,
        template: "模块初始化顺序未定义", fix: Some(FixSuggestion(description: "显式初始化顺序")))
    m["E0722"] = ErrorMeta(code: "E0722", category: ErrorCategory.Module, severity: Severity.Error,
        template: "cfg 禁用的模块被引用", fix: Some(FixSuggestion(description: "检查 cfg 条件")))
    m["E0723"] = ErrorMeta(code: "E0723", category: ErrorCategory.Module, severity: Severity.Error,
        template: "路径 {path} 存在多个候选", fix: Some(FixSuggestion(description: "使用完全限定路径")))
    m["E0724"] = ErrorMeta(code: "E0724", category: ErrorCategory.Module, severity: Severity.Error,
        template: "use 别名与本地定义冲突：{name}", fix: Some(FixSuggestion(description: "重命名别名")))
    m["E0725"] = ErrorMeta(code: "E0725", category: ErrorCategory.Module, severity: Severity.Error,
        template: "trait 在模块中未正确导出", fix: Some(FixSuggestion(description: "添加 pub 导出")))
    m["E0726"] = ErrorMeta(code: "E0726", category: ErrorCategory.Module, severity: Severity.Error,
        template: "结构体在模块中不可见：{name}", fix: Some(FixSuggestion(description: "提升可见性")))
    m["E0727"] = ErrorMeta(code: "E0727", category: ErrorCategory.Module, severity: Severity.Error,
        template: "枚举变体路径解析失败：{path}", fix: Some(FixSuggestion(description: "检查枚举路径")))
    m["E0728"] = ErrorMeta(code: "E0728", category: ErrorCategory.Module, severity: Severity.Warning,
        template: "模块文档与目录文档冲突", fix: Some(FixSuggestion(description: "统一模块文档")))
    m["E0729"] = ErrorMeta(code: "E0729", category: ErrorCategory.Module, severity: Severity.Error,
        template: "模块导出不安全项但缺少 unsafe", fix: Some(FixSuggestion(description: "添加 unsafe 标注")))
    m["E0730"] = ErrorMeta(code: "E0730", category: ErrorCategory.Module, severity: Severity.Error,
        template: "泛型模块参数未推导", fix: Some(FixSuggestion(description: "显式标注泛型")))
    m["E0731"] = ErrorMeta(code: "E0731", category: ErrorCategory.Module, severity: Severity.Error,
        template: "平台特定模块在当前目标不可用", fix: Some(FixSuggestion(description: "检查目标条件编译")))
    m["E0732"] = ErrorMeta(code: "E0732", category: ErrorCategory.Module, severity: Severity.Error,
        template: "测试模块（test）被发布构建引用", fix: Some(FixSuggestion(description: "限定到 test cfg")))
    m["E0733"] = ErrorMeta(code: "E0733", category: ErrorCategory.Module, severity: Severity.Error,
        template: "基准测试模块引用错误", fix: Some(FixSuggestion(description: "检查 bench 配置")))
    m["E0734"] = ErrorMeta(code: "E0734", category: ErrorCategory.Module, severity: Severity.Error,
        template: "声明宏与作用域模块分离导致失效", fix: Some(FixSuggestion(description: "合并宏作用域")))
    m["E0735"] = ErrorMeta(code: "E0735", category: ErrorCategory.Module, severity: Severity.Error,
        template: "模块重导出形成循环", fix: Some(FixSuggestion(description: "打破重导出循环")))
    m["E0736"] = ErrorMeta(code: "E0736", category: ErrorCategory.Module, severity: Severity.Error,
        template: "模块因可见性被完全隐藏", fix: Some(FixSuggestion(description: "调整可见性层级")))
    m["E0737"] = ErrorMeta(code: "E0737", category: ErrorCategory.Module, severity: Severity.Error,
        template: "模块属性（attr）相互冲突", fix: Some(FixSuggestion(description: "移除冲突属性")))
    m["E0738"] = ErrorMeta(code: "E0738", category: ErrorCategory.Module, severity: Severity.Error,
        template: "类型与值命名空间冲突：{name}", fix: Some(FixSuggestion(description: "重命名冲突项")))
    m["E0739"] = ErrorMeta(code: "E0739", category: ErrorCategory.Module, severity: Severity.Error,
        template: "内联模块定义在非预期文件", fix: Some(FixSuggestion(description: "调整模块位置")))
    m["E0740"] = ErrorMeta(code: "E0740", category: ErrorCategory.Module, severity: Severity.Warning,
        template: "模块无任何导出项", fix: Some(FixSuggestion(description: "补充模块内容或移除")))
    m["E1101"] = ErrorMeta(code: "E1101", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "LLVM 模块校验失败：{pass}", fix: Some(FixSuggestion(description: "检查生成的中间表示")))
    m["E1102"] = ErrorMeta(code: "E1102", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "LLVM IR 降级失败：{reason}", fix: Some(FixSuggestion(description: "检查前端生成代码")))
    m["E1103"] = ErrorMeta(code: "E1103", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "LLVM 优化器崩溃", fix: Some(FixSuggestion(description: "禁用该优化 pass 或升级工具链")))
    m["E1104"] = ErrorMeta(code: "E1104", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "LLVM 不支持该特性：{feature}", fix: Some(FixSuggestion(description: "改用受支持的实现")))
    m["E1105"] = ErrorMeta(code: "E1105", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "生成的中间表示（IR）非法：{reason}", fix: Some(FixSuggestion(description: "检查前端代码生成")))
    m["E1106"] = ErrorMeta(code: "E1106", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "IR 类型不匹配：期望 {expected}", fix: Some(FixSuggestion(description: "统一 IR 类型")))
    m["E1107"] = ErrorMeta(code: "E1107", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "IR 中引用了未定义的符号 {name}", fix: Some(FixSuggestion(description: "补全符号定义")))
    m["E1108"] = ErrorMeta(code: "E1108", category: ErrorCategory.Backend, severity: Severity.Warning,
        template: "IR 包含不可达基本块未清理", fix: Some(FixSuggestion(description: "清理死代码")))
    m["E1109"] = ErrorMeta(code: "E1109", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "寄存器分配失败（寄存器不足）", fix: Some(FixSuggestion(description: "减少局部变量或拆分函数")))
    m["E1110"] = ErrorMeta(code: "E1110", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "栈帧过大（{size} 字节）", fix: Some(FixSuggestion(description: "减少栈上大对象")))
    m["E1111"] = ErrorMeta(code: "E1111", category: ErrorCategory.Backend, severity: Severity.Warning,
        template: "代码布局（code layout）失败", fix: Some(FixSuggestion(description: "调整函数布局策略")))
    m["E1112"] = ErrorMeta(code: "E1112", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "目标段（section）写入失败", fix: Some(FixSuggestion(description: "检查段属性")))
    m["E1113"] = ErrorMeta(code: "E1113", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "目标不支持该重定位类型", fix: Some(FixSuggestion(description: "更换目标或调整代码")))
    m["E1114"] = ErrorMeta(code: "E1114", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "目标特性 {feature} 不可用", fix: Some(FixSuggestion(description: "启用目标特性")))
    m["E1115"] = ErrorMeta(code: "E1115", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "未知的调用约定：{conv}", fix: Some(FixSuggestion(description: "使用受支持的调用约定")))
    m["E1116"] = ErrorMeta(code: "E1116", category: ErrorCategory.Backend, severity: Severity.Warning,
        template: "调试信息在后端丢失", fix: Some(FixSuggestion(description: "保留调试信息生成")))
    m["E1117"] = ErrorMeta(code: "E1117", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "异常处理表过大", fix: Some(FixSuggestion(description: "拆分函数或减少异常路径")))
    m["E1118"] = ErrorMeta(code: "E1118", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "全局变量初始化失败", fix: Some(FixSuggestion(description: "检查全局初始化表达式")))
    m["E1119"] = ErrorMeta(code: "E1119", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "后端常量折叠失败", fix: Some(FixSuggestion(description: "简化常量表达式")))
    m["E1120"] = ErrorMeta(code: "E1120", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "内联汇编生成失败：{reason}", fix: Some(FixSuggestion(description: "检查汇编语法")))
    m["E1121"] = ErrorMeta(code: "E1121", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "向量指令后端生成失败", fix: Some(FixSuggestion(description: "改用标量实现")))
    m["E1122"] = ErrorMeta(code: "E1122", category: ErrorCategory.Backend, severity: Severity.Warning,
        template: "目标不支持尾调用优化", fix: Some(FixSuggestion(description: "避免尾调用")))
    m["E1123"] = ErrorMeta(code: "E1123", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "内联汇编约束（constraint）非法", fix: Some(FixSuggestion(description: "修正约束字符串")))
    m["E1124"] = ErrorMeta(code: "E1124", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "LLVM 元数据写入失败", fix: Some(FixSuggestion(description: "检查元数据格式")))
    m["E1125"] = ErrorMeta(code: "E1125", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "LLVM 位码（bitcode）解析失败", fix: Some(FixSuggestion(description: "重新生成位码")))
    m["E1126"] = ErrorMeta(code: "E1126", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "目标机器（TargetMachine）初始化失败", fix: Some(FixSuggestion(description: "检查目标三元组")))
    m["E1127"] = ErrorMeta(code: "E1127", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "数据布局（datalayout）不匹配", fix: Some(FixSuggestion(description: "统一数据布局")))
    m["E1128"] = ErrorMeta(code: "E1128", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "ABI 降级（lowering）失败", fix: Some(FixSuggestion(description: "检查函数签名 ABI")))
    m["E1129"] = ErrorMeta(code: "E1129", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "展开信息（unwind）生成失败", fix: Some(FixSuggestion(description: "检查异常处理配置")))
    m["E1130"] = ErrorMeta(code: "E1130", category: ErrorCategory.Backend, severity: Severity.Warning,
        template: "性能分析插桩失败", fix: Some(FixSuggestion(description: "关闭插桩或调整配置")))
    m["E1131"] = ErrorMeta(code: "E1131", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "该目标不支持消毒剂（sanitizer）", fix: Some(FixSuggestion(description: "更换目标或关闭 sanitizer")))
    m["E1132"] = ErrorMeta(code: "E1132", category: ErrorCategory.Backend, severity: Severity.Warning,
        template: "ThinLTO 失败", fix: Some(FixSuggestion(description: "改用完整 LTO 或禁用")))
    m["E1133"] = ErrorMeta(code: "E1133", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "LTO 跨模块符号冲突", fix: Some(FixSuggestion(description: "统一符号定义")))
    m["E1134"] = ErrorMeta(code: "E1134", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "后端处理超时", fix: Some(FixSuggestion(description: "简化函数或增加超时")))
    m["E1135"] = ErrorMeta(code: "E1135", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "后端内存耗尽", fix: Some(FixSuggestion(description: "减少编译单元规模")))
    m["E1136"] = ErrorMeta(code: "E1136", category: ErrorCategory.Backend, severity: Severity.Warning,
        template: "LLVM 校验器超过内部限制", fix: Some(FixSuggestion(description: "拆分模块")))
    m["E1137"] = ErrorMeta(code: "E1137", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "内建函数（intrinsic）降级失败：{name}", fix: Some(FixSuggestion(description: "检查 intrinsic 签名")))
    m["E1138"] = ErrorMeta(code: "E1138", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "块地址（blockaddress）引用非法", fix: Some(FixSuggestion(description: "修正块引用")))
    m["E1139"] = ErrorMeta(code: "E1139", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "COMDAT 分组失败", fix: Some(FixSuggestion(description: "检查 comdat 选择")))
    m["E1140"] = ErrorMeta(code: "E1140", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "别名（alias）生成失败", fix: Some(FixSuggestion(description: "检查别名目标")))
    m["E1141"] = ErrorMeta(code: "E1141", category: ErrorCategory.Backend, severity: Severity.Error,
        template: "弱符号（weak）冲突", fix: Some(FixSuggestion(description: "统一符号强弱")))
}

/// 填充错误码元数据第 4 组（Opt .. Mem），共 5 个类别。
func buildMetaPart4(m: HashMap<String, ErrorMeta>) {
    m["E1201"] = ErrorMeta(code: "E1201", category: ErrorCategory.Opt, severity: Severity.Error,
        template: "优化 pass {pass} 执行失败", fix: Some(FixSuggestion(description: "禁用该 pass 或报告工具链 bug")))
    m["E1202"] = ErrorMeta(code: "E1202", category: ErrorCategory.Opt, severity: Severity.Error,
        template: "优化器在 pass {pass} 崩溃", fix: Some(FixSuggestion(description: "升级工具链或绕过该 pass")))
    m["E1203"] = ErrorMeta(code: "E1203", category: ErrorCategory.Opt, severity: Severity.Error,
        template: "优化后的 IR 与前置约束冲突", fix: Some(FixSuggestion(description: "检查优化合法性")))
    m["E1204"] = ErrorMeta(code: "E1204", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "循环展开失败", fix: Some(FixSuggestion(description: "调整循环边界或禁用展开")))
    m["E1205"] = ErrorMeta(code: "E1205", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "向量化失败", fix: Some(FixSuggestion(description: "改用手写标量循环")))
    m["E1206"] = ErrorMeta(code: "E1206", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "函数内联失败：{reason}", fix: Some(FixSuggestion(description: "调整内联阈值")))
    m["E1207"] = ErrorMeta(code: "E1207", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "内联递归过深", fix: Some(FixSuggestion(description: "限制内联深度")))
    m["E1208"] = ErrorMeta(code: "E1208", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "死代码未被移除（可能的 bug）", fix: Some(FixSuggestion(description: "检查优化级别")))
    m["E1209"] = ErrorMeta(code: "E1209", category: ErrorCategory.Opt, severity: Severity.Error,
        template: "常量传播溢出", fix: Some(FixSuggestion(description: "降低常量规模")))
    m["E1210"] = ErrorMeta(code: "E1210", category: ErrorCategory.Opt, severity: Severity.Error,
        template: "全局值编号（GVN）冲突", fix: Some(FixSuggestion(description: "检查表达式等价性")))
    m["E1211"] = ErrorMeta(code: "E1211", category: ErrorCategory.Opt, severity: Severity.Error,
        template: "稀疏条件常量传播失败", fix: Some(FixSuggestion(description: "简化控制流")))
    m["E1212"] = ErrorMeta(code: "E1212", category: ErrorCategory.Opt, severity: Severity.Error,
        template: "内存到寄存器提升失败", fix: Some(FixSuggestion(description: "检查内存访问模式")))
    m["E1213"] = ErrorMeta(code: "E1213", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "循环不变量外提失败", fix: Some(FixSuggestion(description: "调整循环结构")))
    m["E1214"] = ErrorMeta(code: "E1214", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "尾块复制失败", fix: Some(FixSuggestion(description: "调整控制流")))
    m["E1215"] = ErrorMeta(code: "E1215", category: ErrorCategory.Opt, severity: Severity.Error,
        template: "窥孔优化失败", fix: Some(FixSuggestion(description: "检查指令序列")))
    m["E1216"] = ErrorMeta(code: "E1216", category: ErrorCategory.Opt, severity: Severity.Error,
        template: "强度削减产生非法序列", fix: Some(FixSuggestion(description: "检查运算等价性")))
    m["E1217"] = ErrorMeta(code: "E1217", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "别名分析失败", fix: Some(FixSuggestion(description: "放宽别名假设")))
    m["E1218"] = ErrorMeta(code: "E1218", category: ErrorCategory.Opt, severity: Severity.Error,
        template: "优化级别非法：{level}", fix: Some(FixSuggestion(description: "使用合法优化级别")))
    m["E1219"] = ErrorMeta(code: "E1219", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "优化尺寸（Os/Oz）与速度冲突", fix: Some(FixSuggestion(description: "统一优化目标")))
    m["E1220"] = ErrorMeta(code: "E1220", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "优化使用的性能画像不匹配", fix: Some(FixSuggestion(description: "重新采集画像")))
    m["E1221"] = ErrorMeta(code: "E1221", category: ErrorCategory.Opt, severity: Severity.Error,
        template: "优化破坏了 IR 合法性", fix: Some(FixSuggestion(description: "报告工具链 bug")))
    m["E1222"] = ErrorMeta(code: "E1222", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "循环旋转失败", fix: Some(FixSuggestion(description: "调整循环条件")))
    m["E1223"] = ErrorMeta(code: "E1223", category: ErrorCategory.Opt, severity: Severity.Error,
        template: "全局优化失败", fix: Some(FixSuggestion(description: "检查全局变量初始化")))
    m["E1224"] = ErrorMeta(code: "E1224", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "过程间常量传播失败", fix: Some(FixSuggestion(description: "简化调用图")))
    m["E1225"] = ErrorMeta(code: "E1225", category: ErrorCategory.Opt, severity: Severity.Error,
        template: "参数提升优化失败", fix: Some(FixSuggestion(description: "检查参数类型")))
    m["E1226"] = ErrorMeta(code: "E1226", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "结构体返回优化失败", fix: Some(FixSuggestion(description: "调整返回类型")))
    m["E1227"] = ErrorMeta(code: "E1227", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "尾调用优化失败", fix: Some(FixSuggestion(description: "检查尾调用形态")))
    m["E1228"] = ErrorMeta(code: "E1228", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "SLP 向量化失败", fix: Some(FixSuggestion(description: "放宽向量化条件")))
    m["E1229"] = ErrorMeta(code: "E1229", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "循环版本化失败", fix: Some(FixSuggestion(description: "禁用循环版本化")))
    m["E1230"] = ErrorMeta(code: "E1230", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "部分内联失败", fix: Some(FixSuggestion(description: "关闭部分内联")))
    m["E1231"] = ErrorMeta(code: "E1231", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "冷热代码分离失败", fix: Some(FixSuggestion(description: "关闭该优化")))
    m["E1232"] = ErrorMeta(code: "E1232", category: ErrorCategory.Opt, severity: Severity.Error,
        template: "函数合并优化失败", fix: Some(FixSuggestion(description: "检查函数签名等价")))
    m["E1233"] = ErrorMeta(code: "E1233", category: ErrorCategory.Opt, severity: Severity.Error,
        template: "负载消除（load elim）冲突", fix: Some(FixSuggestion(description: "检查内存模型")))
    m["E1234"] = ErrorMeta(code: "E1234", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "循环外提（unswitch）失败", fix: Some(FixSuggestion(description: "调整条件")))
    m["E1235"] = ErrorMeta(code: "E1235", category: ErrorCategory.Opt, severity: Severity.Error,
        template: "表达式重结合失败", fix: Some(FixSuggestion(description: "检查结合律合法性")))
    m["E1236"] = ErrorMeta(code: "E1236", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "循环惯用法识别失败", fix: Some(FixSuggestion(description: "关闭惯用法优化")))
    m["E1237"] = ErrorMeta(code: "E1237", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "控制流图简化失败", fix: Some(FixSuggestion(description: "检查异常边")))
    m["E1238"] = ErrorMeta(code: "E1238", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "归纳变量优化失败", fix: Some(FixSuggestion(description: "调整循环变量")))
    m["E1239"] = ErrorMeta(code: "E1239", category: ErrorCategory.Opt, severity: Severity.Error,
        template: "除/余优化产生未定义行为", fix: Some(FixSuggestion(description: "检查除零")))
    m["E1240"] = ErrorMeta(code: "E1240", category: ErrorCategory.Opt, severity: Severity.Error,
        template: "移位优化溢出", fix: Some(FixSuggestion(description: "检查移位量")))
    m["E1241"] = ErrorMeta(code: "E1241", category: ErrorCategory.Opt, severity: Severity.Warning,
        template: "浮点重结合改变语义", fix: Some(FixSuggestion(description: "关闭浮点重结合")))
    m["E1301"] = ErrorMeta(code: "E1301", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "未找到链接器（linker）", fix: Some(FixSuggestion(description: "安装或配置链接器路径")))
    m["E1302"] = ErrorMeta(code: "E1302", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "链接器调用失败：{reason}", fix: Some(FixSuggestion(description: "检查链接命令与参数")))
    m["E1303"] = ErrorMeta(code: "E1303", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "链接时未定义符号：{symbol}", fix: Some(FixSuggestion(description: "补充该符号的定义或依赖")))
    m["E1304"] = ErrorMeta(code: "E1304", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "链接时符号重复定义：{symbol}", fix: Some(FixSuggestion(description: "移除重复定义")))
    m["E1305"] = ErrorMeta(code: "E1305", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "链接库 {lib} 未找到", fix: Some(FixSuggestion(description: "检查库路径（-L）")))
    m["E1306"] = ErrorMeta(code: "E1306", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "链接库版本不兼容：{lib}", fix: Some(FixSuggestion(description: "升级或降级依赖库")))
    m["E1307"] = ErrorMeta(code: "E1307", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "缺少入口符号（如 main）", fix: Some(FixSuggestion(description: "提供入口函数")))
    m["E1308"] = ErrorMeta(code: "E1308", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "重定位溢出（地址超出范围）", fix: Some(FixSuggestion(description: "使用大地址模型")))
    m["E1309"] = ErrorMeta(code: "E1309", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "目标架构与库架构不匹配", fix: Some(FixSuggestion(description: "使用匹配架构的库")))
    m["E1310"] = ErrorMeta(code: "E1310", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "链接对象 ABI 不兼容", fix: Some(FixSuggestion(description: "统一编译 ABI")))
    m["E1311"] = ErrorMeta(code: "E1311", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "链接脚本（linker script）错误", fix: Some(FixSuggestion(description: "修正链接脚本")))
    m["E1312"] = ErrorMeta(code: "E1312", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "静态/动态链接方式冲突", fix: Some(FixSuggestion(description: "统一链接方式")))
    m["E1313"] = ErrorMeta(code: "E1313", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "标准库链接失败", fix: Some(FixSuggestion(description: "检查标准库路径")))
    m["E1314"] = ErrorMeta(code: "E1314", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "运行时库缺失", fix: Some(FixSuggestion(description: "配置运行时库")))
    m["E1315"] = ErrorMeta(code: "E1315", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "链接器内存耗尽", fix: Some(FixSuggestion(description: "减少链接单元或增量链接")))
    m["E1316"] = ErrorMeta(code: "E1316", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "链接超时", fix: Some(FixSuggestion(description: "减少链接规模或增加超时")))
    m["E1317"] = ErrorMeta(code: "E1317", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "线程局部变量链接失败", fix: Some(FixSuggestion(description: "检查 TLS 模型")))
    m["E1318"] = ErrorMeta(code: "E1318", category: ErrorCategory.Linker, severity: Severity.Warning,
        template: "弱符号未解析到实现", fix: Some(FixSuggestion(description: "提供弱符号定义")))
    m["E1319"] = ErrorMeta(code: "E1319", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "导出符号缺失：{symbol}", fix: Some(FixSuggestion(description: "显式导出符号")))
    m["E1320"] = ErrorMeta(code: "E1320", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "导入库（import lib）缺失", fix: Some(FixSuggestion(description: "提供导入库")))
    m["E1321"] = ErrorMeta(code: "E1321", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "COMDAT 段冲突", fix: Some(FixSuggestion(description: "统一 comdat 选择")))
    m["E1322"] = ErrorMeta(code: "E1322", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "链接顺序错误导致符号未解析", fix: Some(FixSuggestion(description: "调整库顺序")))
    m["E1323"] = ErrorMeta(code: "E1323", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "bitcode 链接失败", fix: Some(FixSuggestion(description: "改用对象文件链接")))
    m["E1324"] = ErrorMeta(code: "E1324", category: ErrorCategory.Linker, severity: Severity.Warning,
        template: "链接时优化（LTO）失败", fix: Some(FixSuggestion(description: "禁用 LTO")))
    m["E1325"] = ErrorMeta(code: "E1325", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "链接脚本含未知命令", fix: Some(FixSuggestion(description: "修正脚本语法")))
    m["E1326"] = ErrorMeta(code: "E1326", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "动态库 {lib} 运行时缺失", fix: Some(FixSuggestion(description: "安装运行依赖")))
    m["E1327"] = ErrorMeta(code: "E1327", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "rpath 配置非法", fix: Some(FixSuggestion(description: "修正 rpath")))
    m["E1328"] = ErrorMeta(code: "E1328", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "符号可见性导致未链接", fix: Some(FixSuggestion(description: "调整符号可见性")))
    m["E1329"] = ErrorMeta(code: "E1329", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "链接对象语言（C/C++）不匹配", fix: Some(FixSuggestion(description: "统一语言前端")))
    m["E1330"] = ErrorMeta(code: "E1330", category: ErrorCategory.Linker, severity: Severity.Warning,
        template: "垃圾段回收（gc-sections）失败", fix: Some(FixSuggestion(description: "关闭 gc-sections")))
    m["E1331"] = ErrorMeta(code: "E1331", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "链接器内存映射失败", fix: Some(FixSuggestion(description: "减小链接规模")))
    m["E1332"] = ErrorMeta(code: "E1332", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "链接消毒剂运行时失败", fix: Some(FixSuggestion(description: "配置 sanitizer 运行时")))
    m["E1333"] = ErrorMeta(code: "E1333", category: ErrorCategory.Linker, severity: Severity.Warning,
        template: "死符号剥离失败", fix: Some(FixSuggestion(description: "关闭死剥离")))
    m["E1334"] = ErrorMeta(code: "E1334", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "链接器插件错误", fix: Some(FixSuggestion(description: "移除或更新插件")))
    m["E1335"] = ErrorMeta(code: "E1335", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "C 运行时启动文件缺失", fix: Some(FixSuggestion(description: "安装工具链 C 运行时")))
    m["E1336"] = ErrorMeta(code: "E1336", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "链接器版本过旧不支持特性", fix: Some(FixSuggestion(description: "升级链接器")))
    m["E1337"] = ErrorMeta(code: "E1337", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "名称修饰（mangling）冲突", fix: Some(FixSuggestion(description: "统一修饰方案")))
    m["E1338"] = ErrorMeta(code: "E1338", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "目标不支持位置无关可执行（PIE）", fix: Some(FixSuggestion(description: "禁用 PIE")))
    m["E1339"] = ErrorMeta(code: "E1339", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "链接指定的栈大小非法", fix: Some(FixSuggestion(description: "使用合法栈大小")))
    m["E1340"] = ErrorMeta(code: "E1340", category: ErrorCategory.Linker, severity: Severity.Error,
        template: "展开库（unwind lib）缺失", fix: Some(FixSuggestion(description: "配置展开库")))
    m["E1401"] = ErrorMeta(code: "E1401", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "FFI 函数签名与 C 侧不匹配", fix: Some(FixSuggestion(description: "核对 C 侧声明")))
    m["E1402"] = ErrorMeta(code: "E1402", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "FFI 不支持该类型：{ty}", fix: Some(FixSuggestion(description: "改用兼容类型")))
    m["E1403"] = ErrorMeta(code: "E1403", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "C ABI 调用约定不匹配", fix: Some(FixSuggestion(description: "统一调用约定")))
    m["E1404"] = ErrorMeta(code: "E1404", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "结构体内存布局（padding/align）与 C 不一致", fix: Some(FixSuggestion(description: "使用 repr(C)")))
    m["E1405"] = ErrorMeta(code: "E1405", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "枚举内存表示与 C 不一致", fix: Some(FixSuggestion(description: "指定 repr 标注")))
    m["E1406"] = ErrorMeta(code: "E1406", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "联合体布局与 C 不匹配", fix: Some(FixSuggestion(description: "使用 repr(C) 联合体")))
    m["E1407"] = ErrorMeta(code: "E1407", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "回调函数 ABI 不匹配", fix: Some(FixSuggestion(description: "标注正确的函数指针 ABI")))
    m["E1408"] = ErrorMeta(code: "E1408", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "不支持可变参数（varargs）FFI", fix: Some(FixSuggestion(description: "改用显式参数")))
    m["E1409"] = ErrorMeta(code: "E1409", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "FFI 调用缺少 unsafe 标注", fix: Some(FixSuggestion(description: "添加 unsafe 块")))
    m["E1410"] = ErrorMeta(code: "E1410", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "FFI 返回引用生命周期无法保证", fix: Some(FixSuggestion(description: "使用拥有型返回值")))
    m["E1411"] = ErrorMeta(code: "E1411", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "跨 FFI 边界发生 panic（未定义行为）", fix: Some(FixSuggestion(description: "在边界捕获 panic")))
    m["E1412"] = ErrorMeta(code: "E1412", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "FFI 两侧内存分配器不一致", fix: Some(FixSuggestion(description: "统一分配/释放侧")))
    m["E1413"] = ErrorMeta(code: "E1413", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "浮点 ABI（hard/soft）不匹配", fix: Some(FixSuggestion(description: "统一浮点 ABI")))
    m["E1414"] = ErrorMeta(code: "E1414", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "寄存器级 ABI 约定不一致", fix: Some(FixSuggestion(description: "检查目标 ABI")))
    m["E1415"] = ErrorMeta(code: "E1415", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "字节序（endian）不匹配", fix: Some(FixSuggestion(description: "显式处理字节序")))
    m["E1416"] = ErrorMeta(code: "E1416", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "对齐（alignment）要求不一致", fix: Some(FixSuggestion(description: "使用对齐标注")))
    m["E1417"] = ErrorMeta(code: "E1417", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "FFI 名称修饰（mangling）不匹配", fix: Some(FixSuggestion(description: "使用 extern 名称")))
    m["E1418"] = ErrorMeta(code: "E1418", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "字符编码在 FFI 边界不一致", fix: Some(FixSuggestion(description: "统一字符串编码")))
    m["E1419"] = ErrorMeta(code: "E1419", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "布尔类型大小在 ABI 中不一致", fix: Some(FixSuggestion(description: "使用 C 兼容布尔")))
    m["E1420"] = ErrorMeta(code: "E1420", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "枚举在 C 侧大小不确定", fix: Some(FixSuggestion(description: "指定枚举 repr")))
    m["E1421"] = ErrorMeta(code: "E1421", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "FFI 接收到空指针但类型非可空", fix: Some(FixSuggestion(description: "检查 C 侧返回")))
    m["E1422"] = ErrorMeta(code: "E1422", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "宽字符（wchar）宽度不匹配", fix: Some(FixSuggestion(description: "使用固定宽度字符类型")))
    m["E1423"] = ErrorMeta(code: "E1423", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "long 类型宽度在平台上不一致", fix: Some(FixSuggestion(description: "使用定宽整数")))
    m["E1424"] = ErrorMeta(code: "E1424", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "结构体按值传递 ABI 不匹配", fix: Some(FixSuggestion(description: "改为指针传递")))
    m["E1425"] = ErrorMeta(code: "E1425", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "FFI 边界展开（unwind）约定冲突", fix: Some(FixSuggestion(description: "统一展开策略")))
    m["E1426"] = ErrorMeta(code: "E1426", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "向量类型 ABI 不匹配", fix: Some(FixSuggestion(description: "使用标量或对齐向量")))
    m["E1427"] = ErrorMeta(code: "E1427", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "复数类型 ABI 不兼容", fix: Some(FixSuggestion(description: "使用结构体表示复数")))
    m["E1428"] = ErrorMeta(code: "E1428", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "位域（bitfield）布局跨语言不一致", fix: Some(FixSuggestion(description: "手动打包位域")))
    m["E1429"] = ErrorMeta(code: "E1429", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "va_list 类型在 FFI 中不可用", fix: Some(FixSuggestion(description: "避免传递 va_list")))
    m["E1430"] = ErrorMeta(code: "E1430", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "线程局部在 FFI 边界不可见", fix: Some(FixSuggestion(description: "使用显式上下文传递")))
    m["E1431"] = ErrorMeta(code: "E1431", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "调用约定（cdecl/stdcall）不匹配", fix: Some(FixSuggestion(description: "标注正确调用约定")))
    m["E1432"] = ErrorMeta(code: "E1432", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "非 POD 类型跨越 FFI 边界", fix: Some(FixSuggestion(description: "仅传递 POD 类型")))
    m["E1433"] = ErrorMeta(code: "E1433", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "FFI 拥有对象析构责任不清导致泄漏", fix: Some(FixSuggestion(description: "明确所有权")))
    m["E1434"] = ErrorMeta(code: "E1434", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "FFI 回调生命周期短于注册方", fix: Some(FixSuggestion(description: "延长回调所有权")))
    m["E1435"] = ErrorMeta(code: "E1435", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "FFI 资源未释放", fix: Some(FixSuggestion(description: "在边界释放资源")))
    m["E1436"] = ErrorMeta(code: "E1436", category: ErrorCategory.Abi, severity: Severity.Warning,
        template: "在 FFI 中使用信号不安全操作", fix: Some(FixSuggestion(description: "改用安全替代")))
    m["E1437"] = ErrorMeta(code: "E1437", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "FFI 跨越 setjmp/longjmp 破坏栈", fix: Some(FixSuggestion(description: "避免跨边界跳转")))
    m["E1438"] = ErrorMeta(code: "E1438", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "FFI 符号 comdat 选择冲突", fix: Some(FixSuggestion(description: "统一 comdat")))
    m["E1439"] = ErrorMeta(code: "E1439", category: ErrorCategory.Abi, severity: Severity.Error,
        template: "类型大小在两侧不一致", fix: Some(FixSuggestion(description: "检查类型定义")))
    m["E1440"] = ErrorMeta(code: "E1440", category: ErrorCategory.Abi, severity: Severity.Warning,
        template: "const 限定在 C 侧不一致", fix: Some(FixSuggestion(description: "统一 const 标注")))
    m["E5101"] = ErrorMeta(code: "E5101", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "线程创建失败：{reason}", fix: Some(FixSuggestion(description: "检查系统线程上限")))
    m["E5102"] = ErrorMeta(code: "E5102", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "线程数量超过上限：{limit}", fix: Some(FixSuggestion(description: "复用线程池")))
    m["E5103"] = ErrorMeta(code: "E5103", category: ErrorCategory.Concurrency, severity: Severity.Fatal,
        template: "检测到数据竞争（data race）", fix: Some(FixSuggestion(description: "使用同步原语保护共享数据")))
    m["E5104"] = ErrorMeta(code: "E5104", category: ErrorCategory.Concurrency, severity: Severity.Fatal,
        template: "检测到死锁", fix: Some(FixSuggestion(description: "调整加锁顺序")))
    m["E5105"] = ErrorMeta(code: "E5105", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "锁因持有者 panic 而中毒（poisoned）", fix: Some(FixSuggestion(description: "处理中毒锁")))
    m["E5106"] = ErrorMeta(code: "E5106", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "条件变量伪唤醒（spurious wakeup）未处理", fix: Some(FixSuggestion(description: "在循环中检查条件")))
    m["E5107"] = ErrorMeta(code: "E5107", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "向已关闭的信道发送消息", fix: Some(FixSuggestion(description: "发送前检查信道状态")))
    m["E5108"] = ErrorMeta(code: "E5108", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "信道发送永久阻塞（无接收方）", fix: Some(FixSuggestion(description: "使用带超时的发送")))
    m["E5109"] = ErrorMeta(code: "E5109", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "从空信道接收阻塞", fix: Some(FixSuggestion(description: "检查接收时机")))
    m["E5110"] = ErrorMeta(code: "E5110", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "actor 邮箱已满", fix: Some(FixSuggestion(description: "限流或增大邮箱")))
    m["E5111"] = ErrorMeta(code: "E5111", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "向已停止的 actor 发送消息", fix: Some(FixSuggestion(description: "检查 actor 生命周期")))
    m["E5112"] = ErrorMeta(code: "E5112", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "Future 未被轮询（未驱动执行）", fix: Some(FixSuggestion(description: "将 Future 交给执行器")))
    m["E5113"] = ErrorMeta(code: "E5113", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "向已关闭的执行器提交任务", fix: Some(FixSuggestion(description: "检查执行器生命周期")))
    m["E5114"] = ErrorMeta(code: "E5114", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "在非 async 上下文中使用 await", fix: Some(FixSuggestion(description: "将函数声明为 async")))
    m["E5115"] = ErrorMeta(code: "E5115", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "async 递归导致栈溢出（未使用 Box）", fix: Some(FixSuggestion(description: "使用 BoxFuture 包装")))
    m["E5116"] = ErrorMeta(code: "E5116", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "协程在非挂起点被挂起", fix: Some(FixSuggestion(description: "仅在合法挂起点挂起")))
    m["E5117"] = ErrorMeta(code: "E5117", category: ErrorCategory.Concurrency, severity: Severity.Warning,
        template: "协程泄漏（未结束且未被引用）", fix: Some(FixSuggestion(description: "确保协程完成或被取消")))
    m["E5118"] = ErrorMeta(code: "E5118", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "原子操作误用（非原子访问/内存序错误）", fix: Some(FixSuggestion(description: "统一使用原子操作")))
    m["E5119"] = ErrorMeta(code: "E5119", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "指定的内存序（memory order）非法", fix: Some(FixSuggestion(description: "使用合法内存序")))
    m["E5120"] = ErrorMeta(code: "E5120", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "读写锁死锁", fix: Some(FixSuggestion(description: "避免写者饥饿")))
    m["E5121"] = ErrorMeta(code: "E5121", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "同一线程重复加锁（不可重入）", fix: Some(FixSuggestion(description: "使用可重入锁")))
    m["E5122"] = ErrorMeta(code: "E5122", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "屏障（barrier）等待数量不匹配", fix: Some(FixSuggestion(description: "统一参与者数量")))
    m["E5123"] = ErrorMeta(code: "E5123", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "信号量（semaphore）释放超过初始值", fix: Some(FixSuggestion(description: "检查释放逻辑")))
    m["E5124"] = ErrorMeta(code: "E5124", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "一次性初始化因 panic 永久失败", fix: Some(FixSuggestion(description: "修复初始化逻辑")))
    m["E5125"] = ErrorMeta(code: "E5125", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "线程局部变量跨线程访问非法", fix: Some(FixSuggestion(description: "使用线程安全存储")))
    m["E5126"] = ErrorMeta(code: "E5126", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "静态初始化期间发生竞争", fix: Some(FixSuggestion(description: "使用安全惰性初始化")))
    m["E5127"] = ErrorMeta(code: "E5127", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "unpark 信号在 park 前丢失", fix: Some(FixSuggestion(description: "使用条件变量替代")))
    m["E5128"] = ErrorMeta(code: "E5128", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "任务被取消但资源未清理", fix: Some(FixSuggestion(description: "在取消路径释放资源")))
    m["E5129"] = ErrorMeta(code: "E5129", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "设置线程亲和性失败", fix: Some(FixSuggestion(description: "检查系统支持")))
    m["E5130"] = ErrorMeta(code: "E5130", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "协程/线程栈大小非法", fix: Some(FixSuggestion(description: "使用合法栈大小")))
    m["E5131"] = ErrorMeta(code: "E5131", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "async Drop 形成循环", fix: Some(FixSuggestion(description: "打破 Drop 循环")))
    m["E5132"] = ErrorMeta(code: "E5132", category: ErrorCategory.Concurrency, severity: Severity.Warning,
        template: "执行器线程饥饿", fix: Some(FixSuggestion(description: "调整任务调度")))
    m["E5133"] = ErrorMeta(code: "E5133", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "select! 多臂类型冲突", fix: Some(FixSuggestion(description: "统一臂类型")))
    m["E5134"] = ErrorMeta(code: "E5134", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "容量为 0 的信道使用不当", fix: Some(FixSuggestion(description: "使用带缓冲或 rendezvous")))
    m["E5135"] = ErrorMeta(code: "E5135", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "加锁顺序倒置导致潜在死锁", fix: Some(FixSuggestion(description: "统一全局加锁顺序")))
    m["E5136"] = ErrorMeta(code: "E5136", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "跨线程捕获了非 Send 值", fix: Some(FixSuggestion(description: "仅捕获 Send 值")))
    m["E5137"] = ErrorMeta(code: "E5137", category: ErrorCategory.Concurrency, severity: Severity.Error,
        template: "跨线程共享了非 Sync 值", fix: Some(FixSuggestion(description: "使用同步包装")))
    m["E5138"] = ErrorMeta(code: "E5138", category: ErrorCategory.Concurrency, severity: Severity.Fatal,
        template: "看门狗（watchdog）超时杀进程", fix: Some(FixSuggestion(description: "检查任务耗时")))
    m["E5139"] = ErrorMeta(code: "E5139", category: ErrorCategory.Concurrency, severity: Severity.Warning,
        template: "当前平台不支持 CPU 亲和性", fix: Some(FixSuggestion(description: "移除亲和性设置")))
    m["E5140"] = ErrorMeta(code: "E5140", category: ErrorCategory.Concurrency, severity: Severity.Fatal,
        template: "协程栈耗尽", fix: Some(FixSuggestion(description: "增大协程栈或减小帧")))
    m["E5141"] = ErrorMeta(code: "E5141", category: ErrorCategory.Concurrency, severity: Severity.Warning,
        template: "工作窃取（work-stealing）失衡", fix: Some(FixSuggestion(description: "调整调度策略")))
    m["E5201"] = ErrorMeta(code: "E5201", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "内存分配失败（OOM）", fix: Some(FixSuggestion(description: "释放内存或增大配额")))
    m["E5202"] = ErrorMeta(code: "E5202", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "检测到重复释放（double free）", fix: Some(FixSuggestion(description: "确保每个分配释放一次")))
    m["E5203"] = ErrorMeta(code: "E5203", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "释放后使用（use-after-free）", fix: Some(FixSuggestion(description: "避免使用已释放内存")))
    m["E5204"] = ErrorMeta(code: "E5204", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "堆内存损坏", fix: Some(FixSuggestion(description: "检查越界写入")))
    m["E5205"] = ErrorMeta(code: "E5205", category: ErrorCategory.Mem, severity: Severity.Warning,
        template: "检测到内存泄漏（{bytes} 字节）", fix: Some(FixSuggestion(description: "释放未释放的对象")))
    m["E5206"] = ErrorMeta(code: "E5206", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "对非堆地址调用释放", fix: Some(FixSuggestion(description: "仅释放堆分配地址")))
    m["E5207"] = ErrorMeta(code: "E5207", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "未对齐的内存访问", fix: Some(FixSuggestion(description: "使用对齐类型/地址")))
    m["E5208"] = ErrorMeta(code: "E5208", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "空指针解引用", fix: Some(FixSuggestion(description: "使用前判空")))
    m["E5209"] = ErrorMeta(code: "E5209", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "缓冲区溢出（写越界）", fix: Some(FixSuggestion(description: "检查边界")))
    m["E5210"] = ErrorMeta(code: "E5210", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "缓冲区下溢（写越界）", fix: Some(FixSuggestion(description: "检查索引")))
    m["E5211"] = ErrorMeta(code: "E5211", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "栈溢出", fix: Some(FixSuggestion(description: "减少递归深度")))
    m["E5212"] = ErrorMeta(code: "E5212", category: ErrorCategory.Mem, severity: Severity.Warning,
        template: "垃圾回收停顿过长（{ms} ms）", fix: Some(FixSuggestion(description: "调整 GC 策略")))
    m["E5213"] = ErrorMeta(code: "E5213", category: ErrorCategory.Mem, severity: Severity.Error,
        template: "GC 代际晋升失败", fix: Some(FixSuggestion(description: "检查对象可达性")))
    m["E5214"] = ErrorMeta(code: "E5214", category: ErrorCategory.Mem, severity: Severity.Warning,
        template: "GC 产生过多碎片", fix: Some(FixSuggestion(description: "使用压缩式 GC")))
    m["E5215"] = ErrorMeta(code: "E5215", category: ErrorCategory.Mem, severity: Severity.Warning,
        template: "GC 无法回收循环引用", fix: Some(FixSuggestion(description: "打破循环引用")))
    m["E5216"] = ErrorMeta(code: "E5216", category: ErrorCategory.Mem, severity: Severity.Error,
        template: "终结器（finalizer）死锁", fix: Some(FixSuggestion(description: "避免终结器中加锁")))
    m["E5217"] = ErrorMeta(code: "E5217", category: ErrorCategory.Mem, severity: Severity.Warning,
        template: "终结器延迟执行导致资源紧张", fix: Some(FixSuggestion(description: "显式释放资源")))
    m["E5218"] = ErrorMeta(code: "E5218", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "分配器与释放器不匹配", fix: Some(FixSuggestion(description: "统一分配/释放侧")))
    m["E5219"] = ErrorMeta(code: "E5219", category: ErrorCategory.Mem, severity: Severity.Error,
        template: "自定义分配器返回空", fix: Some(FixSuggestion(description: "检查分配器实现")))
    m["E5220"] = ErrorMeta(code: "E5220", category: ErrorCategory.Mem, severity: Severity.Error,
        template: "请求的对齐超过分配器上限", fix: Some(FixSuggestion(description: "降低对齐要求")))
    m["E5221"] = ErrorMeta(code: "E5221", category: ErrorCategory.Mem, severity: Severity.Warning,
        template: "分配了零大小对象", fix: Some(FixSuggestion(description: "避免零大小分配")))
    m["E5222"] = ErrorMeta(code: "E5222", category: ErrorCategory.Mem, severity: Severity.Error,
        template: "realloc 缩小导致数据丢失", fix: Some(FixSuggestion(description: "先复制再缩小")))
    m["E5223"] = ErrorMeta(code: "E5223", category: ErrorCategory.Mem, severity: Severity.Error,
        template: "内存映射（mmap）失败", fix: Some(FixSuggestion(description: "检查映射大小与权限")))
    m["E5224"] = ErrorMeta(code: "E5224", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "触发了保护页（guard page）", fix: Some(FixSuggestion(description: "检查栈/堆边界")))
    m["E5225"] = ErrorMeta(code: "E5225", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "悬垂指针访问", fix: Some(FixSuggestion(description: "避免使用已失效指针")))
    m["E5226"] = ErrorMeta(code: "E5226", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "野指针访问（未初始化指针）", fix: Some(FixSuggestion(description: "初始化指针后再使用")))
    m["E5227"] = ErrorMeta(code: "E5227", category: ErrorCategory.Mem, severity: Severity.Warning,
        template: "引用计数循环导致泄漏", fix: Some(FixSuggestion(description: "改用弱引用打破循环")))
    m["E5228"] = ErrorMeta(code: "E5228", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "Arc 强引用计数异常归零", fix: Some(FixSuggestion(description: "检查并发计数")))
    m["E5229"] = ErrorMeta(code: "E5229", category: ErrorCategory.Mem, severity: Severity.Warning,
        template: "弱引用升级（upgrade）失败", fix: Some(FixSuggestion(description: "处理升级失败分支")))
    m["E5230"] = ErrorMeta(code: "E5230", category: ErrorCategory.Mem, severity: Severity.Error,
        template: "内存池（arena）耗尽", fix: Some(FixSuggestion(description: "增大池或复用")))
    m["E5231"] = ErrorMeta(code: "E5231", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "内存池内重复释放", fix: Some(FixSuggestion(description: "确保每个槽位释放一次")))
    m["E5232"] = ErrorMeta(code: "E5232", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "栈展开时内存状态损坏", fix: Some(FixSuggestion(description: "检查异常安全")))
    m["E5233"] = ErrorMeta(code: "E5233", category: ErrorCategory.Mem, severity: Severity.Error,
        template: "移动了未初始化内存", fix: Some(FixSuggestion(description: "先初始化再移动")))
    m["E5234"] = ErrorMeta(code: "E5234", category: ErrorCategory.Mem, severity: Severity.Error,
        template: "读取了未初始化内存", fix: Some(FixSuggestion(description: "先初始化再读取")))
    m["E5235"] = ErrorMeta(code: "E5235", category: ErrorCategory.Mem, severity: Severity.Warning,
        template: "结构体内存填充（padding）含敏感数据", fix: Some(FixSuggestion(description: "显式清零填充")))
    m["E5236"] = ErrorMeta(code: "E5236", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "内存标签（tag）校验失败（硬件内存安全）", fix: Some(FixSuggestion(description: "检查标签一致性")))
    m["E5237"] = ErrorMeta(code: "E5237", category: ErrorCategory.Mem, severity: Severity.Warning,
        template: "大页（hugepage）分配失败", fix: Some(FixSuggestion(description: "回退常规页")))
    m["E5238"] = ErrorMeta(code: "E5238", category: ErrorCategory.Mem, severity: Severity.Error,
        template: "NUMA 绑定失败", fix: Some(FixSuggestion(description: "检查 NUMA 节点")))
    m["E5239"] = ErrorMeta(code: "E5239", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "内存过量提交超过限制", fix: Some(FixSuggestion(description: "减少内存使用")))
    m["E5240"] = ErrorMeta(code: "E5240", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "GC 根集合丢失导致误回收", fix: Some(FixSuggestion(description: "保留根引用")))
    m["E5241"] = ErrorMeta(code: "E5241", category: ErrorCategory.Mem, severity: Severity.Fatal,
        template: "分配器内部死锁", fix: Some(FixSuggestion(description: "避免分配时持锁")))
}

/// 填充错误码元数据第 5 组（Os .. Build），共 5 个类别。
func buildMetaPart5(m: HashMap<String, ErrorMeta>) {
    m["E5301"] = ErrorMeta(code: "E5301", category: ErrorCategory.Os, severity: Severity.Error,
        template: "文件未找到：{path}", fix: Some(FixSuggestion(description: "检查文件路径")))
    m["E5302"] = ErrorMeta(code: "E5302", category: ErrorCategory.Os, severity: Severity.Error,
        template: "权限不足：{path}", fix: Some(FixSuggestion(description: "调整文件/目录权限")))
    m["E5303"] = ErrorMeta(code: "E5303", category: ErrorCategory.Os, severity: Severity.Error,
        template: "I/O 错误：{reason}", fix: Some(FixSuggestion(description: "重试或检查设备")))
    m["E5304"] = ErrorMeta(code: "E5304", category: ErrorCategory.Os, severity: Severity.Error,
        template: "管道（pipe）已断开", fix: Some(FixSuggestion(description: "处理写入断开")))
    m["E5305"] = ErrorMeta(code: "E5305", category: ErrorCategory.Os, severity: Severity.Error,
        template: "打开文件数超过系统上限", fix: Some(FixSuggestion(description: "关闭不需要的文件描述符")))
    m["E5306"] = ErrorMeta(code: "E5306", category: ErrorCategory.Os, severity: Severity.Error,
        template: "磁盘空间不足", fix: Some(FixSuggestion(description: "清理磁盘或扩容")))
    m["E5307"] = ErrorMeta(code: "E5307", category: ErrorCategory.Os, severity: Severity.Error,
        template: "目标进程不存在", fix: Some(FixSuggestion(description: "检查进程 ID")))
    m["E5308"] = ErrorMeta(code: "E5308", category: ErrorCategory.Os, severity: Severity.Error,
        template: "进程启动失败：{reason}", fix: Some(FixSuggestion(description: "检查命令与权限")))
    m["E5309"] = ErrorMeta(code: "E5309", category: ErrorCategory.Os, severity: Severity.Fatal,
        template: "收到终止信号：{sig}", fix: Some(FixSuggestion(description: "处理信号或忽略")))
    m["E5310"] = ErrorMeta(code: "E5310", category: ErrorCategory.Os, severity: Severity.Error,
        template: "操作超时", fix: Some(FixSuggestion(description: "增大超时或优化耗时")))
    m["E5311"] = ErrorMeta(code: "E5311", category: ErrorCategory.Os, severity: Severity.Error,
        template: "超过系统资源限制", fix: Some(FixSuggestion(description: "调整系统限制")))
    m["E5312"] = ErrorMeta(code: "E5312", category: ErrorCategory.Os, severity: Severity.Error,
        template: "网络地址已被占用：{addr}", fix: Some(FixSuggestion(description: "更换端口")))
    m["E5313"] = ErrorMeta(code: "E5313", category: ErrorCategory.Os, severity: Severity.Error,
        template: "连接被拒绝", fix: Some(FixSuggestion(description: "检查服务状态")))
    m["E5314"] = ErrorMeta(code: "E5314", category: ErrorCategory.Os, severity: Severity.Error,
        template: "网络不可达", fix: Some(FixSuggestion(description: "检查网络配置")))
    m["E5315"] = ErrorMeta(code: "E5315", category: ErrorCategory.Os, severity: Severity.Error,
        template: "域名解析失败：{host}", fix: Some(FixSuggestion(description: "检查 DNS 配置")))
    m["E5316"] = ErrorMeta(code: "E5316", category: ErrorCategory.Os, severity: Severity.Error,
        template: "环境变量 {var} 缺失", fix: Some(FixSuggestion(description: "设置环境变量")))
    m["E5317"] = ErrorMeta(code: "E5317", category: ErrorCategory.Os, severity: Severity.Error,
        template: "环境变量 {var} 取值非法", fix: Some(FixSuggestion(description: "修正环境变量")))
    m["E5318"] = ErrorMeta(code: "E5318", category: ErrorCategory.Os, severity: Severity.Error,
        template: "工作目录不存在", fix: Some(FixSuggestion(description: "切换有效目录")))
    m["E5319"] = ErrorMeta(code: "E5319", category: ErrorCategory.Os, severity: Severity.Error,
        template: "符号链接形成循环", fix: Some(FixSuggestion(description: "断开链接循环")))
    m["E5320"] = ErrorMeta(code: "E5320", category: ErrorCategory.Os, severity: Severity.Error,
        template: "文件系统只读", fix: Some(FixSuggestion(description: "使用可写文件系统")))
    m["E5321"] = ErrorMeta(code: "E5321", category: ErrorCategory.Os, severity: Severity.Error,
        template: "磁盘配额超限", fix: Some(FixSuggestion(description: "清理或申请配额")))
    m["E5322"] = ErrorMeta(code: "E5322", category: ErrorCategory.Os, severity: Severity.Error,
        template: "路径含非法 UTF-8", fix: Some(FixSuggestion(description: "使用合法路径编码")))
    m["E5323"] = ErrorMeta(code: "E5323", category: ErrorCategory.Os, severity: Severity.Error,
        template: "设置线程优先级失败", fix: Some(FixSuggestion(description: "检查系统权限")))
    m["E5324"] = ErrorMeta(code: "E5324", category: ErrorCategory.Os, severity: Severity.Error,
        template: "系统时钟读取失败", fix: Some(FixSuggestion(description: "检查时钟源")))
    m["E5325"] = ErrorMeta(code: "E5325", category: ErrorCategory.Os, severity: Severity.Error,
        template: "系统可用内存不足", fix: Some(FixSuggestion(description: "释放内存")))
    m["E5326"] = ErrorMeta(code: "E5326", category: ErrorCategory.Os, severity: Severity.Error,
        template: "文件锁被其他进程持有", fix: Some(FixSuggestion(description: "释放锁或重试")))
    m["E5327"] = ErrorMeta(code: "E5327", category: ErrorCategory.Os, severity: Severity.Error,
        template: "共享内存创建失败", fix: Some(FixSuggestion(description: "检查共享内存配置")))
    m["E5328"] = ErrorMeta(code: "E5328", category: ErrorCategory.Os, severity: Severity.Error,
        template: "内存映射执行权限被拒", fix: Some(FixSuggestion(description: "调整映射权限")))
    m["E5329"] = ErrorMeta(code: "E5329", category: ErrorCategory.Os, severity: Severity.Error,
        template: "系统调用被 seccomp 拦截", fix: Some(FixSuggestion(description: "调整沙箱策略")))
    m["E5330"] = ErrorMeta(code: "E5330", category: ErrorCategory.Os, severity: Severity.Error,
        template: "缺少系统能力（capability）", fix: Some(FixSuggestion(description: "授予所需能力")))
    m["E5331"] = ErrorMeta(code: "E5331", category: ErrorCategory.Os, severity: Severity.Error,
        template: "chroot 切换根目录失败", fix: Some(FixSuggestion(description: "检查目录与权限")))
    m["E5332"] = ErrorMeta(code: "E5332", category: ErrorCategory.Os, severity: Severity.Error,
        template: "挂载（mount）失败", fix: Some(FixSuggestion(description: "检查挂载点")))
    m["E5333"] = ErrorMeta(code: "E5333", category: ErrorCategory.Os, severity: Severity.Error,
        template: "设备不存在：{dev}", fix: Some(FixSuggestion(description: "检查设备路径")))
    m["E5334"] = ErrorMeta(code: "E5334", category: ErrorCategory.Os, severity: Severity.Error,
        template: "设备忙", fix: Some(FixSuggestion(description: "稍后重试")))
    m["E5335"] = ErrorMeta(code: "E5335", category: ErrorCategory.Os, severity: Severity.Error,
        template: "文件描述符无效", fix: Some(FixSuggestion(description: "检查描述符生命周期")))
    m["E5336"] = ErrorMeta(code: "E5336", category: ErrorCategory.Os, severity: Severity.Error,
        template: "I/O 多路复用（poll/epoll）失败", fix: Some(FixSuggestion(description: "检查事件源")))
    m["E5337"] = ErrorMeta(code: "E5337", category: ErrorCategory.Os, severity: Severity.Error,
        template: "管道缓冲区已满", fix: Some(FixSuggestion(description: "消费端尽快读取")))
    m["E5338"] = ErrorMeta(code: "E5338", category: ErrorCategory.Os, severity: Severity.Error,
        template: "当前环境不支持 fork", fix: Some(FixSuggestion(description: "避免使用 fork")))
    m["E5339"] = ErrorMeta(code: "E5339", category: ErrorCategory.Os, severity: Severity.Error,
        template: "操作已退出进程", fix: Some(FixSuggestion(description: "检查进程状态")))
    m["E5340"] = ErrorMeta(code: "E5340", category: ErrorCategory.Os, severity: Severity.Error,
        template: "用户命名空间创建失败", fix: Some(FixSuggestion(description: "检查命名空间支持")))
    m["E5341"] = ErrorMeta(code: "E5341", category: ErrorCategory.Os, severity: Severity.Error,
        template: "不支持的文件系统类型", fix: Some(FixSuggestion(description: "使用受支持文件系统")))
    m["E6001"] = ErrorMeta(code: "E6001", category: ErrorCategory.Lsp, severity: Severity.Error,
        template: "LSP 请求非法：{method}", fix: Some(FixSuggestion(description: "检查客户端请求格式")))
    m["E6002"] = ErrorMeta(code: "E6002", category: ErrorCategory.Lsp, severity: Severity.Error,
        template: "LSP 文档未找到：{uri}", fix: Some(FixSuggestion(description: "重新打开文档")))
    m["E6003"] = ErrorMeta(code: "E6003", category: ErrorCategory.Lsp, severity: Severity.Error,
        template: "LSP 位置超出文档范围", fix: Some(FixSuggestion(description: "检查行/列范围")))
    m["E6004"] = ErrorMeta(code: "E6004", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "客户端不支持该能力：{cap}", fix: Some(FixSuggestion(description: "升级客户端")))
    m["E6005"] = ErrorMeta(code: "E6005", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "诊断结果过期（文档已变更）", fix: Some(FixSuggestion(description: "重新触发分析")))
    m["E6006"] = ErrorMeta(code: "E6006", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "语义高亮（semantic tokens）生成失败", fix: Some(FixSuggestion(description: "检查语法树")))
    m["E6007"] = ErrorMeta(code: "E6007", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "补全（completion）生成失败", fix: Some(FixSuggestion(description: "检查上下文")))
    m["E6008"] = ErrorMeta(code: "E6008", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "悬停（hover）信息生成失败", fix: Some(FixSuggestion(description: "检查符号解析")))
    m["E6009"] = ErrorMeta(code: "E6009", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "跳转定义目标未找到", fix: Some(FixSuggestion(description: "确认符号已定义")))
    m["E6010"] = ErrorMeta(code: "E6010", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "引用查找失败", fix: Some(FixSuggestion(description: "检查索引")))
    m["E6011"] = ErrorMeta(code: "E6011", category: ErrorCategory.Lsp, severity: Severity.Error,
        template: "重命名（rename）失败：{name}", fix: Some(FixSuggestion(description: "检查跨文件引用")))
    m["E6012"] = ErrorMeta(code: "E6012", category: ErrorCategory.Lsp, severity: Severity.Error,
        template: "格式化（formatting）失败", fix: Some(FixSuggestion(description: "检查语法合法性")))
    m["E6013"] = ErrorMeta(code: "E6013", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "快速修复（code action）生成失败", fix: Some(FixSuggestion(description: "检查可用修复")))
    m["E6014"] = ErrorMeta(code: "E6014", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "内嵌提示（inlay hint）生成失败", fix: Some(FixSuggestion(description: "检查类型信息")))
    m["E6015"] = ErrorMeta(code: "E6015", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "折叠（folding）范围计算失败", fix: Some(FixSuggestion(description: "检查语法结构")))
    m["E6016"] = ErrorMeta(code: "E6016", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "文档链接生成失败", fix: Some(FixSuggestion(description: "检查链接目标")))
    m["E6017"] = ErrorMeta(code: "E6017", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "工作区符号检索失败", fix: Some(FixSuggestion(description: "检查索引完整性")))
    m["E6018"] = ErrorMeta(code: "E6018", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "LSP 配置缺失：{key}", fix: Some(FixSuggestion(description: "补全客户端配置")))
    m["E6019"] = ErrorMeta(code: "E6019", category: ErrorCategory.Lsp, severity: Severity.Error,
        template: "语言服务器内部异常", fix: Some(FixSuggestion(description: "重启语言服务器")))
    m["E6020"] = ErrorMeta(code: "E6020", category: ErrorCategory.Lsp, severity: Severity.Error,
        template: "LSP 协议版本不匹配", fix: Some(FixSuggestion(description: "对齐协议版本")))
    m["E6021"] = ErrorMeta(code: "E6021", category: ErrorCategory.Lsp, severity: Severity.Error,
        template: "文档编码与服务器不一致", fix: Some(FixSuggestion(description: "统一 UTF-8 编码")))
    m["E6022"] = ErrorMeta(code: "E6022", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "行结束符不一致导致位置偏移", fix: Some(FixSuggestion(description: "统一行结束符")))
    m["E6023"] = ErrorMeta(code: "E6023", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "文档过大超过 LSP 处理上限", fix: Some(FixSuggestion(description: "拆分文档")))
    m["E6024"] = ErrorMeta(code: "E6024", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "防抖（debounce）期间跳过分析", fix: Some(FixSuggestion(description: "稍后重试")))
    m["E6025"] = ErrorMeta(code: "E6025", category: ErrorCategory.Lsp, severity: Severity.Error,
        template: "项目索引损坏", fix: Some(FixSuggestion(description: "重建索引")))
    m["E6026"] = ErrorMeta(code: "E6026", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "分析耗时过长触发超时", fix: Some(FixSuggestion(description: "简化分析范围")))
    m["E6027"] = ErrorMeta(code: "E6027", category: ErrorCategory.Lsp, severity: Severity.Error,
        template: "诊断引用的源码文件缺失", fix: Some(FixSuggestion(description: "确认文件路径")))
    m["E6028"] = ErrorMeta(code: "E6028", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "收到未知诊断码：{code}", fix: Some(FixSuggestion(description: "升级诊断源")))
    m["E6029"] = ErrorMeta(code: "E6029", category: ErrorCategory.Lsp, severity: Severity.Error,
        template: "LSP JSON-RPC 解析失败", fix: Some(FixSuggestion(description: "检查传输层")))
    m["E6030"] = ErrorMeta(code: "E6030", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "请求被取消（客户端关闭）", fix: Some(FixSuggestion(description: "忽略即可")))
    m["E6031"] = ErrorMeta(code: "E6031", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "语言服务器崩溃后恢复中", fix: Some(FixSuggestion(description: "等待恢复完成")))
    m["E6032"] = ErrorMeta(code: "E6032", category: ErrorCategory.Lsp, severity: Severity.Error,
        template: "工作区文件夹未注册", fix: Some(FixSuggestion(description: "注册工作区")))
    m["E6033"] = ErrorMeta(code: "E6033", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "文件监视（watcher）失败", fix: Some(FixSuggestion(description: "检查文件系统事件")))
    m["E6034"] = ErrorMeta(code: "E6034", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "重复诊断（已去重）", fix: Some(FixSuggestion(description: "检查诊断源")))
    m["E6035"] = ErrorMeta(code: "E6035", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "遥测被禁用，无法上报", fix: Some(FixSuggestion(description: "启用遥测")))
    m["E6036"] = ErrorMeta(code: "E6036", category: ErrorCategory.Lsp, severity: Severity.Error,
        template: "客户端初始化握手失败", fix: Some(FixSuggestion(description: "检查初始化参数")))
    m["E6037"] = ErrorMeta(code: "E6037", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "进度（progress）通知失败", fix: Some(FixSuggestion(description: "检查进度令牌")))
    m["E6038"] = ErrorMeta(code: "E6038", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "联动编辑（linked editing）失败", fix: Some(FixSuggestion(description: "检查配对符号")))
    m["E6039"] = ErrorMeta(code: "E6039", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "调用层级（call hierarchy）失败", fix: Some(FixSuggestion(description: "检查调用图")))
    m["E6040"] = ErrorMeta(code: "E6040", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "类型层级（type hierarchy）失败", fix: Some(FixSuggestion(description: "检查继承图")))
    m["E6041"] = ErrorMeta(code: "E6041", category: ErrorCategory.Lsp, severity: Severity.Warning,
        template: "文档颜色（color）提取失败", fix: Some(FixSuggestion(description: "检查颜色字面量")))
    m["E6101"] = ErrorMeta(code: "E6101", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "增量编译缓存缺失，回退全量", fix: Some(FixSuggestion(description: "首次构建正常现象")))
    m["E6102"] = ErrorMeta(code: "E6102", category: ErrorCategory.Incremental, severity: Severity.Error,
        template: "增量缓存损坏", fix: Some(FixSuggestion(description: "清理增量缓存")))
    m["E6103"] = ErrorMeta(code: "E6103", category: ErrorCategory.Incremental, severity: Severity.Error,
        template: "缓存版本与编译器不匹配", fix: Some(FixSuggestion(description: "清理并重建缓存")))
    m["E6104"] = ErrorMeta(code: "E6104", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "依赖文件（.d）过期", fix: Some(FixSuggestion(description: "重新生成依赖")))
    m["E6105"] = ErrorMeta(code: "E6105", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "输入哈希不匹配，触发重编", fix: Some(FixSuggestion(description: "检查源文件变更")))
    m["E6106"] = ErrorMeta(code: "E6106", category: ErrorCategory.Incremental, severity: Severity.Error,
        template: "指纹（fingerprint）计算失败", fix: Some(FixSuggestion(description: "检查文件属性")))
    m["E6107"] = ErrorMeta(code: "E6107", category: ErrorCategory.Incremental, severity: Severity.Error,
        template: "增量查询形成循环", fix: Some(FixSuggestion(description: "打破查询循环")))
    m["E6108"] = ErrorMeta(code: "E6108", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "增量节点被标记为脏需重算", fix: Some(FixSuggestion(description: "重新分析该节点")))
    m["E6109"] = ErrorMeta(code: "E6109", category: ErrorCategory.Incremental, severity: Severity.Error,
        template: "增量状态序列化失败", fix: Some(FixSuggestion(description: "检查缓存目录权限")))
    m["E6110"] = ErrorMeta(code: "E6110", category: ErrorCategory.Incremental, severity: Severity.Error,
        template: "增量状态反序列化失败", fix: Some(FixSuggestion(description: "清理缓存重建")))
    m["E6111"] = ErrorMeta(code: "E6111", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "缓存条目被驱逐（容量限制）", fix: Some(FixSuggestion(description: "增大缓存或重编")))
    m["E6112"] = ErrorMeta(code: "E6112", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "误判为最新（实际需重编）", fix: Some(FixSuggestion(description: "强制重编一次")))
    m["E6113"] = ErrorMeta(code: "E6113", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "一处变更引发大面积重编", fix: Some(FixSuggestion(description: "缩小变更范围")))
    m["E6114"] = ErrorMeta(code: "E6114", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "缓存锁竞争导致变慢", fix: Some(FixSuggestion(description: "减少并发写入")))
    m["E6115"] = ErrorMeta(code: "E6115", category: ErrorCategory.Incremental, severity: Severity.Error,
        template: "缓存目录无写入权限", fix: Some(FixSuggestion(description: "修正缓存目录权限")))
    m["E6116"] = ErrorMeta(code: "E6116", category: ErrorCategory.Incremental, severity: Severity.Error,
        template: "缓存磁盘空间不足", fix: Some(FixSuggestion(description: "清理或扩容")))
    m["E6117"] = ErrorMeta(code: "E6117", category: ErrorCategory.Incremental, severity: Severity.Error,
        template: "并发写入缓存冲突", fix: Some(FixSuggestion(description: "串行化缓存写入")))
    m["E6118"] = ErrorMeta(code: "E6118", category: ErrorCategory.Incremental, severity: Severity.Error,
        template: "模块元数据与缓存不一致", fix: Some(FixSuggestion(description: "清理缓存")))
    m["E6119"] = ErrorMeta(code: "E6119", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "配置禁用增量编译", fix: Some(FixSuggestion(description: "启用增量编译")))
    m["E6120"] = ErrorMeta(code: "E6120", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "编译环境变更导致缓存失效", fix: Some(FixSuggestion(description: "稳定编译环境")))
    m["E6121"] = ErrorMeta(code: "E6121", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "编译选项变更导致缓存失效", fix: Some(FixSuggestion(description: "保持编译选项稳定")))
    m["E6122"] = ErrorMeta(code: "E6122", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "目标平台变更导致缓存失效", fix: Some(FixSuggestion(description: "清理跨目标缓存")))
    m["E6123"] = ErrorMeta(code: "E6123", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "指纹盐（salt）变更", fix: Some(FixSuggestion(description: "清理缓存")))
    m["E6124"] = ErrorMeta(code: "E6124", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "增量节点数超过上限", fix: Some(FixSuggestion(description: "拆分编译单元")))
    m["E6125"] = ErrorMeta(code: "E6125", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "依赖图过大导致内存压力", fix: Some(FixSuggestion(description: "模块化拆分")))
    m["E6126"] = ErrorMeta(code: "E6126", category: ErrorCategory.Incremental, severity: Severity.Error,
        template: "缓存路径过长（系统限制）", fix: Some(FixSuggestion(description: "缩短项目路径")))
    m["E6127"] = ErrorMeta(code: "E6127", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "符号链接导致缓存命中错误", fix: Some(FixSuggestion(description: "使用真实路径")))
    m["E6128"] = ErrorMeta(code: "E6128", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "工具链版本变化使缓存失效", fix: Some(FixSuggestion(description: "清理缓存")))
    m["E6129"] = ErrorMeta(code: "E6129", category: ErrorCategory.Incremental, severity: Severity.Error,
        template: "增量子系统异常", fix: Some(FixSuggestion(description: "清理缓存并重试")))
    m["E6130"] = ErrorMeta(code: "E6130", category: ErrorCategory.Incremental, severity: Severity.Error,
        template: "增量查询栈溢出", fix: Some(FixSuggestion(description: "减少递归查询")))
    m["E6131"] = ErrorMeta(code: "E6131", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "缓存读取超时", fix: Some(FixSuggestion(description: "检查存储性能")))
    m["E6132"] = ErrorMeta(code: "E6132", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "持久化缓存加载缓慢", fix: Some(FixSuggestion(description: "优化缓存存储")))
    m["E6133"] = ErrorMeta(code: "E6133", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "全量标记为脏（罕见）", fix: Some(FixSuggestion(description: "触发全量重编")))
    m["E6134"] = ErrorMeta(code: "E6134", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "输入哈希冲突（极低概率）", fix: Some(FixSuggestion(description: "更换哈希策略")))
    m["E6135"] = ErrorMeta(code: "E6135", category: ErrorCategory.Incremental, severity: Severity.Error,
        template: "依赖追踪丢失", fix: Some(FixSuggestion(description: "重建依赖图")))
    m["E6136"] = ErrorMeta(code: "E6136", category: ErrorCategory.Incremental, severity: Severity.Error,
        template: "增量状态内存耗尽", fix: Some(FixSuggestion(description: "减小缓存规模")))
    m["E6137"] = ErrorMeta(code: "E6137", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "降级编译器导致缓存不可用", fix: Some(FixSuggestion(description: "清理旧缓存")))
    m["E6138"] = ErrorMeta(code: "E6138", category: ErrorCategory.Incremental, severity: Severity.Error,
        template: "缓存格式迁移失败", fix: Some(FixSuggestion(description: "清理并重建")))
    m["E6139"] = ErrorMeta(code: "E6139", category: ErrorCategory.Incremental, severity: Severity.Warning,
        template: "存在未追踪的输入导致误命中", fix: Some(FixSuggestion(description: "登记全部输入")))
    m["E6201"] = ErrorMeta(code: "E6201", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "包清单（manifest）未找到", fix: Some(FixSuggestion(description: "创建或定位 manifest")))
    m["E6202"] = ErrorMeta(code: "E6202", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "包清单解析失败：{reason}", fix: Some(FixSuggestion(description: "修正 manifest 语法")))
    m["E6203"] = ErrorMeta(code: "E6203", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "依赖 {dep} 未找到", fix: Some(FixSuggestion(description: "检查依赖名与源")))
    m["E6204"] = ErrorMeta(code: "E6204", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "依赖版本不满足：期望 {expected}", fix: Some(FixSuggestion(description: "调整版本约束")))
    m["E6205"] = ErrorMeta(code: "E6205", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "依赖版本冲突：{dep}", fix: Some(FixSuggestion(description: "统一版本约束")))
    m["E6206"] = ErrorMeta(code: "E6206", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "包仓库（registry）不可达", fix: Some(FixSuggestion(description: "检查网络/镜像")))
    m["E6207"] = ErrorMeta(code: "E6207", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "依赖下载失败：{dep}", fix: Some(FixSuggestion(description: "重试下载")))
    m["E6208"] = ErrorMeta(code: "E6208", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "依赖校验和（checksum）不匹配", fix: Some(FixSuggestion(description: "清理并重下")))
    m["E6209"] = ErrorMeta(code: "E6209", category: ErrorCategory.Pkg, severity: Severity.Warning,
        template: "锁定文件（lockfile）过期", fix: Some(FixSuggestion(description: "更新 lockfile")))
    m["E6210"] = ErrorMeta(code: "E6210", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "lockfile 与 manifest 冲突", fix: Some(FixSuggestion(description: "重新解析依赖")))
    m["E6211"] = ErrorMeta(code: "E6211", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "依赖存在循环", fix: Some(FixSuggestion(description: "打破依赖循环")))
    m["E6212"] = ErrorMeta(code: "E6212", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "依赖特性（feature）不存在：{feat}", fix: Some(FixSuggestion(description: "检查特性名")))
    m["E6213"] = ErrorMeta(code: "E6213", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "依赖特性组合冲突", fix: Some(FixSuggestion(description: "调整特性启用")))
    m["E6214"] = ErrorMeta(code: "E6214", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "构建脚本（build script）失败", fix: Some(FixSuggestion(description: "检查构建脚本")))
    m["E6215"] = ErrorMeta(code: "E6215", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "Git 依赖克隆失败：{url}", fix: Some(FixSuggestion(description: "检查 Git 地址")))
    m["E6216"] = ErrorMeta(code: "E6216", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "本地路径依赖不存在：{path}", fix: Some(FixSuggestion(description: "检查路径")))
    m["E6217"] = ErrorMeta(code: "E6217", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "发布被拒绝：{reason}", fix: Some(FixSuggestion(description: "检查发布权限")))
    m["E6218"] = ErrorMeta(code: "E6218", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "包名非法：{name}", fix: Some(FixSuggestion(description: "使用合法包名")))
    m["E6219"] = ErrorMeta(code: "E6219", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "包版本号非法", fix: Some(FixSuggestion(description: "使用语义化版本")))
    m["E6220"] = ErrorMeta(code: "E6220", category: ErrorCategory.Pkg, severity: Severity.Warning,
        template: "依赖版本已被撤回（yanked）", fix: Some(FixSuggestion(description: "升级到可用版本")))
    m["E6221"] = ErrorMeta(code: "E6221", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "依赖代理（proxy）解析失败", fix: Some(FixSuggestion(description: "检查代理配置")))
    m["E6222"] = ErrorMeta(code: "E6222", category: ErrorCategory.Pkg, severity: Severity.Warning,
        template: "镜像同步延迟导致缺包", fix: Some(FixSuggestion(description: "切换镜像或等待")))
    m["E6223"] = ErrorMeta(code: "E6223", category: ErrorCategory.Pkg, severity: Severity.Warning,
        template: "缺少许可证声明", fix: Some(FixSuggestion(description: "补充许可证")))
    m["E6224"] = ErrorMeta(code: "E6224", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "依赖许可证冲突", fix: Some(FixSuggestion(description: "检查许可证兼容")))
    m["E6225"] = ErrorMeta(code: "E6225", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "无权限访问私有包", fix: Some(FixSuggestion(description: "配置凭证")))
    m["E6226"] = ErrorMeta(code: "E6226", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "仓库访问令牌过期", fix: Some(FixSuggestion(description: "刷新令牌")))
    m["E6227"] = ErrorMeta(code: "E6227", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "包体积超过限制", fix: Some(FixSuggestion(description: "精简包内容")))
    m["E6228"] = ErrorMeta(code: "E6228", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "包元数据非法", fix: Some(FixSuggestion(description: "修正元数据字段")))
    m["E6229"] = ErrorMeta(code: "E6229", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "依赖源（source）类型不兼容", fix: Some(FixSuggestion(description: "统一依赖源")))
    m["E6230"] = ErrorMeta(code: "E6230", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "依赖的平台条件不满足", fix: Some(FixSuggestion(description: "检查目标平台")))
    m["E6231"] = ErrorMeta(code: "E6231", category: ErrorCategory.Pkg, severity: Severity.Warning,
        template: "可选依赖缺失但不影响构建", fix: Some(FixSuggestion(description: "忽略或安装可选依赖")))
    m["E6232"] = ErrorMeta(code: "E6232", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "开发依赖被发布构建引用", fix: Some(FixSuggestion(description: "限定到 dev 依赖")))
    m["E6233"] = ErrorMeta(code: "E6233", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "补丁（patch）依赖冲突", fix: Some(FixSuggestion(description: "调整补丁集")))
    m["E6234"] = ErrorMeta(code: "E6234", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "工作区成员（member）未找到", fix: Some(FixSuggestion(description: "检查成员路径")))
    m["E6235"] = ErrorMeta(code: "E6235", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "工作区继承字段缺失", fix: Some(FixSuggestion(description: "在根配置补充")))
    m["E6236"] = ErrorMeta(code: "E6236", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "依赖覆盖（override）冲突", fix: Some(FixSuggestion(description: "统一覆盖规则")))
    m["E6237"] = ErrorMeta(code: "E6237", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "vendor 目录与实际依赖不一致", fix: Some(FixSuggestion(description: "重新 vendor")))
    m["E6238"] = ErrorMeta(code: "E6238", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "包缓存目录无权限", fix: Some(FixSuggestion(description: "修正缓存权限")))
    m["E6239"] = ErrorMeta(code: "E6239", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "依赖解析超时", fix: Some(FixSuggestion(description: "减少依赖图规模")))
    m["E6240"] = ErrorMeta(code: "E6240", category: ErrorCategory.Pkg, severity: Severity.Warning,
        template: "同一包被多次引入", fix: Some(FixSuggestion(description: "统一依赖来源")))
    m["E6241"] = ErrorMeta(code: "E6241", category: ErrorCategory.Pkg, severity: Severity.Error,
        template: "目标特定 manifest 解析失败", fix: Some(FixSuggestion(description: "检查目标字段")))
    m["E6301"] = ErrorMeta(code: "E6301", category: ErrorCategory.Build, severity: Severity.Error,
        template: "构建脚本异常终止", fix: Some(FixSuggestion(description: "修复构建脚本")))
    m["E6302"] = ErrorMeta(code: "E6302", category: ErrorCategory.Build, severity: Severity.Error,
        template: "构建目标未定义：{target}", fix: Some(FixSuggestion(description: "检查构建配置")))
    m["E6303"] = ErrorMeta(code: "E6303", category: ErrorCategory.Build, severity: Severity.Error,
        template: "构建配置（profile）未知：{profile}", fix: Some(FixSuggestion(description: "使用合法 profile")))
    m["E6304"] = ErrorMeta(code: "E6304", category: ErrorCategory.Build, severity: Severity.Error,
        template: "产物（artifact）未生成：{name}", fix: Some(FixSuggestion(description: "检查构建步骤")))
    m["E6305"] = ErrorMeta(code: "E6305", category: ErrorCategory.Build, severity: Severity.Error,
        template: "编译步骤失败", fix: Some(FixSuggestion(description: "查看编译错误")))
    m["E6306"] = ErrorMeta(code: "E6306", category: ErrorCategory.Build, severity: Severity.Error,
        template: "链接步骤失败", fix: Some(FixSuggestion(description: "查看链接错误")))
    m["E6307"] = ErrorMeta(code: "E6307", category: ErrorCategory.Build, severity: Severity.Error,
        template: "自定义目标（custom target）执行失败", fix: Some(FixSuggestion(description: "检查目标脚本")))
    m["E6308"] = ErrorMeta(code: "E6308", category: ErrorCategory.Build, severity: Severity.Warning,
        template: "构建缓存失效", fix: Some(FixSuggestion(description: "清理构建缓存")))
    m["E6309"] = ErrorMeta(code: "E6309", category: ErrorCategory.Build, severity: Severity.Error,
        template: "并行构建死锁", fix: Some(FixSuggestion(description: "减少并行度")))
    m["E6310"] = ErrorMeta(code: "E6310", category: ErrorCategory.Build, severity: Severity.Error,
        template: "作业服务器（jobserver）不可用", fix: Some(FixSuggestion(description: "禁用 jobserver")))
    m["E6311"] = ErrorMeta(code: "E6311", category: ErrorCategory.Build, severity: Severity.Error,
        template: "输出目录被占用", fix: Some(FixSuggestion(description: "释放目录锁")))
    m["E6312"] = ErrorMeta(code: "E6312", category: ErrorCategory.Build, severity: Severity.Error,
        template: "无写入输出目录权限", fix: Some(FixSuggestion(description: "修正输出目录权限")))
    m["E6313"] = ErrorMeta(code: "E6313", category: ErrorCategory.Build, severity: Severity.Error,
        template: "构建磁盘空间不足", fix: Some(FixSuggestion(description: "清理或扩容")))
    m["E6314"] = ErrorMeta(code: "E6314", category: ErrorCategory.Build, severity: Severity.Error,
        template: "构建超时", fix: Some(FixSuggestion(description: "增大超时或减少规模")))
    m["E6315"] = ErrorMeta(code: "E6315", category: ErrorCategory.Build, severity: Severity.Warning,
        template: "增量构建被禁用导致慢", fix: Some(FixSuggestion(description: "启用增量")))
    m["E6316"] = ErrorMeta(code: "E6316", category: ErrorCategory.Build, severity: Severity.Error,
        template: "构建需特性开关未开启", fix: Some(FixSuggestion(description: "开启特性")))
    m["E6317"] = ErrorMeta(code: "E6317", category: ErrorCategory.Build, severity: Severity.Error,
        template: "交叉编译工具链缺失", fix: Some(FixSuggestion(description: "安装目标工具链")))
    m["E6318"] = ErrorMeta(code: "E6318", category: ErrorCategory.Build, severity: Severity.Error,
        template: "系统根（sysroot）缺失", fix: Some(FixSuggestion(description: "配置 sysroot")))
    m["E6319"] = ErrorMeta(code: "E6319", category: ErrorCategory.Build, severity: Severity.Error,
        template: "构建所需环境变量缺失：{var}", fix: Some(FixSuggestion(description: "设置环境变量")))
    m["E6320"] = ErrorMeta(code: "E6320", category: ErrorCategory.Build, severity: Severity.Error,
        template: "构建脚本读取了禁止的环境变量", fix: Some(FixSuggestion(description: "移除敏感环境依赖")))
    m["E6321"] = ErrorMeta(code: "E6321", category: ErrorCategory.Build, severity: Severity.Warning,
        template: "构建指纹不匹配触发重编", fix: Some(FixSuggestion(description: "保持输入稳定")))
    m["E6322"] = ErrorMeta(code: "E6322", category: ErrorCategory.Build, severity: Severity.Warning,
        template: "依赖信息（depinfo）过期", fix: Some(FixSuggestion(description: "重新生成")))
    m["E6323"] = ErrorMeta(code: "E6323", category: ErrorCategory.Build, severity: Severity.Error,
        template: "目标三元组非法：{triple}", fix: Some(FixSuggestion(description: "检查三元组")))
    m["E6324"] = ErrorMeta(code: "E6324", category: ErrorCategory.Build, severity: Severity.Error,
        template: "构建计划（build plan）生成失败", fix: Some(FixSuggestion(description: "检查依赖图")))
    m["E6325"] = ErrorMeta(code: "E6325", category: ErrorCategory.Build, severity: Severity.Error,
        template: "后处理（post-build）步骤失败", fix: Some(FixSuggestion(description: "检查后处理脚本")))
    m["E6326"] = ErrorMeta(code: "E6326", category: ErrorCategory.Build, severity: Severity.Error,
        template: "测试执行框架失败", fix: Some(FixSuggestion(description: "检查测试配置")))
    m["E6327"] = ErrorMeta(code: "E6327", category: ErrorCategory.Build, severity: Severity.Error,
        template: "基准测试框架失败", fix: Some(FixSuggestion(description: "检查基准配置")))
    m["E6328"] = ErrorMeta(code: "E6328", category: ErrorCategory.Build, severity: Severity.Error,
        template: "文档构建失败", fix: Some(FixSuggestion(description: "检查文档注释")))
    m["E6329"] = ErrorMeta(code: "E6329", category: ErrorCategory.Build, severity: Severity.Error,
        template: "示例（example）构建失败", fix: Some(FixSuggestion(description: "检查示例代码")))
    m["E6330"] = ErrorMeta(code: "E6330", category: ErrorCategory.Build, severity: Severity.Error,
        template: "工具链下载失败", fix: Some(FixSuggestion(description: "检查网络/镜像")))
    m["E6331"] = ErrorMeta(code: "E6331", category: ErrorCategory.Build, severity: Severity.Error,
        template: "自定义编译标志冲突", fix: Some(FixSuggestion(description: "统一编译标志")))
    m["E6332"] = ErrorMeta(code: "E6332", category: ErrorCategory.Build, severity: Severity.Error,
        template: "条件编译 cfg 未定义：{key}", fix: Some(FixSuggestion(description: "定义该 cfg")))
    m["E6333"] = ErrorMeta(code: "E6333", category: ErrorCategory.Build, severity: Severity.Warning,
        template: "构建脚本被重复触发重编", fix: Some(FixSuggestion(description: "稳定构建脚本输入")))
    m["E6334"] = ErrorMeta(code: "E6334", category: ErrorCategory.Build, severity: Severity.Warning,
        template: "构建锁竞争", fix: Some(FixSuggestion(description: "减少并发写入")))
    m["E6335"] = ErrorMeta(code: "E6335", category: ErrorCategory.Build, severity: Severity.Error,
        template: "仅在特定目标失败的构建", fix: Some(FixSuggestion(description: "检查目标条件")))
    m["E6336"] = ErrorMeta(code: "E6336", category: ErrorCategory.Build, severity: Severity.Error,
        template: "构建进程内存耗尽", fix: Some(FixSuggestion(description: "减少并行或拆分")))
    m["E6337"] = ErrorMeta(code: "E6337", category: ErrorCategory.Build, severity: Severity.Error,
        template: "构建被信号中断", fix: Some(FixSuggestion(description: "重新构建")))
    m["E6338"] = ErrorMeta(code: "E6338", category: ErrorCategory.Build, severity: Severity.Error,
        template: "临时目录不可写", fix: Some(FixSuggestion(description: "修正临时目录权限")))
    m["E6339"] = ErrorMeta(code: "E6339", category: ErrorCategory.Build, severity: Severity.Error,
        template: "构建钩子（hook）执行失败", fix: Some(FixSuggestion(description: "检查钩子脚本")))
    m["E6340"] = ErrorMeta(code: "E6340", category: ErrorCategory.Build, severity: Severity.Error,
        template: "构建动作不支持：{action}", fix: Some(FixSuggestion(description: "使用受支持动作")))
}

/// 填充错误码元数据第 6 组（Debug .. Simd），共 5 个类别。
func buildMetaPart6(m: HashMap<String, ErrorMeta>) {
    m["E6401"] = ErrorMeta(code: "E6401", category: ErrorCategory.Debug, severity: Severity.Error,
        template: "DWARF 调试信息生成失败", fix: Some(FixSuggestion(description: "降低调试信息级别")))
    m["E6402"] = ErrorMeta(code: "E6402", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "调试信息被剥离（无法调试）", fix: Some(FixSuggestion(description: "保留调试信息")))
    m["E6403"] = ErrorMeta(code: "E6403", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "行号表（line table）缺失", fix: Some(FixSuggestion(description: "启用行号生成")))
    m["E6404"] = ErrorMeta(code: "E6404", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "变量位置（location）信息丢失", fix: Some(FixSuggestion(description: "保留变量调试信息")))
    m["E6405"] = ErrorMeta(code: "E6405", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "类型信息缺失（无法展开类型）", fix: Some(FixSuggestion(description: "包含完整类型信息")))
    m["E6406"] = ErrorMeta(code: "E6406", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "内联帧（inlined frame）调试错位", fix: Some(FixSuggestion(description: "检查内联调试信息")))
    m["E6407"] = ErrorMeta(code: "E6407", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "无法在优化后设置断点", fix: Some(FixSuggestion(description: "降低优化级别")))
    m["E6408"] = ErrorMeta(code: "E6408", category: ErrorCategory.Debug, severity: Severity.Error,
        template: "监视点（watchpoint）设置失败", fix: Some(FixSuggestion(description: "检查硬件支持")))
    m["E6409"] = ErrorMeta(code: "E6409", category: ErrorCategory.Debug, severity: Severity.Error,
        template: "调试符号未找到：{symbol}", fix: Some(FixSuggestion(description: "保留符号表")))
    m["E6410"] = ErrorMeta(code: "E6410", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "源码映射（source map）缺失", fix: Some(FixSuggestion(description: "生成 source map")))
    m["E6411"] = ErrorMeta(code: "E6411", category: ErrorCategory.Debug, severity: Severity.Error,
        template: "PDB 调试数据库生成失败", fix: Some(FixSuggestion(description: "检查 PDB 路径")))
    m["E6412"] = ErrorMeta(code: "E6412", category: ErrorCategory.Debug, severity: Severity.Error,
        template: "调试器附加（attach）失败", fix: Some(FixSuggestion(description: "检查权限/进程")))
    m["E6413"] = ErrorMeta(code: "E6413", category: ErrorCategory.Debug, severity: Severity.Error,
        template: "核心转储（core dump）生成失败", fix: Some(FixSuggestion(description: "检查核心大小限制")))
    m["E6414"] = ErrorMeta(code: "E6414", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "调用栈回溯不可用", fix: Some(FixSuggestion(description: "保留帧指针")))
    m["E6415"] = ErrorMeta(code: "E6415", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "变量被优化掉无法查看", fix: Some(FixSuggestion(description: "使用 volatile 或降优化")))
    m["E6416"] = ErrorMeta(code: "E6416", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "宏调试信息缺失", fix: Some(FixSuggestion(description: "启用宏调试信息")))
    m["E6417"] = ErrorMeta(code: "E6417", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "命名空间调试信息缺失", fix: Some(FixSuggestion(description: "包含命名空间信息")))
    m["E6418"] = ErrorMeta(code: "E6418", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "模板/泛型调试信息缺失", fix: Some(FixSuggestion(description: "包含实例化信息")))
    m["E6419"] = ErrorMeta(code: "E6419", category: ErrorCategory.Debug, severity: Severity.Error,
        template: "分离调试信息（split debug）失败", fix: Some(FixSuggestion(description: "检查调试目录")))
    m["E6420"] = ErrorMeta(code: "E6420", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "调试信息压缩失败", fix: Some(FixSuggestion(description: "关闭压缩")))
    m["E6421"] = ErrorMeta(code: "E6421", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "调试出现第 0 行（位置异常）", fix: Some(FixSuggestion(description: "检查源码位置传递")))
    m["E6422"] = ErrorMeta(code: "E6422", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "列号调试信息缺失", fix: Some(FixSuggestion(description: "启用列信息")))
    m["E6423"] = ErrorMeta(code: "E6423", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "继承关系调试信息缺失", fix: Some(FixSuggestion(description: "包含类型层级")))
    m["E6424"] = ErrorMeta(code: "E6424", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "异步调用栈回溯断裂", fix: Some(FixSuggestion(description: "启用异步回溯")))
    m["E6425"] = ErrorMeta(code: "E6425", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "pretty printer 注册失败", fix: Some(FixSuggestion(description: "检查调试脚本")))
    m["E6426"] = ErrorMeta(code: "E6426", category: ErrorCategory.Debug, severity: Severity.Error,
        template: "调试器表达式求值失败", fix: Some(FixSuggestion(description: "检查表达式上下文")))
    m["E6427"] = ErrorMeta(code: "E6427", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "条件断点求值失败", fix: Some(FixSuggestion(description: "简化断点条件")))
    m["E6428"] = ErrorMeta(code: "E6428", category: ErrorCategory.Debug, severity: Severity.Error,
        template: "调试服务器（debug server）未运行", fix: Some(FixSuggestion(description: "启动调试服务器")))
    m["E6429"] = ErrorMeta(code: "E6429", category: ErrorCategory.Debug, severity: Severity.Error,
        template: "调试协议握手失败", fix: Some(FixSuggestion(description: "检查调试器版本")))
    m["E6430"] = ErrorMeta(code: "E6430", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "符号化（symbolicate）失败", fix: Some(FixSuggestion(description: "提供符号文件")))
    m["E6431"] = ErrorMeta(code: "E6431", category: ErrorCategory.Debug, severity: Severity.Error,
        template: "调试信息与二进制不匹配", fix: Some(FixSuggestion(description: "重新生成调试信息")))
    m["E6432"] = ErrorMeta(code: "E6432", category: ErrorCategory.Debug, severity: Severity.Error,
        template: "调用帧损坏无法展开", fix: Some(FixSuggestion(description: "检查栈完整性")))
    m["E6433"] = ErrorMeta(code: "E6433", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "展开信息缺失导致回溯失败", fix: Some(FixSuggestion(description: "保留展开信息")))
    m["E6434"] = ErrorMeta(code: "E6434", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "调试段（.debug_*）被剥离", fix: Some(FixSuggestion(description: "保留调试段")))
    m["E6435"] = ErrorMeta(code: "E6435", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "类型别名调试信息丢失", fix: Some(FixSuggestion(description: "包含别名解析")))
    m["E6436"] = ErrorMeta(code: "E6436", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "局部变量调试条目被省略", fix: Some(FixSuggestion(description: "禁用变量省略")))
    m["E6437"] = ErrorMeta(code: "E6437", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "调试信息过大", fix: Some(FixSuggestion(description: "降低调试级别")))
    m["E6438"] = ErrorMeta(code: "E6438", category: ErrorCategory.Debug, severity: Severity.Error,
        template: "调试信息损坏", fix: Some(FixSuggestion(description: "重新生成")))
    m["E6439"] = ErrorMeta(code: "E6439", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "编译单元（CU）调试信息缺失", fix: Some(FixSuggestion(description: "包含 CU 信息")))
    m["E6440"] = ErrorMeta(code: "E6440", category: ErrorCategory.Debug, severity: Severity.Warning,
        template: "地址区间（aranges）表缺失", fix: Some(FixSuggestion(description: "生成 aranges")))
    m["E6501"] = ErrorMeta(code: "E6501", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "远程编译节点不可用", fix: Some(FixSuggestion(description: "检查节点状态")))
    m["E6502"] = ErrorMeta(code: "E6502", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "编译调度器（scheduler）不可达", fix: Some(FixSuggestion(description: "检查网络")))
    m["E6503"] = ErrorMeta(code: "E6503", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "编译任务分发失败", fix: Some(FixSuggestion(description: "重试分发")))
    m["E6504"] = ErrorMeta(code: "E6504", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "远程结果拉取失败", fix: Some(FixSuggestion(description: "检查网络/存储")))
    m["E6505"] = ErrorMeta(code: "E6505", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "远程节点鉴权失败", fix: Some(FixSuggestion(description: "检查凭证")))
    m["E6506"] = ErrorMeta(code: "E6506", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "远程与本地环境不一致", fix: Some(FixSuggestion(description: "统一工具链/依赖")))
    m["E6507"] = ErrorMeta(code: "E6507", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "分布式缓存同步失败", fix: Some(FixSuggestion(description: "检查缓存后端")))
    m["E6508"] = ErrorMeta(code: "E6508", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "网络分区导致编译中断", fix: Some(FixSuggestion(description: "恢复网络后重试")))
    m["E6509"] = ErrorMeta(code: "E6509", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "远程编译超时", fix: Some(FixSuggestion(description: "增大超时或拆分任务")))
    m["E6510"] = ErrorMeta(code: "E6510", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "远程返回结果损坏", fix: Some(FixSuggestion(description: "重新分发任务")))
    m["E6511"] = ErrorMeta(code: "E6511", category: ErrorCategory.Dist, severity: Severity.Warning,
        template: "远程节点过载", fix: Some(FixSuggestion(description: "分散到其他节点")))
    m["E6512"] = ErrorMeta(code: "E6512", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "远程产物与本地期望不一致", fix: Some(FixSuggestion(description: "校验产物哈希")))
    m["E6513"] = ErrorMeta(code: "E6513", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "远程节点不支持该目标", fix: Some(FixSuggestion(description: "选择支持的目标节点")))
    m["E6514"] = ErrorMeta(code: "E6514", category: ErrorCategory.Dist, severity: Severity.Warning,
        template: "编译单元过大无法分发", fix: Some(FixSuggestion(description: "拆分编译单元")))
    m["E6515"] = ErrorMeta(code: "E6515", category: ErrorCategory.Dist, severity: Severity.Warning,
        template: "依赖未缓存到远程", fix: Some(FixSuggestion(description: "预上传依赖")))
    m["E6516"] = ErrorMeta(code: "E6516", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "安全通道（TLS）建立失败", fix: Some(FixSuggestion(description: "检查证书")))
    m["E6517"] = ErrorMeta(code: "E6517", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "节点心跳丢失", fix: Some(FixSuggestion(description: "检查节点健康")))
    m["E6518"] = ErrorMeta(code: "E6518", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "编译配额超限", fix: Some(FixSuggestion(description: "申请更多配额")))
    m["E6519"] = ErrorMeta(code: "E6519", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "节点区域与数据合规冲突", fix: Some(FixSuggestion(description: "选择合规区域")))
    m["E6520"] = ErrorMeta(code: "E6520", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "任务序列化失败", fix: Some(FixSuggestion(description: "检查任务结构")))
    m["E6521"] = ErrorMeta(code: "E6521", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "任务反序列化失败", fix: Some(FixSuggestion(description: "统一定义格式")))
    m["E6522"] = ErrorMeta(code: "E6522", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "节点工具链版本不一致", fix: Some(FixSuggestion(description: "统一版本")))
    m["E6523"] = ErrorMeta(code: "E6523", category: ErrorCategory.Dist, severity: Severity.Warning,
        template: "部分节点失败导致整体回退", fix: Some(FixSuggestion(description: "隔离失败节点")))
    m["E6524"] = ErrorMeta(code: "E6524", category: ErrorCategory.Dist, severity: Severity.Warning,
        template: "负载不均衡", fix: Some(FixSuggestion(description: "优化调度策略")))
    m["E6525"] = ErrorMeta(code: "E6525", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "重复分发导致非幂等结果", fix: Some(FixSuggestion(description: "去重任务")))
    m["E6526"] = ErrorMeta(code: "E6526", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "分布式缓存被污染", fix: Some(FixSuggestion(description: "清理缓存")))
    m["E6527"] = ErrorMeta(code: "E6527", category: ErrorCategory.Dist, severity: Severity.Warning,
        template: "带宽受限拖慢编译", fix: Some(FixSuggestion(description: "就近调度节点")))
    m["E6528"] = ErrorMeta(code: "E6528", category: ErrorCategory.Dist, severity: Severity.Warning,
        template: "节点被列入黑名单", fix: Some(FixSuggestion(description: "检查节点健康")))
    m["E6529"] = ErrorMeta(code: "E6529", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "分布式编译被中止", fix: Some(FixSuggestion(description: "查看中止原因")))
    m["E6530"] = ErrorMeta(code: "E6530", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "任务检查点（checkpoint）失败", fix: Some(FixSuggestion(description: "检查存储")))
    m["E6531"] = ErrorMeta(code: "E6531", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "故障恢复失败", fix: Some(FixSuggestion(description: "手动重试")))
    m["E6532"] = ErrorMeta(code: "E6532", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "临时访问令牌过期", fix: Some(FixSuggestion(description: "刷新令牌")))
    m["E6533"] = ErrorMeta(code: "E6533", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "节点池配置错误", fix: Some(FixSuggestion(description: "修正池配置")))
    m["E6534"] = ErrorMeta(code: "E6534", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "多次编译结果漂移（不确定）", fix: Some(FixSuggestion(description: "固定环境变量")))
    m["E6535"] = ErrorMeta(code: "E6535", category: ErrorCategory.Dist, severity: Severity.Warning,
        template: "审计日志缺失", fix: Some(FixSuggestion(description: "启用审计")))
    m["E6536"] = ErrorMeta(code: "E6536", category: ErrorCategory.Dist, severity: Severity.Warning,
        template: "节点冷启动慢", fix: Some(FixSuggestion(description: "预热节点")))
    m["E6537"] = ErrorMeta(code: "E6537", category: ErrorCategory.Dist, severity: Severity.Warning,
        template: "多任务资源争用", fix: Some(FixSuggestion(description: "限流")))
    m["E6538"] = ErrorMeta(code: "E6538", category: ErrorCategory.Dist, severity: Severity.Error,
        template: "分布式不支持该编译特性", fix: Some(FixSuggestion(description: "本地编译该特性")))
    m["E6601"] = ErrorMeta(code: "E6601", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件未找到：{name}", fix: Some(FixSuggestion(description: "检查插件路径")))
    m["E6602"] = ErrorMeta(code: "E6602", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件加载失败：{reason}", fix: Some(FixSuggestion(description: "检查插件兼容")))
    m["E6603"] = ErrorMeta(code: "E6603", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件版本与宿主不兼容", fix: Some(FixSuggestion(description: "升级插件或宿主")))
    m["E6604"] = ErrorMeta(code: "E6604", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件使用的 API 已变更", fix: Some(FixSuggestion(description: "更新插件")))
    m["E6605"] = ErrorMeta(code: "E6605", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件执行异常", fix: Some(FixSuggestion(description: "修复插件实现")))
    m["E6606"] = ErrorMeta(code: "E6606", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件执行超时", fix: Some(FixSuggestion(description: "优化插件或增大超时")))
    m["E6607"] = ErrorMeta(code: "E6607", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件权限不足", fix: Some(FixSuggestion(description: "授予所需权限")))
    m["E6608"] = ErrorMeta(code: "E6608", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件间功能冲突：{name}", fix: Some(FixSuggestion(description: "禁用冲突插件")))
    m["E6609"] = ErrorMeta(code: "E6609", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件签名校验失败", fix: Some(FixSuggestion(description: "使用受信任插件")))
    m["E6610"] = ErrorMeta(code: "E6610", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件执行了不安全操作", fix: Some(FixSuggestion(description: "审查插件来源")))
    m["E6611"] = ErrorMeta(code: "E6611", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件初始化失败", fix: Some(FixSuggestion(description: "检查插件配置")))
    m["E6612"] = ErrorMeta(code: "E6612", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件依赖缺失：{dep}", fix: Some(FixSuggestion(description: "安装插件依赖")))
    m["E6613"] = ErrorMeta(code: "E6613", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件配置非法", fix: Some(FixSuggestion(description: "修正插件配置")))
    m["E6614"] = ErrorMeta(code: "E6614", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件钩子（hook）执行失败", fix: Some(FixSuggestion(description: "检查钩子实现")))
    m["E6615"] = ErrorMeta(code: "E6615", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件泄漏资源", fix: Some(FixSuggestion(description: "修复插件资源释放")))
    m["E6616"] = ErrorMeta(code: "E6616", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件崩溃导致宿主降级", fix: Some(FixSuggestion(description: "更新插件")))
    m["E6617"] = ErrorMeta(code: "E6617", category: ErrorCategory.Plugin, severity: Severity.Warning,
        template: "插件被禁用但被引用", fix: Some(FixSuggestion(description: "启用插件")))
    m["E6618"] = ErrorMeta(code: "E6618", category: ErrorCategory.Plugin, severity: Severity.Warning,
        template: "插件过旧不再受支持", fix: Some(FixSuggestion(description: "升级插件")))
    m["E6619"] = ErrorMeta(code: "E6619", category: ErrorCategory.Plugin, severity: Severity.Warning,
        template: "插件过新宿主不支持", fix: Some(FixSuggestion(description: "升级宿主")))
    m["E6620"] = ErrorMeta(code: "E6620", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件名冲突：{name}", fix: Some(FixSuggestion(description: "重命名插件")))
    m["E6621"] = ErrorMeta(code: "E6621", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件依赖形成循环", fix: Some(FixSuggestion(description: "打破插件循环")))
    m["E6622"] = ErrorMeta(code: "E6622", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件违反沙箱约束", fix: Some(FixSuggestion(description: "放宽沙箱或修正插件")))
    m["E6623"] = ErrorMeta(code: "E6623", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件内存耗尽", fix: Some(FixSuggestion(description: "限制插件内存")))
    m["E6624"] = ErrorMeta(code: "E6624", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件内部死锁", fix: Some(FixSuggestion(description: "审查插件并发")))
    m["E6625"] = ErrorMeta(code: "E6625", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件网络访问被拦", fix: Some(FixSuggestion(description: "配置网络策略")))
    m["E6626"] = ErrorMeta(code: "E6626", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件文件系统访问被拦", fix: Some(FixSuggestion(description: "配置文件系统策略")))
    m["E6627"] = ErrorMeta(code: "E6627", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件环境变量访问被拦", fix: Some(FixSuggestion(description: "配置环境策略")))
    m["E6628"] = ErrorMeta(code: "E6628", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件状态反序列化失败", fix: Some(FixSuggestion(description: "清理插件状态")))
    m["E6629"] = ErrorMeta(code: "E6629", category: ErrorCategory.Plugin, severity: Severity.Warning,
        template: "插件热重载失败", fix: Some(FixSuggestion(description: "重启加载插件")))
    m["E6630"] = ErrorMeta(code: "E6630", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件卸载失败", fix: Some(FixSuggestion(description: "强制释放插件")))
    m["E6631"] = ErrorMeta(code: "E6631", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件所需能力缺失：{cap}", fix: Some(FixSuggestion(description: "启用对应能力")))
    m["E6632"] = ErrorMeta(code: "E6632", category: ErrorCategory.Plugin, severity: Severity.Warning,
        template: "插件 API 已废弃", fix: Some(FixSuggestion(description: "迁移到新 API")))
    m["E6633"] = ErrorMeta(code: "E6633", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件清单非法", fix: Some(FixSuggestion(description: "修正插件清单")))
    m["E6634"] = ErrorMeta(code: "E6634", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件入口符号缺失", fix: Some(FixSuggestion(description: "检查插件导出")))
    m["E6635"] = ErrorMeta(code: "E6635", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件 ABI 与宿主不匹配", fix: Some(FixSuggestion(description: "重新编译插件")))
    m["E6636"] = ErrorMeta(code: "E6636", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件语言运行时不匹配", fix: Some(FixSuggestion(description: "使用兼容运行时")))
    m["E6637"] = ErrorMeta(code: "E6637", category: ErrorCategory.Plugin, severity: Severity.Error,
        template: "插件以错误码退出", fix: Some(FixSuggestion(description: "查看插件日志")))
    m["E6638"] = ErrorMeta(code: "E6638", category: ErrorCategory.Plugin, severity: Severity.Warning,
        template: "插件输出解析失败", fix: Some(FixSuggestion(description: "规范插件输出")))
    m["E6639"] = ErrorMeta(code: "E6639", category: ErrorCategory.Plugin, severity: Severity.Warning,
        template: "插件锁竞争", fix: Some(FixSuggestion(description: "减少插件并发")))
    m["E6701"] = ErrorMeta(code: "E6701", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标三元组（triple）无效：{triple}", fix: Some(FixSuggestion(description: "检查目标拼写")))
    m["E6702"] = ErrorMeta(code: "E6702", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标平台不受支持：{target}", fix: Some(FixSuggestion(description: "选择受支持目标")))
    m["E6703"] = ErrorMeta(code: "E6703", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标缺少特性 {feature}", fix: Some(FixSuggestion(description: "启用目标特性")))
    m["E6704"] = ErrorMeta(code: "E6704", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "未知目标架构：{arch}", fix: Some(FixSuggestion(description: "使用已知架构")))
    m["E6705"] = ErrorMeta(code: "E6705", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "未知目标操作系统：{os}", fix: Some(FixSuggestion(description: "使用已知 OS")))
    m["E6706"] = ErrorMeta(code: "E6706", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "未知目标环境（env）：{env}", fix: Some(FixSuggestion(description: "使用已知 env")))
    m["E6707"] = ErrorMeta(code: "E6707", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "未知目标厂商（vendor）：{vendor}", fix: Some(FixSuggestion(description: "使用已知 vendor")))
    m["E6708"] = ErrorMeta(code: "E6708", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标指针宽度不支持：{width}", fix: Some(FixSuggestion(description: "选择受支持宽度")))
    m["E6709"] = ErrorMeta(code: "E6709", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标字节序未知", fix: Some(FixSuggestion(description: "显式指定字节序")))
    m["E6710"] = ErrorMeta(code: "E6710", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标不支持硬件浮点", fix: Some(FixSuggestion(description: "使用软浮点")))
    m["E6711"] = ErrorMeta(code: "E6711", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标不支持原子指令", fix: Some(FixSuggestion(description: "使用锁替代")))
    m["E6712"] = ErrorMeta(code: "E6712", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标无 SIMD 指令集", fix: Some(FixSuggestion(description: "禁用向量化")))
    m["E6713"] = ErrorMeta(code: "E6713", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标 TLS 模型不支持", fix: Some(FixSuggestion(description: "更换 TLS 模型")))
    m["E6714"] = ErrorMeta(code: "E6714", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标不支持该重定位", fix: Some(FixSuggestion(description: "调整代码生成")))
    m["E6715"] = ErrorMeta(code: "E6715", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标代码模型（code model）非法", fix: Some(FixSuggestion(description: "使用合法代码模型")))
    m["E6716"] = ErrorMeta(code: "E6716", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "未知目标 CPU：{cpu}", fix: Some(FixSuggestion(description: "使用已知 CPU")))
    m["E6717"] = ErrorMeta(code: "E6717", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "未知目标 FPU：{fpu}", fix: Some(FixSuggestion(description: "使用已知 FPU")))
    m["E6718"] = ErrorMeta(code: "E6718", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "未知目标 ABI：{abi}", fix: Some(FixSuggestion(description: "使用已知 ABI")))
    m["E6719"] = ErrorMeta(code: "E6719", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标不支持该 panic 策略", fix: Some(FixSuggestion(description: "使用受支持策略")))
    m["E6720"] = ErrorMeta(code: "E6720", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标分配策略不支持", fix: Some(FixSuggestion(description: "更换分配器")))
    m["E6721"] = ErrorMeta(code: "E6721", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标系统调用约定未知", fix: Some(FixSuggestion(description: "使用目标约定")))
    m["E6722"] = ErrorMeta(code: "E6722", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标栈探测（stack probe）不支持", fix: Some(FixSuggestion(description: "禁用栈探测")))
    m["E6723"] = ErrorMeta(code: "E6723", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标异常模型不支持", fix: Some(FixSuggestion(description: "使用受支持模型")))
    m["E6724"] = ErrorMeta(code: "E6724", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标调试格式不支持", fix: Some(FixSuggestion(description: "更换调试格式")))
    m["E6725"] = ErrorMeta(code: "E6725", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标目标文件格式不支持", fix: Some(FixSuggestion(description: "使用受支持格式")))
    m["E6726"] = ErrorMeta(code: "E6726", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标链接器缺失", fix: Some(FixSuggestion(description: "安装目标链接器")))
    m["E6727"] = ErrorMeta(code: "E6727", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标运行时库缺失", fix: Some(FixSuggestion(description: "配置目标运行时")))
    m["E6728"] = ErrorMeta(code: "E6728", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标 libc 缺失", fix: Some(FixSuggestion(description: "提供目标 libc")))
    m["E6729"] = ErrorMeta(code: "E6729", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标无标准库支持", fix: Some(FixSuggestion(description: "使用 no_std 模式")))
    m["E6730"] = ErrorMeta(code: "E6730", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标无原子支持且禁用 fallback", fix: Some(FixSuggestion(description: "启用原子 fallback")))
    m["E6731"] = ErrorMeta(code: "E6731", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标浮点类型不支持", fix: Some(FixSuggestion(description: "改用整型表示")))
    m["E6732"] = ErrorMeta(code: "E6732", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标寄存器宽度不支持", fix: Some(FixSuggestion(description: "调整数据类型")))
    m["E6733"] = ErrorMeta(code: "E6733", category: ErrorCategory.Tgt, severity: Severity.Warning,
        template: "目标不支持性能分析插桩", fix: Some(FixSuggestion(description: "关闭插桩")))
    m["E6734"] = ErrorMeta(code: "E6734", category: ErrorCategory.Tgt, severity: Severity.Warning,
        template: "目标不支持消毒剂", fix: Some(FixSuggestion(description: "关闭 sanitizer")))
    m["E6735"] = ErrorMeta(code: "E6735", category: ErrorCategory.Tgt, severity: Severity.Warning,
        template: "目标不支持覆盖率插桩", fix: Some(FixSuggestion(description: "关闭覆盖率")))
    m["E6736"] = ErrorMeta(code: "E6736", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标不支持位置无关代码", fix: Some(FixSuggestion(description: "禁用 PIC")))
    m["E6737"] = ErrorMeta(code: "E6737", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标不支持线程局部", fix: Some(FixSuggestion(description: "避免使用 TLS")))
    m["E6738"] = ErrorMeta(code: "E6738", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标不支持栈展开", fix: Some(FixSuggestion(description: "使用不展开 panic 策略")))
    m["E6739"] = ErrorMeta(code: "E6739", category: ErrorCategory.Tgt, severity: Severity.Error,
        template: "目标厂商库缺失", fix: Some(FixSuggestion(description: "安装厂商 SDK")))
    m["E6801"] = ErrorMeta(code: "E6801", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 宽度 {width} 不支持", fix: Some(FixSuggestion(description: "使用受支持宽度")))
    m["E6802"] = ErrorMeta(code: "E6802", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 向量类型不匹配", fix: Some(FixSuggestion(description: "统一向量长度/类型")))
    m["E6803"] = ErrorMeta(code: "E6803", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 通道数（lane）非法：{lanes}", fix: Some(FixSuggestion(description: "使用合法通道数")))
    m["E6804"] = ErrorMeta(code: "E6804", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 未对齐访问", fix: Some(FixSuggestion(description: "使用对齐加载/存储")))
    m["E6805"] = ErrorMeta(code: "E6805", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 掩码（mask）非法", fix: Some(FixSuggestion(description: "检查掩码位宽")))
    m["E6806"] = ErrorMeta(code: "E6806", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 归约（reduction）失败", fix: Some(FixSuggestion(description: "改用标量归约")))
    m["E6807"] = ErrorMeta(code: "E6807", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 重排（shuffle）索引越界", fix: Some(FixSuggestion(description: "检查索引范围")))
    m["E6808"] = ErrorMeta(code: "E6808", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 聚集/散布（gather/scatter）不支持", fix: Some(FixSuggestion(description: "使用标量回退")))
    m["E6809"] = ErrorMeta(code: "E6809", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 内建指令缺失：{name}", fix: Some(FixSuggestion(description: "使用受支持指令")))
    m["E6810"] = ErrorMeta(code: "E6810", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 运算溢出", fix: Some(FixSuggestion(description: "检查数据范围")))
    m["E6811"] = ErrorMeta(code: "E6811", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 除零", fix: Some(FixSuggestion(description: "检查分母通道")))
    m["E6812"] = ErrorMeta(code: "E6812", category: ErrorCategory.Simd, severity: Severity.Warning,
        template: "SIMD 产生非数（NaN）未处理", fix: Some(FixSuggestion(description: "检查输入有效性")))
    m["E6813"] = ErrorMeta(code: "E6813", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 常量构造非法", fix: Some(FixSuggestion(description: "检查常量类型")))
    m["E6814"] = ErrorMeta(code: "E6814", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 类型转换（convert）失败", fix: Some(FixSuggestion(description: "使用兼容类型")))
    m["E6815"] = ErrorMeta(code: "E6815", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 置换（permute）失败", fix: Some(FixSuggestion(description: "检查置换模式")))
    m["E6816"] = ErrorMeta(code: "E6816", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 混合（blend）掩码非法", fix: Some(FixSuggestion(description: "检查掩码")))
    m["E6817"] = ErrorMeta(code: "E6817", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 提取（extract）越界", fix: Some(FixSuggestion(description: "检查通道索引")))
    m["E6818"] = ErrorMeta(code: "E6818", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 插入（insert）越界", fix: Some(FixSuggestion(description: "检查通道索引")))
    m["E6819"] = ErrorMeta(code: "E6819", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 比较结果类型不匹配", fix: Some(FixSuggestion(description: "使用掩码类型")))
    m["E6820"] = ErrorMeta(code: "E6820", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 位转换（bitcast）非法", fix: Some(FixSuggestion(description: "检查位宽")))
    m["E6821"] = ErrorMeta(code: "E6821", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 对齐要求不满足", fix: Some(FixSuggestion(description: "使用对齐分配")))
    m["E6822"] = ErrorMeta(code: "E6822", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "目标无对应 SIMD ISA", fix: Some(FixSuggestion(description: "禁用该 SIMD 路径")))
    m["E6823"] = ErrorMeta(code: "E6823", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 操作数长度不一致", fix: Some(FixSuggestion(description: "统一向量长度")))
    m["E6824"] = ErrorMeta(code: "E6824", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 有/无符号混用错误", fix: Some(FixSuggestion(description: "统一符号")))
    m["E6825"] = ErrorMeta(code: "E6825", category: ErrorCategory.Simd, severity: Severity.Warning,
        template: "SIMD 舍入模式不支持", fix: Some(FixSuggestion(description: "使用默认舍入")))
    m["E6826"] = ErrorMeta(code: "E6826", category: ErrorCategory.Simd, severity: Severity.Warning,
        template: "SIMD 饱和（saturation）不支持", fix: Some(FixSuggestion(description: "使用标量回退")))
    m["E6827"] = ErrorMeta(code: "E6827", category: ErrorCategory.Simd, severity: Severity.Warning,
        template: "SIMD 融合乘加（FMA）不支持", fix: Some(FixSuggestion(description: "拆分乘加")))
    m["E6828"] = ErrorMeta(code: "E6828", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "多 SIMD 指令集冲突", fix: Some(FixSuggestion(description: "固定使用一种 ISA")))
    m["E6829"] = ErrorMeta(code: "E6829", category: ErrorCategory.Simd, severity: Severity.Warning,
        template: "SIMD 寄存器压力过高", fix: Some(FixSuggestion(description: "减少同时活动向量")))
    m["E6830"] = ErrorMeta(code: "E6830", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 通道顺序（endian）不一致", fix: Some(FixSuggestion(description: "统一通道序")))
    m["E6831"] = ErrorMeta(code: "E6831", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 谓词（predicate）非法", fix: Some(FixSuggestion(description: "检查谓词")))
    m["E6832"] = ErrorMeta(code: "E6832", category: ErrorCategory.Simd, severity: Severity.Warning,
        template: "SIMD 旋转（rotate）不支持", fix: Some(FixSuggestion(description: "改用移位组合")))
    m["E6833"] = ErrorMeta(code: "E6833", category: ErrorCategory.Simd, severity: Severity.Warning,
        template: "SIMD 位计数（popcount）不支持", fix: Some(FixSuggestion(description: "使用标量回退")))
    m["E6834"] = ErrorMeta(code: "E6834", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 移位量越界", fix: Some(FixSuggestion(description: "检查移位量")))
    m["E6835"] = ErrorMeta(code: "E6835", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 选择（select）掩码非法", fix: Some(FixSuggestion(description: "检查掩码")))
    m["E6836"] = ErrorMeta(code: "E6836", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 加宽（widen）失败", fix: Some(FixSuggestion(description: "使用显式加宽")))
    m["E6837"] = ErrorMeta(code: "E6837", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 收窄（narrow）溢出", fix: Some(FixSuggestion(description: "检查数据范围")))
    m["E6838"] = ErrorMeta(code: "E6838", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 交织（interleave）失败", fix: Some(FixSuggestion(description: "检查输入布局")))
    m["E6839"] = ErrorMeta(code: "E6839", category: ErrorCategory.Simd, severity: Severity.Error,
        template: "SIMD 去交织（deinterleave）失败", fix: Some(FixSuggestion(description: "检查输入布局")))
}

/// 填充错误码元数据第 7 组（Embed .. Sec），共 5 个类别。
func buildMetaPart7(m: HashMap<String, ErrorMeta>) {
    m["E6901"] = ErrorMeta(code: "E6901", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "嵌入式目标无标准库", fix: Some(FixSuggestion(description: "使用 no_std 模式")))
    m["E6902"] = ErrorMeta(code: "E6902", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "嵌入式目标无分配器", fix: Some(FixSuggestion(description: "使用静态分配")))
    m["E6903"] = ErrorMeta(code: "E6903", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "嵌入式 Flash 空间不足", fix: Some(FixSuggestion(description: "精简固件")))
    m["E6904"] = ErrorMeta(code: "E6904", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "嵌入式 RAM 不足", fix: Some(FixSuggestion(description: "减少静态占用")))
    m["E6905"] = ErrorMeta(code: "E6905", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "嵌入式目标无 FPU", fix: Some(FixSuggestion(description: "使用定点数")))
    m["E6906"] = ErrorMeta(code: "E6906", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "嵌入式目标禁用异常", fix: Some(FixSuggestion(description: "使用错误码返回")))
    m["E6907"] = ErrorMeta(code: "E6907", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "嵌入式目标禁用 RTTI", fix: Some(FixSuggestion(description: "避免运行时类型查询")))
    m["E6908"] = ErrorMeta(code: "E6908", category: ErrorCategory.Embed, severity: Severity.Fatal,
        template: "触发硬件错误（HardFault）", fix: Some(FixSuggestion(description: "检查外设/内存访问")))
    m["E6909"] = ErrorMeta(code: "E6909", category: ErrorCategory.Embed, severity: Severity.Fatal,
        template: "看门狗（watchdog）复位", fix: Some(FixSuggestion(description: "喂狗或优化耗时")))
    m["E6910"] = ErrorMeta(code: "E6910", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "中断嵌套过深", fix: Some(FixSuggestion(description: "减少中断嵌套")))
    m["E6911"] = ErrorMeta(code: "E6911", category: ErrorCategory.Embed, severity: Severity.Fatal,
        template: "嵌入式栈溢出", fix: Some(FixSuggestion(description: "增大栈或减帧")))
    m["E6912"] = ErrorMeta(code: "E6912", category: ErrorCategory.Embed, severity: Severity.Fatal,
        template: "嵌入式堆损坏", fix: Some(FixSuggestion(description: "检查越界写入")))
    m["E6913"] = ErrorMeta(code: "E6913", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "外设忙（忙等待超时）", fix: Some(FixSuggestion(description: "检查外设状态")))
    m["E6914"] = ErrorMeta(code: "E6914", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "DMA 传输失败", fix: Some(FixSuggestion(description: "检查 DMA 配置")))
    m["E6915"] = ErrorMeta(code: "E6915", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "时钟配置错误", fix: Some(FixSuggestion(description: "检查时钟树")))
    m["E6916"] = ErrorMeta(code: "E6916", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "引脚（pin）功能冲突", fix: Some(FixSuggestion(description: "重新分配引脚")))
    m["E6917"] = ErrorMeta(code: "E6917", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "嵌入式目标无系统调用", fix: Some(FixSuggestion(description: "使用裸机 API")))
    m["E6918"] = ErrorMeta(code: "E6918", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "CGO 符号与 C 侧冲突", fix: Some(FixSuggestion(description: "使用命名空间前缀")))
    m["E6919"] = ErrorMeta(code: "E6919", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "CGO 类型映射错误", fix: Some(FixSuggestion(description: "检查 cgo 类型标注")))
    m["E6920"] = ErrorMeta(code: "E6920", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "CGO 回调指针为空", fix: Some(FixSuggestion(description: "检查 C 侧注册")))
    m["E6921"] = ErrorMeta(code: "E6921", category: ErrorCategory.Embed, severity: Severity.Fatal,
        template: "CGO 跨边界 panic", fix: Some(FixSuggestion(description: "边界捕获 panic")))
    m["E6922"] = ErrorMeta(code: "E6922", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "CGO 线程局部不可见", fix: Some(FixSuggestion(description: "显式传递上下文")))
    m["E6923"] = ErrorMeta(code: "E6923", category: ErrorCategory.Embed, severity: Severity.Fatal,
        template: "CGO 跨语言释放内存", fix: Some(FixSuggestion(description: "统一分配侧")))
    m["E6924"] = ErrorMeta(code: "E6924", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "中断优先级配置非法", fix: Some(FixSuggestion(description: "检查 NVIC 配置")))
    m["E6925"] = ErrorMeta(code: "E6925", category: ErrorCategory.Embed, severity: Severity.Fatal,
        template: "启动（boot）失败", fix: Some(FixSuggestion(description: "检查启动文件")))
    m["E6926"] = ErrorMeta(code: "E6926", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "嵌入式链接脚本错误", fix: Some(FixSuggestion(description: "修正链接脚本")))
    m["E6927"] = ErrorMeta(code: "E6927", category: ErrorCategory.Embed, severity: Severity.Fatal,
        template: "中断向量表缺失/错位", fix: Some(FixSuggestion(description: "检查向量表")))
    m["E6928"] = ErrorMeta(code: "E6928", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "嵌入式目标无原子指令", fix: Some(FixSuggestion(description: "关闭并发或禁用")))
    m["E6929"] = ErrorMeta(code: "E6929", category: ErrorCategory.Embed, severity: Severity.Warning,
        template: "嵌入式监视点不可用", fix: Some(FixSuggestion(description: "改用软件检测")))
    m["E6930"] = ErrorMeta(code: "E6930", category: ErrorCategory.Embed, severity: Severity.Fatal,
        template: "电源故障导致复位", fix: Some(FixSuggestion(description: "检查电源管理")))
    m["E6931"] = ErrorMeta(code: "E6931", category: ErrorCategory.Embed, severity: Severity.Fatal,
        template: "栈金丝雀（canary）被破坏", fix: Some(FixSuggestion(description: "检查栈溢出")))
    m["E6932"] = ErrorMeta(code: "E6932", category: ErrorCategory.Embed, severity: Severity.Fatal,
        template: "MPU 保护区域违规", fix: Some(FixSuggestion(description: "调整 MPU 配置")))
    m["E6933"] = ErrorMeta(code: "E6933", category: ErrorCategory.Embed, severity: Severity.Warning,
        template: "缓存一致性（cache coherency）问题", fix: Some(FixSuggestion(description: "手动刷新缓存")))
    m["E6934"] = ErrorMeta(code: "E6934", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "CGO 所需 C 编译器未找到", fix: Some(FixSuggestion(description: "安装 C 工具链")))
    m["E6935"] = ErrorMeta(code: "E6935", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "CGO 生成的 C 代码编译失败", fix: Some(FixSuggestion(description: "检查 C 代码")))
    m["E6936"] = ErrorMeta(code: "E6936", category: ErrorCategory.Embed, severity: Severity.Warning,
        template: "嵌入式目标无标准 IO", fix: Some(FixSuggestion(description: "使用自定义日志")))
    m["E6937"] = ErrorMeta(code: "E6937", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "系统节拍（tick）初始化失败", fix: Some(FixSuggestion(description: "检查定时器")))
    m["E6938"] = ErrorMeta(code: "E6938", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "临界区（critical section）嵌套错误", fix: Some(FixSuggestion(description: "平衡进入/退出")))
    m["E6939"] = ErrorMeta(code: "E6939", category: ErrorCategory.Embed, severity: Severity.Error,
        template: "目标硬件无 FPU 触发软浮点异常", fix: Some(FixSuggestion(description: "启用软浮点")))
    m["E6940"] = ErrorMeta(code: "E6940", category: ErrorCategory.Embed, severity: Severity.Fatal,
        template: "CGO 回调生命周期短于 C 侧", fix: Some(FixSuggestion(description: "延长回调所有权")))
    m["E7001"] = ErrorMeta(code: "E7001", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试代码编译失败", fix: Some(FixSuggestion(description: "修复测试代码")))
    m["E7002"] = ErrorMeta(code: "E7002", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试可执行文件未生成", fix: Some(FixSuggestion(description: "检查测试构建")))
    m["E7003"] = ErrorMeta(code: "E7003", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试用例超时", fix: Some(FixSuggestion(description: "优化用例或增大超时")))
    m["E7004"] = ErrorMeta(code: "E7004", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试中出现 panic", fix: Some(FixSuggestion(description: "修复被测逻辑")))
    m["E7005"] = ErrorMeta(code: "E7005", category: ErrorCategory.Test, severity: Severity.Error,
        template: "断言失败：{msg}", fix: Some(FixSuggestion(description: "检查预期与实际")))
    m["E7006"] = ErrorMeta(code: "E7006", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试夹具（fixture）初始化失败", fix: Some(FixSuggestion(description: "检查夹具逻辑")))
    m["E7007"] = ErrorMeta(code: "E7007", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试清理（teardown）失败", fix: Some(FixSuggestion(description: "检查清理逻辑")))
    m["E7008"] = ErrorMeta(code: "E7008", category: ErrorCategory.Test, severity: Severity.Warning,
        template: "测试过滤器未匹配任何用例", fix: Some(FixSuggestion(description: "检查过滤表达式")))
    m["E7009"] = ErrorMeta(code: "E7009", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试用例名重复：{name}", fix: Some(FixSuggestion(description: "重命名用例")))
    m["E7010"] = ErrorMeta(code: "E7010", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试依赖顺序错误", fix: Some(FixSuggestion(description: "显式声明依赖")))
    m["E7011"] = ErrorMeta(code: "E7011", category: ErrorCategory.Test, severity: Severity.Warning,
        template: "测试泄漏资源", fix: Some(FixSuggestion(description: "在 teardown 释放")))
    m["E7012"] = ErrorMeta(code: "E7012", category: ErrorCategory.Test, severity: Severity.Warning,
        template: "测试用例被忽略（ignore）", fix: Some(FixSuggestion(description: "检查忽略条件")))
    m["E7013"] = ErrorMeta(code: "E7013", category: ErrorCategory.Test, severity: Severity.Error,
        template: "期望 panic 但未发生", fix: Some(FixSuggestion(description: "修正预期")))
    m["E7014"] = ErrorMeta(code: "E7014", category: ErrorCategory.Test, severity: Severity.Error,
        template: "未期望的 panic 发生", fix: Some(FixSuggestion(description: "修复被测代码")))
    m["E7015"] = ErrorMeta(code: "E7015", category: ErrorCategory.Test, severity: Severity.Warning,
        template: "测试不稳定（flaky）", fix: Some(FixSuggestion(description: "消除时序依赖")))
    m["E7016"] = ErrorMeta(code: "E7016", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试框架崩溃", fix: Some(FixSuggestion(description: "升级测试框架")))
    m["E7017"] = ErrorMeta(code: "E7017", category: ErrorCategory.Test, severity: Severity.Warning,
        template: "测试输出捕获失败", fix: Some(FixSuggestion(description: "检查输出重定向")))
    m["E7018"] = ErrorMeta(code: "E7018", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试所需环境变量缺失", fix: Some(FixSuggestion(description: "设置环境变量")))
    m["E7019"] = ErrorMeta(code: "E7019", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试数据文件缺失：{path}", fix: Some(FixSuggestion(description: "补充测试数据")))
    m["E7020"] = ErrorMeta(code: "E7020", category: ErrorCategory.Test, severity: Severity.Error,
        template: "Mock 对象行为不匹配", fix: Some(FixSuggestion(description: "修正 mock 设定")))
    m["E7021"] = ErrorMeta(code: "E7021", category: ErrorCategory.Test, severity: Severity.Error,
        template: "并发测试竞态", fix: Some(FixSuggestion(description: "使用同步原语")))
    m["E7022"] = ErrorMeta(code: "E7022", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试内部死锁", fix: Some(FixSuggestion(description: "检查加锁顺序")))
    m["E7023"] = ErrorMeta(code: "E7023", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试触发泄漏检测", fix: Some(FixSuggestion(description: "释放测试资源")))
    m["E7024"] = ErrorMeta(code: "E7024", category: ErrorCategory.Test, severity: Severity.Warning,
        template: "覆盖率采集失败", fix: Some(FixSuggestion(description: "检查插桩")))
    m["E7025"] = ErrorMeta(code: "E7025", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试报告生成失败", fix: Some(FixSuggestion(description: "检查报告路径")))
    m["E7026"] = ErrorMeta(code: "E7026", category: ErrorCategory.Test, severity: Severity.Error,
        template: "并行测试共享状态冲突", fix: Some(FixSuggestion(description: "隔离测试状态")))
    m["E7027"] = ErrorMeta(code: "E7027", category: ErrorCategory.Test, severity: Severity.Error,
        template: "全局前置（before-all）失败", fix: Some(FixSuggestion(description: "检查前置逻辑")))
    m["E7028"] = ErrorMeta(code: "E7028", category: ErrorCategory.Test, severity: Severity.Error,
        template: "全局后置（after-all）失败", fix: Some(FixSuggestion(description: "检查后置逻辑")))
    m["E7029"] = ErrorMeta(code: "E7029", category: ErrorCategory.Test, severity: Severity.Warning,
        template: "测试跳过条件误触发", fix: Some(FixSuggestion(description: "检查跳过逻辑")))
    m["E7030"] = ErrorMeta(code: "E7030", category: ErrorCategory.Test, severity: Severity.Error,
        template: "参数化测试参数不匹配", fix: Some(FixSuggestion(description: "检查参数集")))
    m["E7031"] = ErrorMeta(code: "E7031", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试超时配置非法", fix: Some(FixSuggestion(description: "使用合法超时")))
    m["E7032"] = ErrorMeta(code: "E7032", category: ErrorCategory.Test, severity: Severity.Fatal,
        template: "测试进程崩溃", fix: Some(FixSuggestion(description: "检查被测代码")))
    m["E7033"] = ErrorMeta(code: "E7033", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试收到意外信号", fix: Some(FixSuggestion(description: "检查信号处理")))
    m["E7034"] = ErrorMeta(code: "E7034", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试超过内存限制", fix: Some(FixSuggestion(description: "减少内存使用")))
    m["E7035"] = ErrorMeta(code: "E7035", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试间未隔离导致相互影响", fix: Some(FixSuggestion(description: "隔离测试环境")))
    m["E7036"] = ErrorMeta(code: "E7036", category: ErrorCategory.Test, severity: Severity.Warning,
        template: "随机测试种子未固定导致不稳定", fix: Some(FixSuggestion(description: "固定随机种子")))
    m["E7037"] = ErrorMeta(code: "E7037", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试辅助模块导入失败", fix: Some(FixSuggestion(description: "检查测试路径")))
    m["E7038"] = ErrorMeta(code: "E7038", category: ErrorCategory.Test, severity: Severity.Warning,
        template: "未知测试属性（attr）", fix: Some(FixSuggestion(description: "移除无效属性")))
    m["E7039"] = ErrorMeta(code: "E7039", category: ErrorCategory.Test, severity: Severity.Warning,
        template: "同一用例被执行两次", fix: Some(FixSuggestion(description: "检查测试发现逻辑")))
    m["E7040"] = ErrorMeta(code: "E7040", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试汇总信息丢失", fix: Some(FixSuggestion(description: "检查输出通道")))
    m["E7041"] = ErrorMeta(code: "E7041", category: ErrorCategory.Test, severity: Severity.Error,
        template: "测试挂起（hang）", fix: Some(FixSuggestion(description: "检查阻塞调用")))
    m["E7101"] = ErrorMeta(code: "E7101", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档存在断链：{url}", fix: Some(FixSuggestion(description: "修正链接地址")))
    m["E7102"] = ErrorMeta(code: "E7102", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档引用的条目不存在：{name}", fix: Some(FixSuggestion(description: "补充条目或修正引用")))
    m["E7103"] = ErrorMeta(code: "E7103", category: ErrorCategory.Doc, severity: Severity.Error,
        template: "文档代码块（rust/cangjie）执行失败", fix: Some(FixSuggestion(description: "修正示例代码")))
    m["E7104"] = ErrorMeta(code: "E7104", category: ErrorCategory.Doc, severity: Severity.Error,
        template: "文档测试（doctest）失败", fix: Some(FixSuggestion(description: "修正文档示例")))
    m["E7105"] = ErrorMeta(code: "E7105", category: ErrorCategory.Doc, severity: Severity.Error,
        template: "文档示例 panic", fix: Some(FixSuggestion(description: "修正示例逻辑")))
    m["E7106"] = ErrorMeta(code: "E7106", category: ErrorCategory.Doc, severity: Severity.Error,
        template: "文档示例编译失败", fix: Some(FixSuggestion(description: "修复示例代码")))
    m["E7107"] = ErrorMeta(code: "E7107", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档属性非法", fix: Some(FixSuggestion(description: "修正文档属性")))
    m["E7108"] = ErrorMeta(code: "E7108", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档模块引用循环", fix: Some(FixSuggestion(description: "打破文档循环")))
    m["E7109"] = ErrorMeta(code: "E7109", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档泄露了私有项", fix: Some(FixSuggestion(description: "调整可见性或 #[doc(hidden)]")))
    m["E7110"] = ErrorMeta(code: "E7110", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档 HTML 转义失败", fix: Some(FixSuggestion(description: "检查特殊字符")))
    m["E7111"] = ErrorMeta(code: "E7111", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档缺少摘要（summary）", fix: Some(FixSuggestion(description: "补充条目首句")))
    m["E7112"] = ErrorMeta(code: "E7112", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档内部链接（intra-doc）失效", fix: Some(FixSuggestion(description: "修正内部路径")))
    m["E7113"] = ErrorMeta(code: "E7113", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档别名冲突", fix: Some(FixSuggestion(description: "统一文档别名")))
    m["E7114"] = ErrorMeta(code: "E7114", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档搜索索引生成失败", fix: Some(FixSuggestion(description: "检查文档结构")))
    m["E7115"] = ErrorMeta(code: "E7115", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档主题渲染失败", fix: Some(FixSuggestion(description: "使用默认主题")))
    m["E7116"] = ErrorMeta(code: "E7116", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档资源（图片/JS）缺失", fix: Some(FixSuggestion(description: "补充资源文件")))
    m["E7117"] = ErrorMeta(code: "E7117", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档注释过长", fix: Some(FixSuggestion(description: "精简文档")))
    m["E7118"] = ErrorMeta(code: "E7118", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档路径含非 ASCII 字符", fix: Some(FixSuggestion(description: "使用 ASCII 路径")))
    m["E7119"] = ErrorMeta(code: "E7119", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档版本与代码不一致", fix: Some(FixSuggestion(description: "同步文档版本")))
    m["E7120"] = ErrorMeta(code: "E7120", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档示例已过时", fix: Some(FixSuggestion(description: "更新示例")))
    m["E7121"] = ErrorMeta(code: "E7121", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档 Markdown 语法非法", fix: Some(FixSuggestion(description: "修正 Markdown")))
    m["E7122"] = ErrorMeta(code: "E7122", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档表格格式错误", fix: Some(FixSuggestion(description: "修正表格")))
    m["E7123"] = ErrorMeta(code: "E7123", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档代码块语言未知", fix: Some(FixSuggestion(description: "指定已知语言")))
    m["E7124"] = ErrorMeta(code: "E7124", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档重定向循环", fix: Some(FixSuggestion(description: "修正重定向")))
    m["E7125"] = ErrorMeta(code: "E7125", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "跨 crate 文档链接失效", fix: Some(FixSuggestion(description: "检查外部文档")))
    m["E7126"] = ErrorMeta(code: "E7126", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档特性未开启导致缺失", fix: Some(FixSuggestion(description: "开启文档特性")))
    m["E7127"] = ErrorMeta(code: "E7127", category: ErrorCategory.Doc, severity: Severity.Error,
        template: "文档 JSON 输出生成失败", fix: Some(FixSuggestion(description: "检查文档结构")))
    m["E7128"] = ErrorMeta(code: "E7128", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档测试编译超时", fix: Some(FixSuggestion(description: "简化示例")))
    m["E7129"] = ErrorMeta(code: "E7129", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档引用了隐藏项", fix: Some(FixSuggestion(description: "取消隐藏或移除引用")))
    m["E7130"] = ErrorMeta(code: "E7130", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "文档锚点（anchor）重复", fix: Some(FixSuggestion(description: "修正标题层级")))
    m["E7131"] = ErrorMeta(code: "E7131", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "宏文档生成异常", fix: Some(FixSuggestion(description: "检查宏文档注释")))
    m["E7132"] = ErrorMeta(code: "E7132", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "trait 实现的文档缺失", fix: Some(FixSuggestion(description: "补充 impl 文档")))
    m["E7133"] = ErrorMeta(code: "E7133", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "泛型参数文档未渲染", fix: Some(FixSuggestion(description: "检查泛型标注")))
    m["E7134"] = ErrorMeta(code: "E7134", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "cfg 过滤导致文档缺失", fix: Some(FixSuggestion(description: "检查 cfg 条件")))
    m["E7135"] = ErrorMeta(code: "E7135", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "平台特定文档缺失", fix: Some(FixSuggestion(description: "补充平台文档")))
    m["E7136"] = ErrorMeta(code: "E7136", category: ErrorCategory.Doc, severity: Severity.Error,
        template: "文档 include! 文件失败", fix: Some(FixSuggestion(description: "检查包含路径")))
    m["E7137"] = ErrorMeta(code: "E7137", category: ErrorCategory.Doc, severity: Severity.Warning,
        template: "教学文档（rust-by-example 类）链接失效", fix: Some(FixSuggestion(description: "修正链接")))
    m["E7201"] = ErrorMeta(code: "E7201", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "变量 {name} 未使用", fix: Some(FixSuggestion(description: "删除或前缀 _")))
    m["E7202"] = ErrorMeta(code: "E7202", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "导入 {name} 未使用", fix: Some(FixSuggestion(description: "移除未使用导入")))
    m["E7203"] = ErrorMeta(code: "E7203", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "函数 {name} 未使用", fix: Some(FixSuggestion(description: "删除或 pub 导出")))
    m["E7204"] = ErrorMeta(code: "E7204", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "死代码（不可达）", fix: Some(FixSuggestion(description: "移除死代码")))
    m["E7205"] = ErrorMeta(code: "E7205", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "使用了已废弃 API：{name}", fix: Some(FixSuggestion(description: "迁移到新 API")))
    m["E7206"] = ErrorMeta(code: "E7206", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "命名不符合 snake_case：{name}", fix: Some(FixSuggestion(description: "使用 snake_case")))
    m["E7207"] = ErrorMeta(code: "E7207", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "类型命名不符合 CamelCase：{name}", fix: Some(FixSuggestion(description: "使用 CamelCase")))
    m["E7208"] = ErrorMeta(code: "E7208", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "常量命名未全大写：{name}", fix: Some(FixSuggestion(description: "使用 UPPER_CASE")))
    m["E7209"] = ErrorMeta(code: "E7209", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "硬编码路径：{path}", fix: Some(FixSuggestion(description: "使用配置或常量")))
    m["E7210"] = ErrorMeta(code: "E7210", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "使用了魔术数字：{value}", fix: Some(FixSuggestion(description: "提取为具名常量")))
    m["E7211"] = ErrorMeta(code: "E7211", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "遗留 TODO/FIXME 注释", fix: Some(FixSuggestion(description: "完成或登记任务")))
    m["E7212"] = ErrorMeta(code: "E7212", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "使用了 print 调试语句", fix: Some(FixSuggestion(description: "改用日志")))
    m["E7213"] = ErrorMeta(code: "E7213", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "存在 unsafe 块（需审查）", fix: Some(FixSuggestion(description: "确认 unsafe 必要性")))
    m["E7214"] = ErrorMeta(code: "E7214", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "在循环中不必要的 clone", fix: Some(FixSuggestion(description: "移出循环或借用")))
    m["E7215"] = ErrorMeta(code: "E7215", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "函数复杂度过高", fix: Some(FixSuggestion(description: "拆分函数")))
    m["E7216"] = ErrorMeta(code: "E7216", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "函数参数过多（{n}）", fix: Some(FixSuggestion(description: "使用结构体聚合参数")))
    m["E7217"] = ErrorMeta(code: "E7217", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "嵌套层级过深", fix: Some(FixSuggestion(description: "提前返回扁平化")))
    m["E7218"] = ErrorMeta(code: "E7218", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "单行过长（{n} 字符）", fix: Some(FixSuggestion(description: "拆分长行")))
    m["E7219"] = ErrorMeta(code: "E7219", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "公共项缺少文档注释", fix: Some(FixSuggestion(description: "补充文档")))
    m["E7220"] = ErrorMeta(code: "E7220", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "可传引用却发生了拷贝", fix: Some(FixSuggestion(description: "改为引用传递")))
    m["E7221"] = ErrorMeta(code: "E7221", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "使用了通配导入（*）", fix: Some(FixSuggestion(description: "改为显式导入")))
    m["E7222"] = ErrorMeta(code: "E7222", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "match 存在不可达分支", fix: Some(FixSuggestion(description: "移除不可达分支")))
    m["E7223"] = ErrorMeta(code: "E7223", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "let-else 非穷尽", fix: Some(FixSuggestion(description: "补全处理分支")))
    m["E7224"] = ErrorMeta(code: "E7224", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "冗余的 clone 调用", fix: Some(FixSuggestion(description: "移除冗余 clone")))
    m["E7225"] = ErrorMeta(code: "E7225", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "变量遮蔽（shadowing）", fix: Some(FixSuggestion(description: "重命名以避免混淆")))
    m["E7226"] = ErrorMeta(code: "E7226", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "变量声明为 mut 但从未修改", fix: Some(FixSuggestion(description: "移除 mut")))
    m["E7227"] = ErrorMeta(code: "E7227", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "不必要的可变借用", fix: Some(FixSuggestion(description: "改为不可变借用")))
    m["E7228"] = ErrorMeta(code: "E7228", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "低效的字符串转换", fix: Some(FixSuggestion(description: "使用更高效的格式化")))
    m["E7229"] = ErrorMeta(code: "E7229", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "生产代码中存在 panic", fix: Some(FixSuggestion(description: "改用错误返回")))
    m["E7230"] = ErrorMeta(code: "E7230", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "直接比较浮点相等", fix: Some(FixSuggestion(description: "使用容差比较")))
    m["E7231"] = ErrorMeta(code: "E7231", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "使用了 unwrap（可能 panic）", fix: Some(FixSuggestion(description: "使用安全的解包方式")))
    m["E7232"] = ErrorMeta(code: "E7232", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "使用了 expect（可能 panic）", fix: Some(FixSuggestion(description: "处理错误分支")))
    m["E7233"] = ErrorMeta(code: "E7233", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "未检查越界的索引访问", fix: Some(FixSuggestion(description: "使用 checked 访问")))
    m["E7234"] = ErrorMeta(code: "E7234", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "在迭代中持有值引用导致冲突", fix: Some(FixSuggestion(description: "调整迭代方式")))
    m["E7235"] = ErrorMeta(code: "E7235", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "枚举变体过大（内存不均）", fix: Some(FixSuggestion(description: "使用 Box 装箱大字段")))
    m["E7236"] = ErrorMeta(code: "E7236", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "对解引用结果多余 clone", fix: Some(FixSuggestion(description: "直接使用引用")))
    m["E7237"] = ErrorMeta(code: "E7237", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "冗余的字段初始化", fix: Some(FixSuggestion(description: "移除冗余字段")))
    m["E7238"] = ErrorMeta(code: "E7238", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "不符合惯用写法", fix: Some(FixSuggestion(description: "采用惯用表达")))
    m["E7239"] = ErrorMeta(code: "E7239", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "代码风格违规", fix: Some(FixSuggestion(description: "运行格式化器")))
    m["E7240"] = ErrorMeta(code: "E7240", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "可安全替代 unsafe 的写法", fix: Some(FixSuggestion(description: "改用安全 API")))
    m["E7241"] = ErrorMeta(code: "E7241", category: ErrorCategory.Lint, severity: Severity.Warning,
        template: "可能存在逻辑缺陷的模式", fix: Some(FixSuggestion(description: "人工复核")))
    m["E7301"] = ErrorMeta(code: "E7301", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "检测到硬编码密钥/口令", fix: Some(FixSuggestion(description: "改用环境变量或密钥管理")))
    m["E7302"] = ErrorMeta(code: "E7302", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "可能存在 SQL 注入风险", fix: Some(FixSuggestion(description: "使用参数化查询")))
    m["E7303"] = ErrorMeta(code: "E7303", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "可能存在命令注入风险", fix: Some(FixSuggestion(description: "校验外部输入")))
    m["E7304"] = ErrorMeta(code: "E7304", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "可能存在路径穿越（traversal）", fix: Some(FixSuggestion(description: "规范化路径并校验")))
    m["E7305"] = ErrorMeta(code: "E7305", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "不安全的反序列化", fix: Some(FixSuggestion(description: "使用受信任格式")))
    m["E7306"] = ErrorMeta(code: "E7306", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "使用了弱加密算法：{algo}", fix: Some(FixSuggestion(description: "改用强加密")))
    m["E7307"] = ErrorMeta(code: "E7307", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "使用了不安全随机数源", fix: Some(FixSuggestion(description: "使用密码学安全随机")))
    m["E7308"] = ErrorMeta(code: "E7308", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "关闭了 TLS 证书校验", fix: Some(FixSuggestion(description: "启用证书校验")))
    m["E7309"] = ErrorMeta(code: "E7309", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "明文传输敏感数据", fix: Some(FixSuggestion(description: "使用加密通道")))
    m["E7310"] = ErrorMeta(code: "E7310", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "执行了不可信的动态代码", fix: Some(FixSuggestion(description: "避免动态执行")))
    m["E7311"] = ErrorMeta(code: "E7311", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "潜在的缓冲区溢出", fix: Some(FixSuggestion(description: "使用边界检查")))
    m["E7312"] = ErrorMeta(code: "E7312", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "格式化字符串可能受控", fix: Some(FixSuggestion(description: "使用静态格式串")))
    m["E7313"] = ErrorMeta(code: "E7313", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "整数溢出可能被利用", fix: Some(FixSuggestion(description: "使用饱和/检查运算")))
    m["E7314"] = ErrorMeta(code: "E7314", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "存在竞态条件风险", fix: Some(FixSuggestion(description: "使用同步保护")))
    m["E7315"] = ErrorMeta(code: "E7315", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "潜在的释放后使用", fix: Some(FixSuggestion(description: "延长所有者生命周期")))
    m["E7316"] = ErrorMeta(code: "E7316", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "潜在的重复释放", fix: Some(FixSuggestion(description: "确保每个分配释放一次")))
    m["E7317"] = ErrorMeta(code: "E7317", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "潜在的空指针解引用", fix: Some(FixSuggestion(description: "使用前判空")))
    m["E7318"] = ErrorMeta(code: "E7318", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "日志可能泄露敏感信息", fix: Some(FixSuggestion(description: "脱敏日志")))
    m["E7319"] = ErrorMeta(code: "E7319", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "使用了可预测的临时文件名", fix: Some(FixSuggestion(description: "使用安全临时文件")))
    m["E7320"] = ErrorMeta(code: "E7320", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "存在符号链接攻击风险", fix: Some(FixSuggestion(description: "使用真实路径校验")))
    m["E7321"] = ErrorMeta(code: "E7321", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "不安全的类型转换", fix: Some(FixSuggestion(description: "使用安全转换")))
    m["E7322"] = ErrorMeta(code: "E7322", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "可能泄露内存内容", fix: Some(FixSuggestion(description: "清零敏感缓冲区")))
    m["E7323"] = ErrorMeta(code: "E7323", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "缺少授权检查", fix: Some(FixSuggestion(description: "补充授权逻辑")))
    m["E7324"] = ErrorMeta(code: "E7324", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "缺少身份认证", fix: Some(FixSuggestion(description: "补充认证逻辑")))
    m["E7325"] = ErrorMeta(code: "E7325", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "存在 CSRF 风险", fix: Some(FixSuggestion(description: "添加令牌校验")))
    m["E7326"] = ErrorMeta(code: "E7326", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "存在 XSS 风险", fix: Some(FixSuggestion(description: "转义输出")))
    m["E7327"] = ErrorMeta(code: "E7327", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "Cookie 安全属性缺失", fix: Some(FixSuggestion(description: "设置 Secure/HttpOnly")))
    m["E7328"] = ErrorMeta(code: "E7328", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "开放重定向风险", fix: Some(FixSuggestion(description: "校验重定向目标")))
    m["E7329"] = ErrorMeta(code: "E7329", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "不安全的反射/动态调用", fix: Some(FixSuggestion(description: "限制可调用集合")))
    m["E7330"] = ErrorMeta(code: "E7330", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "依赖存在已知漏洞", fix: Some(FixSuggestion(description: "升级依赖版本")))
    m["E7331"] = ErrorMeta(code: "E7331", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "请求了过度权限", fix: Some(FixSuggestion(description: "按最小权限原则收敛")))
    m["E7332"] = ErrorMeta(code: "E7332", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "密钥长度过短", fix: Some(FixSuggestion(description: "增大密钥长度")))
    m["E7333"] = ErrorMeta(code: "E7333", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "使用了弱哈希（如 MD5/SHA1）", fix: Some(FixSuggestion(description: "改用 SHA-256+")))
    m["E7334"] = ErrorMeta(code: "E7334", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "使用了弱分组模式（如 ECB）", fix: Some(FixSuggestion(description: "改用 GCM/CBC")))
    m["E7335"] = ErrorMeta(code: "E7335", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "检测到 nonce 重用", fix: Some(FixSuggestion(description: "每次使用唯一 nonce")))
    m["E7336"] = ErrorMeta(code: "E7336", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "证书已过期", fix: Some(FixSuggestion(description: "更新证书")))
    m["E7337"] = ErrorMeta(code: "E7337", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "使用了不安全协议（如 HTTP/TLS1.0）", fix: Some(FixSuggestion(description: "升级到安全协议")))
    m["E7338"] = ErrorMeta(code: "E7338", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "未降权运行（以高权限常驻）", fix: Some(FixSuggestion(description: "降权到最小权限")))
    m["E7339"] = ErrorMeta(code: "E7339", category: ErrorCategory.Sec, severity: Severity.Warning,
        template: "错误信息可能泄露内部细节", fix: Some(FixSuggestion(description: "返回通用错误")))
}

/// 填充错误码元数据第 8 组（Conf .. Gpu），共 5 个类别。
func buildMetaPart8(m: HashMap<String, ErrorMeta>) {
    m["E7401"] = ErrorMeta(code: "E7401", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置文件未找到：{path}", fix: Some(FixSuggestion(description: "创建配置文件")))
    m["E7402"] = ErrorMeta(code: "E7402", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置解析失败：{reason}", fix: Some(FixSuggestion(description: "修正配置语法")))
    m["E7403"] = ErrorMeta(code: "E7403", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置不符合 schema", fix: Some(FixSuggestion(description: "对照 schema 修正")))
    m["E7404"] = ErrorMeta(code: "E7404", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "未知配置项：{key}", fix: Some(FixSuggestion(description: "删除或更正配置项")))
    m["E7405"] = ErrorMeta(code: "E7405", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置项类型不匹配：期望 {expected}", fix: Some(FixSuggestion(description: "使用正确类型")))
    m["E7406"] = ErrorMeta(code: "E7406", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "缺少必填配置项：{key}", fix: Some(FixSuggestion(description: "补充必填项")))
    m["E7407"] = ErrorMeta(code: "E7407", category: ErrorCategory.Conf, severity: Severity.Warning,
        template: "配置项已废弃：{key}", fix: Some(FixSuggestion(description: "迁移到新配置")))
    m["E7408"] = ErrorMeta(code: "E7408", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置项相互冲突", fix: Some(FixSuggestion(description: "统一配置值")))
    m["E7409"] = ErrorMeta(code: "E7409", category: ErrorCategory.Conf, severity: Severity.Warning,
        template: "环境变量覆盖配置失败", fix: Some(FixSuggestion(description: "检查环境变量名")))
    m["E7410"] = ErrorMeta(code: "E7410", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "未知配置档（profile）：{profile}", fix: Some(FixSuggestion(description: "使用合法 profile")))
    m["E7411"] = ErrorMeta(code: "E7411", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置 include 失败：{path}", fix: Some(FixSuggestion(description: "检查包含路径")))
    m["E7412"] = ErrorMeta(code: "E7412", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置引用形成循环", fix: Some(FixSuggestion(description: "打破配置循环")))
    m["E7413"] = ErrorMeta(code: "E7413", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置文件无读取权限", fix: Some(FixSuggestion(description: "修正文件权限")))
    m["E7414"] = ErrorMeta(code: "E7414", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置文件编码非法", fix: Some(FixSuggestion(description: "使用 UTF-8")))
    m["E7415"] = ErrorMeta(code: "E7415", category: ErrorCategory.Conf, severity: Severity.Warning,
        template: "配置文件过大", fix: Some(FixSuggestion(description: "拆分配置")))
    m["E7416"] = ErrorMeta(code: "E7416", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置校验失败", fix: Some(FixSuggestion(description: "检查校验规则")))
    m["E7417"] = ErrorMeta(code: "E7417", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "默认值非法", fix: Some(FixSuggestion(description: "修正默认值")))
    m["E7418"] = ErrorMeta(code: "E7418", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置值超出范围", fix: Some(FixSuggestion(description: "使用范围内值")))
    m["E7419"] = ErrorMeta(code: "E7419", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置枚举值非法", fix: Some(FixSuggestion(description: "使用合法枚举值")))
    m["E7420"] = ErrorMeta(code: "E7420", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置路径非法：{path}", fix: Some(FixSuggestion(description: "使用合法路径")))
    m["E7421"] = ErrorMeta(code: "E7421", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置 URL 非法", fix: Some(FixSuggestion(description: "使用合法 URL")))
    m["E7422"] = ErrorMeta(code: "E7422", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置超时值非法", fix: Some(FixSuggestion(description: "使用合法超时")))
    m["E7423"] = ErrorMeta(code: "E7423", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "特性配置冲突", fix: Some(FixSuggestion(description: "统一特性开关")))
    m["E7424"] = ErrorMeta(code: "E7424", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置与目标不匹配", fix: Some(FixSuggestion(description: "检查目标配置")))
    m["E7425"] = ErrorMeta(code: "E7425", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "运行期配置与启动期不一致", fix: Some(FixSuggestion(description: "统一配置来源")))
    m["E7426"] = ErrorMeta(code: "E7426", category: ErrorCategory.Conf, severity: Severity.Warning,
        template: "配置热加载失败", fix: Some(FixSuggestion(description: "检查配置变更")))
    m["E7427"] = ErrorMeta(code: "E7427", category: ErrorCategory.Conf, severity: Severity.Warning,
        template: "配置可能包含密钥明文", fix: Some(FixSuggestion(description: "改用密钥引用")))
    m["E7428"] = ErrorMeta(code: "E7428", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "未知配置格式", fix: Some(FixSuggestion(description: "使用受支持格式")))
    m["E7429"] = ErrorMeta(code: "E7429", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "多来源配置合并冲突", fix: Some(FixSuggestion(description: "明确合并优先级")))
    m["E7430"] = ErrorMeta(code: "E7430", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置版本不兼容", fix: Some(FixSuggestion(description: "迁移配置版本")))
    m["E7431"] = ErrorMeta(code: "E7431", category: ErrorCategory.Conf, severity: Severity.Warning,
        template: "配置含不安全值", fix: Some(FixSuggestion(description: "审查配置值")))
    m["E7432"] = ErrorMeta(code: "E7432", category: ErrorCategory.Conf, severity: Severity.Warning,
        template: "配置项冗余", fix: Some(FixSuggestion(description: "移除冗余项")))
    m["E7433"] = ErrorMeta(code: "E7433", category: ErrorCategory.Conf, severity: Severity.Warning,
        template: "配置项缺少说明", fix: Some(FixSuggestion(description: "补充配置文档")))
    m["E7434"] = ErrorMeta(code: "E7434", category: ErrorCategory.Conf, severity: Severity.Warning,
        template: "配置类型强制转换丢失精度", fix: Some(FixSuggestion(description: "使用精确类型")))
    m["E7435"] = ErrorMeta(code: "E7435", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置含未替换的占位符", fix: Some(FixSuggestion(description: "补全占位符")))
    m["E7436"] = ErrorMeta(code: "E7436", category: ErrorCategory.Conf, severity: Severity.Warning,
        template: "条件配置不满足分支", fix: Some(FixSuggestion(description: "检查条件")))
    m["E7437"] = ErrorMeta(code: "E7437", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置被锁定不可修改", fix: Some(FixSuggestion(description: "解除锁定或新开配置")))
    m["E7438"] = ErrorMeta(code: "E7438", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置依赖的环境变量缺失", fix: Some(FixSuggestion(description: "设置环境变量")))
    m["E7439"] = ErrorMeta(code: "E7439", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置布尔值非法", fix: Some(FixSuggestion(description: "使用 true/false")))
    m["E7440"] = ErrorMeta(code: "E7440", category: ErrorCategory.Conf, severity: Severity.Error,
        template: "配置列表为空（需至少一项）", fix: Some(FixSuggestion(description: "补充列表项")))
    m["E7501"] = ErrorMeta(code: "E7501", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测被禁用", fix: Some(FixSuggestion(description: "启用遥测以采集")))
    m["E7502"] = ErrorMeta(code: "E7502", category: ErrorCategory.Telem, severity: Severity.Error,
        template: "遥测初始化失败", fix: Some(FixSuggestion(description: "检查遥测配置")))
    m["E7503"] = ErrorMeta(code: "E7503", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测导出失败", fix: Some(FixSuggestion(description: "检查导出端点")))
    m["E7504"] = ErrorMeta(code: "E7504", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测队列已满（丢弃数据）", fix: Some(FixSuggestion(description: "增大队列或降采样")))
    m["E7505"] = ErrorMeta(code: "E7505", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测上报超时", fix: Some(FixSuggestion(description: "增大超时或降频")))
    m["E7506"] = ErrorMeta(code: "E7506", category: ErrorCategory.Telem, severity: Severity.Error,
        template: "遥测端点鉴权失败", fix: Some(FixSuggestion(description: "检查凭证")))
    m["E7507"] = ErrorMeta(code: "E7507", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测端点不可达", fix: Some(FixSuggestion(description: "检查网络")))
    m["E7508"] = ErrorMeta(code: "E7508", category: ErrorCategory.Telem, severity: Severity.Error,
        template: "遥测数据 schema 非法", fix: Some(FixSuggestion(description: "修正数据格式")))
    m["E7509"] = ErrorMeta(code: "E7509", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "追踪（trace）跨度被丢弃", fix: Some(FixSuggestion(description: "调整采样率")))
    m["E7510"] = ErrorMeta(code: "E7510", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测缺少上下文（trace_id）", fix: Some(FixSuggestion(description: "注入上下文")))
    m["E7511"] = ErrorMeta(code: "E7511", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测标签基数过高", fix: Some(FixSuggestion(description: "降低标签维度")))
    m["E7512"] = ErrorMeta(code: "E7512", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测可能泄露个人数据", fix: Some(FixSuggestion(description: "脱敏遥测")))
    m["E7513"] = ErrorMeta(code: "E7513", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "重复上报遥测", fix: Some(FixSuggestion(description: "去重上报")))
    m["E7514"] = ErrorMeta(code: "E7514", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测时钟偏差", fix: Some(FixSuggestion(description: "同步时钟")))
    m["E7515"] = ErrorMeta(code: "E7515", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测缓冲刷新失败", fix: Some(FixSuggestion(description: "检查存储")))
    m["E7516"] = ErrorMeta(code: "E7516", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测占用内存过高", fix: Some(FixSuggestion(description: "限制遥测内存")))
    m["E7517"] = ErrorMeta(code: "E7517", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测配置不完整", fix: Some(FixSuggestion(description: "补全遥测配置")))
    m["E7518"] = ErrorMeta(code: "E7518", category: ErrorCategory.Telem, severity: Severity.Error,
        template: "遥测协议版本不匹配", fix: Some(FixSuggestion(description: "对齐协议版本")))
    m["E7519"] = ErrorMeta(code: "E7519", category: ErrorCategory.Telem, severity: Severity.Error,
        template: "采样器配置非法", fix: Some(FixSuggestion(description: "使用合法采样率")))
    m["E7520"] = ErrorMeta(code: "E7520", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测属性值过长", fix: Some(FixSuggestion(description: "截断属性")))
    m["E7521"] = ErrorMeta(code: "E7521", category: ErrorCategory.Telem, severity: Severity.Error,
        template: "遥测指标名非法", fix: Some(FixSuggestion(description: "使用合法命名")))
    m["E7522"] = ErrorMeta(code: "E7522", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "指标被丢弃", fix: Some(FixSuggestion(description: "检查导出管道")))
    m["E7523"] = ErrorMeta(code: "E7523", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "结构化日志导出失败", fix: Some(FixSuggestion(description: "检查日志端点")))
    m["E7524"] = ErrorMeta(code: "E7524", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "崩溃未生成遥测报告", fix: Some(FixSuggestion(description: "启用崩溃上报")))
    m["E7525"] = ErrorMeta(code: "E7525", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测被限流", fix: Some(FixSuggestion(description: "降低上报频率")))
    m["E7526"] = ErrorMeta(code: "E7526", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测属性含密钥", fix: Some(FixSuggestion(description: "移除敏感属性")))
    m["E7527"] = ErrorMeta(code: "E7527", category: ErrorCategory.Telem, severity: Severity.Error,
        template: "遥测导出被网络策略拦截", fix: Some(FixSuggestion(description: "配置网络策略")))
    m["E7528"] = ErrorMeta(code: "E7528", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测产生背压（backpressure）", fix: Some(FixSuggestion(description: "降采样")))
    m["E7529"] = ErrorMeta(code: "E7529", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "追踪跨度无父节点", fix: Some(FixSuggestion(description: "建立跨度关系")))
    m["E7530"] = ErrorMeta(code: "E7530", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测迟到被丢弃", fix: Some(FixSuggestion(description: "增大等待窗口")))
    m["E7531"] = ErrorMeta(code: "E7531", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测存储已满", fix: Some(FixSuggestion(description: "清理或扩容")))
    m["E7532"] = ErrorMeta(code: "E7532", category: ErrorCategory.Telem, severity: Severity.Error,
        template: "遥测序列化失败", fix: Some(FixSuggestion(description: "检查数据格式")))
    m["E7533"] = ErrorMeta(code: "E7533", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测批量发送失败", fix: Some(FixSuggestion(description: "重试发送")))
    m["E7534"] = ErrorMeta(code: "E7534", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "未配置遥测收集器", fix: Some(FixSuggestion(description: "配置 collector")))
    m["E7535"] = ErrorMeta(code: "E7535", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测前后不一致", fix: Some(FixSuggestion(description: "统一采集逻辑")))
    m["E7536"] = ErrorMeta(code: "E7536", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测所需特性未开启", fix: Some(FixSuggestion(description: "开启特性")))
    m["E7537"] = ErrorMeta(code: "E7537", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测违反隐私策略", fix: Some(FixSuggestion(description: "调整采集范围")))
    m["E7538"] = ErrorMeta(code: "E7538", category: ErrorCategory.Telem, severity: Severity.Warning,
        template: "遥测属性数量超限", fix: Some(FixSuggestion(description: "减少属性")))
    m["E7601"] = ErrorMeta(code: "E7601", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "交叉编译工具链缺失：{target}", fix: Some(FixSuggestion(description: "安装目标工具链")))
    m["E7602"] = ErrorMeta(code: "E7602", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "交叉编译 sysroot 缺失", fix: Some(FixSuggestion(description: "配置交叉 sysroot")))
    m["E7603"] = ErrorMeta(code: "E7603", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "交叉链接器缺失", fix: Some(FixSuggestion(description: "安装交叉链接器")))
    m["E7604"] = ErrorMeta(code: "E7604", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标平台库缺失", fix: Some(FixSuggestion(description: "提供目标库")))
    m["E7605"] = ErrorMeta(code: "E7605", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "交叉编译 ABI 不匹配", fix: Some(FixSuggestion(description: "统一 ABI")))
    m["E7606"] = ErrorMeta(code: "E7606", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标系统调用号不同", fix: Some(FixSuggestion(description: "使用目标 syscall 表")))
    m["E7607"] = ErrorMeta(code: "E7607", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标字节序不同", fix: Some(FixSuggestion(description: "处理字节序")))
    m["E7608"] = ErrorMeta(code: "E7608", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标指针宽度不同", fix: Some(FixSuggestion(description: "调整数据类型")))
    m["E7609"] = ErrorMeta(code: "E7609", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标 FPU 不同", fix: Some(FixSuggestion(description: "使用软浮点")))
    m["E7610"] = ErrorMeta(code: "E7610", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标无原子支持", fix: Some(FixSuggestion(description: "禁用原子或 fallback")))
    m["E7611"] = ErrorMeta(code: "E7611", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标 C 运行时缺失", fix: Some(FixSuggestion(description: "安装目标 CRT")))
    m["E7612"] = ErrorMeta(code: "E7612", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标展开模型不同", fix: Some(FixSuggestion(description: "使用目标展开策略")))
    m["E7613"] = ErrorMeta(code: "E7613", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "交叉编译环境不一致", fix: Some(FixSuggestion(description: "统一工具链")))
    m["E7614"] = ErrorMeta(code: "E7614", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "运行交叉测试所需 QEMU 缺失", fix: Some(FixSuggestion(description: "安装 QEMU")))
    m["E7615"] = ErrorMeta(code: "E7615", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "交叉编译产物无法在模拟器运行", fix: Some(FixSuggestion(description: "检查模拟器配置")))
    m["E7616"] = ErrorMeta(code: "E7616", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "依赖了宿主（host）专用功能", fix: Some(FixSuggestion(description: "改用目标可移植实现")))
    m["E7617"] = ErrorMeta(code: "E7617", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标路径分隔符不同", fix: Some(FixSuggestion(description: "使用跨平台路径")))
    m["E7618"] = ErrorMeta(code: "E7618", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标不支持动态加载", fix: Some(FixSuggestion(description: "改用静态链接")))
    m["E7619"] = ErrorMeta(code: "E7619", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标 TLS 模型不同", fix: Some(FixSuggestion(description: "使用兼容 TLS 模型")))
    m["E7620"] = ErrorMeta(code: "E7620", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标栈探测机制不同", fix: Some(FixSuggestion(description: "配置栈探测")))
    m["E7621"] = ErrorMeta(code: "E7621", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标代码模型不同", fix: Some(FixSuggestion(description: "使用目标代码模型")))
    m["E7622"] = ErrorMeta(code: "E7622", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标架构特性不可用", fix: Some(FixSuggestion(description: "禁用该特性")))
    m["E7623"] = ErrorMeta(code: "E7623", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "交叉链接脚本不匹配", fix: Some(FixSuggestion(description: "提供目标链接脚本")))
    m["E7624"] = ErrorMeta(code: "E7624", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标目标文件格式不同", fix: Some(FixSuggestion(description: "使用目标格式")))
    m["E7625"] = ErrorMeta(code: "E7625", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标调试格式不同", fix: Some(FixSuggestion(description: "使用目标调试格式")))
    m["E7626"] = ErrorMeta(code: "E7626", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标厂商库缺失", fix: Some(FixSuggestion(description: "提供厂商 SDK")))
    m["E7627"] = ErrorMeta(code: "E7627", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "系统调用表不匹配", fix: Some(FixSuggestion(description: "使用目标 syscall 表")))
    m["E7628"] = ErrorMeta(code: "E7628", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "浮点 ABI 不同", fix: Some(FixSuggestion(description: "统一浮点 ABI")))
    m["E7629"] = ErrorMeta(code: "E7629", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标对齐要求不同", fix: Some(FixSuggestion(description: "调整对齐")))
    m["E7630"] = ErrorMeta(code: "E7630", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "va_list 布局不同", fix: Some(FixSuggestion(description: "避免跨目标 va_list")))
    m["E7631"] = ErrorMeta(code: "E7631", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "time_t 宽度不同", fix: Some(FixSuggestion(description: "使用固定宽度时间")))
    m["E7632"] = ErrorMeta(code: "E7632", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "wchar_t 宽度不同", fix: Some(FixSuggestion(description: "使用固定宽度字符")))
    m["E7633"] = ErrorMeta(code: "E7633", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "long double 布局不同", fix: Some(FixSuggestion(description: "避免依赖 long double")))
    m["E7634"] = ErrorMeta(code: "E7634", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "展开库不匹配", fix: Some(FixSuggestion(description: "提供目标展开库")))
    m["E7635"] = ErrorMeta(code: "E7635", category: ErrorCategory.Xcompile, severity: Severity.Warning,
        template: "目标不支持消毒剂", fix: Some(FixSuggestion(description: "关闭 sanitizer")))
    m["E7636"] = ErrorMeta(code: "E7636", category: ErrorCategory.Xcompile, severity: Severity.Warning,
        template: "目标不支持覆盖率", fix: Some(FixSuggestion(description: "关闭覆盖率")))
    m["E7637"] = ErrorMeta(code: "E7637", category: ErrorCategory.Xcompile, severity: Severity.Warning,
        template: "目标不支持性能画像", fix: Some(FixSuggestion(description: "关闭画像")))
    m["E7638"] = ErrorMeta(code: "E7638", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "模拟器崩溃", fix: Some(FixSuggestion(description: "检查模拟器/产物")))
    m["E7639"] = ErrorMeta(code: "E7639", category: ErrorCategory.Xcompile, severity: Severity.Error,
        template: "目标描述（target.json）非法", fix: Some(FixSuggestion(description: "修正目标描述")))
    m["E7701"] = ErrorMeta(code: "E7701", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "当前不支持 WASM 目标", fix: Some(FixSuggestion(description: "启用 WASM 后端")))
    m["E7702"] = ErrorMeta(code: "E7702", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 非法操作码", fix: Some(FixSuggestion(description: "检查代码生成")))
    m["E7703"] = ErrorMeta(code: "E7703", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 内存增长（memory.grow）失败", fix: Some(FixSuggestion(description: "检查内存上限")))
    m["E7704"] = ErrorMeta(code: "E7704", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 表（table）已满", fix: Some(FixSuggestion(description: "增大表大小")))
    m["E7705"] = ErrorMeta(code: "E7705", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 函数索引越界", fix: Some(FixSuggestion(description: "检查函数索引")))
    m["E7706"] = ErrorMeta(code: "E7706", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 类型不匹配", fix: Some(FixSuggestion(description: "统一函数签名")))
    m["E7707"] = ErrorMeta(code: "E7707", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 导入（import）缺失：{name}", fix: Some(FixSuggestion(description: "提供导入实现")))
    m["E7708"] = ErrorMeta(code: "E7708", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 导出（export）缺失", fix: Some(FixSuggestion(description: "显式导出符号")))
    m["E7709"] = ErrorMeta(code: "E7709", category: ErrorCategory.Wasm, severity: Severity.Fatal,
        template: "WASM 栈溢出", fix: Some(FixSuggestion(description: "减少递归深度")))
    m["E7710"] = ErrorMeta(code: "E7710", category: ErrorCategory.Wasm, severity: Severity.Fatal,
        template: "WASM 执行到 unreachable", fix: Some(FixSuggestion(description: "检查逻辑")))
    m["E7711"] = ErrorMeta(code: "E7711", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 燃料（gas）耗尽", fix: Some(FixSuggestion(description: "优化计算量")))
    m["E7712"] = ErrorMeta(code: "E7712", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 系统调用未实现：{syscall}", fix: Some(FixSuggestion(description: "实现该 syscalls")))
    m["E7713"] = ErrorMeta(code: "E7713", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 绑定（bindgen）生成失败", fix: Some(FixSuggestion(description: "检查绑定注解")))
    m["E7714"] = ErrorMeta(code: "E7714", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM ABI 不匹配", fix: Some(FixSuggestion(description: "统一 WASM ABI")))
    m["E7715"] = ErrorMeta(code: "E7715", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 与 JS 互操作失败", fix: Some(FixSuggestion(description: "检查互操作层")))
    m["E7716"] = ErrorMeta(code: "E7716", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 目标不支持线程", fix: Some(FixSuggestion(description: "使用单线程模型")))
    m["E7717"] = ErrorMeta(code: "E7717", category: ErrorCategory.Wasm, severity: Severity.Warning,
        template: "WASM 目标不支持 SIMD", fix: Some(FixSuggestion(description: "禁用 SIMD 路径")))
    m["E7718"] = ErrorMeta(code: "E7718", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 目标不支持异常", fix: Some(FixSuggestion(description: "使用错误码返回")))
    m["E7719"] = ErrorMeta(code: "E7719", category: ErrorCategory.Wasm, severity: Severity.Warning,
        template: "WASM 共享内存（shared memory）不支持", fix: Some(FixSuggestion(description: "关闭共享内存")))
    m["E7720"] = ErrorMeta(code: "E7720", category: ErrorCategory.Wasm, severity: Severity.Warning,
        template: "WASM 尾调用扩展不可用", fix: Some(FixSuggestion(description: "避免尾调用")))
    m["E7721"] = ErrorMeta(code: "E7721", category: ErrorCategory.Wasm, severity: Severity.Warning,
        template: "WASM 批量内存扩展不可用", fix: Some(FixSuggestion(description: "降级实现")))
    m["E7722"] = ErrorMeta(code: "E7722", category: ErrorCategory.Wasm, severity: Severity.Warning,
        template: "WASM 引用类型扩展不可用", fix: Some(FixSuggestion(description: "避免使用引用类型")))
    m["E7723"] = ErrorMeta(code: "E7723", category: ErrorCategory.Wasm, severity: Severity.Warning,
        template: "WASM 多值返回扩展不可用", fix: Some(FixSuggestion(description: "改用输出参数")))
    m["E7724"] = ErrorMeta(code: "E7724", category: ErrorCategory.Wasm, severity: Severity.Warning,
        template: "WASM 符号扩展扩展不可用", fix: Some(FixSuggestion(description: "手动实现扩展")))
    m["E7725"] = ErrorMeta(code: "E7725", category: ErrorCategory.Wasm, severity: Severity.Warning,
        template: "WASM 饱和浮点扩展不可用", fix: Some(FixSuggestion(description: "手动饱和")))
    m["E7726"] = ErrorMeta(code: "E7726", category: ErrorCategory.Wasm, severity: Severity.Warning,
        template: "WASM 可变全局不可用", fix: Some(FixSuggestion(description: "改用线性内存")))
    m["E7727"] = ErrorMeta(code: "E7727", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 异常编码失败", fix: Some(FixSuggestion(description: "检查异常类型")))
    m["E7728"] = ErrorMeta(code: "E7728", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 导入类型错误", fix: Some(FixSuggestion(description: "对齐导入签名")))
    m["E7729"] = ErrorMeta(code: "E7729", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM start 函数非法", fix: Some(FixSuggestion(description: "修正 start 函数")))
    m["E7730"] = ErrorMeta(code: "E7730", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM data count 段不匹配", fix: Some(FixSuggestion(description: "修正数据段")))
    m["E7731"] = ErrorMeta(code: "E7731", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 自定义段（custom section）非法", fix: Some(FixSuggestion(description: "检查自定义段")))
    m["E7732"] = ErrorMeta(code: "E7732", category: ErrorCategory.Wasm, severity: Severity.Warning,
        template: "WASM 名称段（name section）损坏", fix: Some(FixSuggestion(description: "重新生成名称段")))
    m["E7733"] = ErrorMeta(code: "E7733", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 链接（wasm-ld）失败", fix: Some(FixSuggestion(description: "检查链接参数")))
    m["E7734"] = ErrorMeta(code: "E7734", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 模块校验失败", fix: Some(FixSuggestion(description: "检查模块合法性")))
    m["E7735"] = ErrorMeta(code: "E7735", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 实例化失败", fix: Some(FixSuggestion(description: "检查导入与内存")))
    m["E7736"] = ErrorMeta(code: "E7736", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 目标无标准库", fix: Some(FixSuggestion(description: "使用 wasm 适配层")))
    m["E7737"] = ErrorMeta(code: "E7737", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 目标无文件系统", fix: Some(FixSuggestion(description: "使用内存文件系统")))
    m["E7738"] = ErrorMeta(code: "E7738", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 目标无网络（除非配置）", fix: Some(FixSuggestion(description: "使用宿主网络 API")))
    m["E7739"] = ErrorMeta(code: "E7739", category: ErrorCategory.Wasm, severity: Severity.Error,
        template: "WASM 模块超过大小限制", fix: Some(FixSuggestion(description: "精简模块")))
    m["E7801"] = ErrorMeta(code: "E7801", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "当前不支持 GPU 目标", fix: Some(FixSuggestion(description: "启用 GPU 后端")))
    m["E7802"] = ErrorMeta(code: "E7802", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 内核（kernel）编译失败", fix: Some(FixSuggestion(description: "检查内核代码")))
    m["E7803"] = ErrorMeta(code: "E7803", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "未找到 GPU 设备", fix: Some(FixSuggestion(description: "检查驱动/设备")))
    m["E7804"] = ErrorMeta(code: "E7804", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 显存不足", fix: Some(FixSuggestion(description: "减少显存占用")))
    m["E7805"] = ErrorMeta(code: "E7805", category: ErrorCategory.Gpu, severity: Severity.Fatal,
        template: "GPU 非法内存访问", fix: Some(FixSuggestion(description: "检查索引边界")))
    m["E7806"] = ErrorMeta(code: "E7806", category: ErrorCategory.Gpu, severity: Severity.Warning,
        template: "GPU 线程束（warp）分支发散", fix: Some(FixSuggestion(description: "减少分支发散")))
    m["E7807"] = ErrorMeta(code: "E7807", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 同步（barrier）失败", fix: Some(FixSuggestion(description: "检查同步调用")))
    m["E7808"] = ErrorMeta(code: "E7808", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 内核执行超时", fix: Some(FixSuggestion(description: "减小工作量")))
    m["E7809"] = ErrorMeta(code: "E7809", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 网格/块维度非法", fix: Some(FixSuggestion(description: "使用合法维度")))
    m["E7810"] = ErrorMeta(code: "E7810", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 共享内存超过限制", fix: Some(FixSuggestion(description: "减少共享内存")))
    m["E7811"] = ErrorMeta(code: "E7811", category: ErrorCategory.Gpu, severity: Severity.Warning,
        template: "GPU 不支持双精度", fix: Some(FixSuggestion(description: "使用单精度")))
    m["E7812"] = ErrorMeta(code: "E7812", category: ErrorCategory.Gpu, severity: Severity.Warning,
        template: "GPU 统一内存（UVM）不可用", fix: Some(FixSuggestion(description: "显式拷贝内存")))
    m["E7813"] = ErrorMeta(code: "E7813", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 驱动版本不匹配", fix: Some(FixSuggestion(description: "升级驱动")))
    m["E7814"] = ErrorMeta(code: "E7814", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 上下文丢失", fix: Some(FixSuggestion(description: "重建上下文")))
    m["E7815"] = ErrorMeta(code: "E7815", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 流（stream）创建失败", fix: Some(FixSuggestion(description: "检查流配置")))
    m["E7816"] = ErrorMeta(code: "E7816", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 事件（event）失败", fix: Some(FixSuggestion(description: "检查事件使用")))
    m["E7817"] = ErrorMeta(code: "E7817", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 主机-设备拷贝失败", fix: Some(FixSuggestion(description: "检查指针与大小")))
    m["E7818"] = ErrorMeta(code: "E7818", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 内核参数不匹配", fix: Some(FixSuggestion(description: "对齐参数类型/大小")))
    m["E7819"] = ErrorMeta(code: "E7819", category: ErrorCategory.Gpu, severity: Severity.Warning,
        template: "GPU 占用率过低", fix: Some(FixSuggestion(description: "调整块大小")))
    m["E7820"] = ErrorMeta(code: "E7820", category: ErrorCategory.Gpu, severity: Severity.Warning,
        template: "GPU 寄存器溢出到本地内存", fix: Some(FixSuggestion(description: "减少寄存器使用")))
    m["E7821"] = ErrorMeta(code: "E7821", category: ErrorCategory.Gpu, severity: Severity.Warning,
        template: "GPU 共享内存 bank 冲突", fix: Some(FixSuggestion(description: "调整访问模式")))
    m["E7822"] = ErrorMeta(code: "E7822", category: ErrorCategory.Gpu, severity: Severity.Warning,
        template: "GPU 不支持该原子操作", fix: Some(FixSuggestion(description: "使用替代同步")))
    m["E7823"] = ErrorMeta(code: "E7823", category: ErrorCategory.Gpu, severity: Severity.Warning,
        template: "GPU 协作组（cooperative group）不可用", fix: Some(FixSuggestion(description: "降级实现")))
    m["E7824"] = ErrorMeta(code: "E7824", category: ErrorCategory.Gpu, severity: Severity.Warning,
        template: "GPU 张量核心（tensor core）不可用", fix: Some(FixSuggestion(description: "使用普通计算")))
    m["E7825"] = ErrorMeta(code: "E7825", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 图（graph）捕获失败", fix: Some(FixSuggestion(description: "检查图节点")))
    m["E7826"] = ErrorMeta(code: "E7826", category: ErrorCategory.Gpu, severity: Severity.Warning,
        template: "GPU MPS（多进程服务）不可用", fix: Some(FixSuggestion(description: "关闭 MPS")))
    m["E7827"] = ErrorMeta(code: "E7827", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "多 GPU 设备间通信失败", fix: Some(FixSuggestion(description: "检查 NCCL/通信")))
    m["E7828"] = ErrorMeta(code: "E7828", category: ErrorCategory.Gpu, severity: Severity.Warning,
        template: "GPU P2P 访问不可用", fix: Some(FixSuggestion(description: "使用主机中转")))
    m["E7829"] = ErrorMeta(code: "E7829", category: ErrorCategory.Gpu, severity: Severity.Warning,
        template: "GPU 性能分析失败", fix: Some(FixSuggestion(description: "检查分析工具")))
    m["E7830"] = ErrorMeta(code: "E7830", category: ErrorCategory.Gpu, severity: Severity.Warning,
        template: "GPU 目标不支持调试", fix: Some(FixSuggestion(description: "使用 CPU 回退调试")))
    m["E7831"] = ErrorMeta(code: "E7831", category: ErrorCategory.Gpu, severity: Severity.Warning,
        template: "GPU 内核 printf 失败", fix: Some(FixSuggestion(description: "检查 printf 缓冲")))
    m["E7832"] = ErrorMeta(code: "E7832", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 内核断言失败", fix: Some(FixSuggestion(description: "修复内核逻辑")))
    m["E7833"] = ErrorMeta(code: "E7833", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 不支持该数据类型", fix: Some(FixSuggestion(description: "使用受支持类型")))
    m["E7834"] = ErrorMeta(code: "E7834", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 内核启动失败", fix: Some(FixSuggestion(description: "检查启动配置")))
    m["E7835"] = ErrorMeta(code: "E7835", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 目标缺少主机侧代码", fix: Some(FixSuggestion(description: "补充主机代码")))
    m["E7836"] = ErrorMeta(code: "E7836", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 设备代码链接失败", fix: Some(FixSuggestion(description: "检查设备链接")))
    m["E7837"] = ErrorMeta(code: "E7837", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU fatbin（多架构）缺失", fix: Some(FixSuggestion(description: "生成 fatbin")))
    m["E7838"] = ErrorMeta(code: "E7838", category: ErrorCategory.Gpu, severity: Severity.Error,
        template: "GPU 架构与编译架构不匹配", fix: Some(FixSuggestion(description: "使用目标架构编译")))
    m["E7839"] = ErrorMeta(code: "E7839", category: ErrorCategory.Gpu, severity: Severity.Warning,
        template: "GPU 资源未释放", fix: Some(FixSuggestion(description: "释放 GPU 资源")))
}


/// 错误码枚举（扩展后：40 个类别、共 1519 个规范错误码）
///
/// 命名规范：首字母 E + 类别号（1 位）+ 子类号（1 位）+ 序号（2 位）。
public enum ErrorCode <: Equatable<ErrorCode> {
    // ===== Lexer 词法分析（E00xx） =====
    | LexerUnterminatedString
    | LexerUnterminatedBlockComment
    | LexerInvalidEscapeSequence
    | LexerInvalidNumberLiteral
    | LexerUnexpectedCharacter
    | LexerInvalidIdentifier
    | LexerNumericOverflow
    | LexerUnterminatedCharLiteral
    | LexerEmptyCharLiteral
    | LexerInvalidUtf8Sequence
    | LexerInvalidNumericSuffix
    | LexerNewlineInStringLiteral
    | LexerInvalidIdentifierStart
    | LexerInvalidRawStringDelimiter
    | LexerNestedCommentTooDeep
    | LexerInvalidUnicodeEscape
    | LexerLeadingZero
    | LexerCharLiteralTooLong
    | LexerUnsupportedLineEnding
    | LexerBOMEncodingConflict
    | LexerDigitSeparatorMisplaced
    | LexerUnterminatedRawString
    | LexerInvalidStringPrefix
    | LexerConflictingSourceEncoding
    | LexerZeroWidthCharacter
    | LexerFloatingPointFormat
    | LexerRadixLiteralFormat
    | LexerLiteralTooLong
    | LexerTruncatedMultibyte
    | ParserMissingOperand
    | ParserInvalidModifierOrder
    | ParserDuplicateImport
    | ParserUnexpectedExpressionStatement
    | ParserIllegalTopLevelStatement
    | ParserExpectedIdentifier
    | ParserMissingTypeAnnotation
    | ParserUnclosedTypeParams
    | ParserDuplicateParameterName
    | ParserMisplacedAnnotation
    // ===== Parser 语法分析（E01xx） =====
    | ParserUnterminatedString
    | ParserUnexpectedToken
    | ParserMissingSemicolon
    | ParserMismatchedBracket
    | ParserInvalidExpression
    | ParserMissingColon
    | ParserDuplicateModifier
    | ParserInvalidDeclaration
    | ParserTrailingComma
    | ParserUnexpectedEOF
    | ParserInvalidGenericConstraint
    | ParserMissingReturnType
    | ParserDanglingDocComment
    | ParserInvalidAttributeTarget
    | ParserConflictingMutability
    | ParserInvalidPattern
    | ParserInvalidMemberDecl
    | ParserInvalidLambdaSyntax
    | ParserInvalidStringInterpolation
    | ParserMissingElseBranch
    | ParserOperatorPrecedenceAmbiguous
    | SemaUninitializedConstant
    | SemaDuplicateImportItem
    | SemaIllegalRecursion
    | SemaNonExhaustiveMatch
    | SemaUnreachableMatchArm
    | SemaTypeInferenceFailed
    | SemaMutableOpOnImmutable
    | SemaOperatorOverloadMismatch
    | SemaInterfaceDefaultConflict
    | SemaUnusedConstructorParam
    | SemaUnreachableLoop
    | SemaInvalidCastSafety
    | SemaMissingMainFunction
    | SemaConflictingTraitImpl
    | SemaUnsafeEscape
    | SemaTraitMethodMissing
    | SemaClosureCaptureError
    | SemaNoViableOverload
    | SemaNamedArgumentMismatch
    | SemaMutabilityPropagation
    | SemaInvalidAsyncContext
    | SemaCyclicInitialization
    // ===== Sema 语义分析（E10xx） =====
    | SemaUndefinedSymbol
    | SemaRedeclaration
    | SemaInvalidArgumentCount
    | SemaImmutableAssignment
    | SemaUseBeforeDeclaration
    | SemaInvalidBreakContinue
    | SemaMissingReturn
    | SemaUnreachableCode
    | SemaShadowedVariable
    | SemaDeprecatedUsage
    | TypeInvalidVariancePosition
    | TypeWhereClauseViolation
    | TypeClosureTypeMismatch
    | TypeBorrowConflict
    | TypeCyclicInference
    | TypeCovariantReturnInvalid
    | TypeEmptyEnum
    | TypeUnsafeTraitUpcast
    | TypeArgumentCountMismatch
    | TypeCyclicInterfaceInheritance
    | TypeIncompatibleReturn
    | TypeUnresolvedAssociatedType
    | TypeInvalidSelfType
    | TypeHigherRankedBound
    | TypePhantomTypeMismatch
    | TypeConstEvalFailure
    | TypeConstOverflow
    | TypeNullableUnwrap
    | TypeTupleElementMismatch
    | TypeFunctionPointerMismatch
    | TypeLiteralAmbiguity
    // ===== Type 类型系统（E20xx） =====
    | TypeMismatch
    | TypeInferenceFailed
    | TypeInvalidCast
    | TypeAmbiguousOverload
    | TypeMissingGenericArgument
    | TypeConstraintViolation
    | TypeRecursiveAlias
    | TypeUnsizedInStack
    | TypeImplicitConversionLossy
    | TypeIncompatibleVariance
    | ResolutionMacroExpansionFailed
    | ResolutionCyclicTypeAlias
    | ResolutionMissingExport
    | ResolutionTransitiveVisibility
    | ResolutionUncoveredCfgBranch
    | ResolutionMacroImportNotFound
    | ResolutionReexportConflict
    | ResolutionPackageInitCycle
    | ResolutionUndefinedCfgSymbol
    | ResolutionVisibilityLeak
    | ResolutionConflictingImportAlias
    | ResolutionUnstableApi
    | ResolutionMissingFeatureFlag
    | ResolutionSymbolPrecedence
    | ResolutionOrphanedImpl
    | ResolutionGlobImportAmbiguous
    | ResolutionMacroHygiene
    | ResolutionVisibilityTierViolation
    | ResolutionTraitMethodConflict
    | ResolutionCfgExpressionError
    // ===== Resolution 名称解析（E30xx） =====
    | ResolutionModuleNotFound
    | ResolutionImportNotFound
    | ResolutionAmbiguousImport
    | ResolutionPrivateAccess
    | ResolutionUnresolvedPath
    | ResolutionCircularImport
    | ResolutionTraitNotImplemented
    | ResolutionInvalidSuperCall
    | ResolutionNameClash
    | ResolutionVersionMismatch
    | CodegenRegisterAllocationFailed
    | CodegenUnsupportedTailCall
    | CodegenInlineFailed
    | CodegenConstFoldOverflow
    | CodegenTargetFeatureUnsupported
    | CodegenUnreachableBlock
    | CodegenVtableOverflow
    | CodegenLargeEhTable
    | CodegenInvalidInlineAsm
    | CodegenAlignmentUnsupported
    | CodegenUnsupportedSimd
    | CodegenDebugInfoFailed
    | CodegenSectionTooLarge
    | CodegenRelocUnsupported
    | CodegenProfileInstrumentFailed
    | CodegenMonomorphizationFailed
    | CodegenLinkerFailed
    | CodegenBuiltinUnsupported
    | CodegenCallingConventionMismatch
    | CodegenTlsUnsupported
    | CodegenFfiAbiMismatch
    | CodegenInvalidTargetTriple
    | CodegenDebugFormatError
    // ===== Codegen 代码生成（E40xx） =====
    | CodegenUnsupportedConstruct
    | CodegenStackOverflowRisk
    | CodegenInvalidIntrinsic
    | CodegenLinkageError
    | CodegenABIIncompatible
    | CodegenOptimizationFailed
    | CodegenUninitializedUse
    | CodegenLargeConstant
    | CodegenTargetNotSupported
    | CodegenEmissionInterrupted
    | RuntimeUseAfterMove
    | RuntimeDataRace
    | RuntimeBufferOverflow
    | RuntimeInfiniteRecursion
    | RuntimeFFICallFailed
    | RuntimeDestructorThrow
    | RuntimeDanglingWeakRef
    | RuntimeNegativeIndex
    | RuntimeInvalidSuspend
    | RuntimeAlignmentFault
    | RuntimeLeakedResource
    | RuntimeContractViolation
    | RuntimeTimeoutExceeded
    | RuntimeStackCorruption
    | RuntimeUnknownError
    | RuntimeDoubleFree
    | RuntimeUseAfterFree
    | RuntimeChannelClosed
    | RuntimeAtomicMisuse
    | RuntimeThreadLimitExceeded
    | RuntimeMemoryMapFailed
    // ===== Runtime 运行时（E50xx） =====
    | RuntimeNullDereference
    | RuntimeIndexOutOfBounds
    | RuntimeDivisionByZero
    | RuntimeStackOverflow
    | RuntimeIntegerOverflow
    | RuntimeInvalidCast
    | RuntimeResourceExhausted
    | RuntimeDeadlockDetected
    | RuntimeAssertionFailed
    | RuntimeUnwindAborted
    | SystemConcurrencyLimit
    | SystemDiagnosticSerializeFailed
    | SystemIncompatibleCompilerVersion
    | SystemMissingEnvVar
    | SystemInternalAssertion
    | SystemTempDirUnwritable
    | SystemOutputChannelBusy
    | SystemPluginVersionMismatch
    | SystemInterrupted
    | SystemUnknownInternal
    // ===== System 系统/内部（E90xx） =====
    | SystemInternalError
    | SystemIOError
    | SystemOutOfMemory
    | SystemTimeout
    | SystemInvalidConfig
    | SystemPluginLoadFailed
    | SystemCacheCorrupted
    | SystemNetworkError
    | SystemPermissionDenied
    | SystemUnknown
    | SystemResourceLimit
    | SystemFeatureUnsupported
    | SystemFatalSignal
    | SystemUnrecoverableState
    | SystemShutdownRequested
    | SystemIncrementalCacheInvalidated
    | SystemRemoteBuildFailed
    | SystemSandboxLimitExceeded
    | MacroUndefinedIdentifier
    | MacroArityMismatch
    | MacroRecursiveExpansion
    | MacroHygieneViolation
    | MacroInvalidTokenTree
    | MacroMissingMacroDef
    | MacroDuplicateMacroDef
    | MacroWrongFragmentKind
    | MacroMetavarReuse
    | MacroNoMatchingRule
    | MacroReservedName
    | MacroContextualKeyword
    | MacroExpansionDepthLimit
    | MacroMalformedAttribute
    | MacroDeriveConflict
    | MacroProcMacroPanic
    | MacroProcMacroTimeout
    | MacroProcMacroIOError
    | MacroQuoteSpanLost
    | MacroRuleAmbiguity
    | MacroEmptyRepetition
    | MacroSeparatorMismatch
    | MacroTTNotBalance
    | MacroUnresolvedFragment
    | MacroBuiltinMacroUnsupported
    | MacroMacroInConst
    | MacroCfgMacroBranch
    | MacroDocMacroBroken
    | MacroFormatMacroParse
    | MacroLogMacroLevel
    | MacroAssertMacroMsg
    | MacroVecMacroNonUniform
    | MacroIncludeMacroFail
    | MacroConcatMacroType
    | MacroEnvMacroMissing
    | MacroSelectMacroConflict
    | MacroMacroDefRecursion
    | MacroGenericMacroParam
    | MacroUnsafeMacroExpansion
    | MacroMacroSpanOverflow
    | TraitMethodNotImplemented
    | TraitMethodSignatureMismatch
    | TraitMissingSupertrait
    | TraitConflictingImpl
    | TraitOrphanRuleViolation
    | TraitNegativeImplConflict
    | TraitSealedTraitLeak
    | TraitAssociatedTypeMissing
    | TraitAssociatedTypeBound
    | TraitDefaultImplConflict
    | TraitMarkerTraitMisuse
    | TraitDynTraitNotObjectSafe
    | TraitDynTraitGeneric
    | TraitTraitBoundUnmet
    | TraitHigherRankedBound
    | TraitTraitAliasCycle
    | TraitImplForBoundParam
    | TraitSpecializationFailure
    | TraitAutoTraitNotImpl
    | TraitAutoTraitConflict
    | TraitCoordTraitAmbig
    | TraitUnsafeTraitImpl
    | TraitTraitMethodVisibility
    | TraitWhereClauseOnImpl
    | TraitBlanketImplConflict
    | TraitTraitObjectCovariance
    | TraitAssocTypeProjection
    | TraitTraitMethodDefaultParam
    | TraitAsyncTraitNotSupported
    | TraitTraitMethodGenericClash
    | TraitDuplicateAssocConst
    | TraitAssocConstType
    | TraitTraitMethodByName
    | TraitImplGenericCount
    | TraitTraitRequirementCycle
    | TraitDispatchResolution
    | TraitTraitMethodOverride
    | TraitLateBoundParam
    | TraitTraitInheritanceDepth
    | TraitSelfImplConflict
    | BorrowMoveOutOfBorrowed
    | BorrowBorrowAfterMove
    | BorrowMutableBorrowConflict
    | BorrowAliasingMutableBorrow
    | BorrowBorrowEscapesScope
    | BorrowUseOfMovedValue
    | BorrowPartialMoveStruct
    | BorrowMoveInMatchGuard
    | BorrowClosureCaptureByMove
    | BorrowReturnReferenceToLocal
    | BorrowTemporaryLifetime
    | BorrowBorrowOfMovedField
    | BorrowSelfBorrowInMethod
    | BorrowReborrowFailed
    | BorrowCopyTraitMissing
    | BorrowDropDuringBorrow
    | BorrowBorrowInMatchArm
    | BorrowDoubleMutableBorrow
    | BorrowImmutableToMutable
    | BorrowBorrowInClosureArg
    | BorrowUnsafeBypassBorrow
    | BorrowPhantomBorrow
    | BorrowBorrowInLoop
    | BorrowFieldBorrowEscape
    | BorrowGenericBorrowBound
    | BorrowMoveAcrossAwait
    | BorrowBorrowOfDropType
    | BorrowReturnBorrowedParam
    | BorrowSelfReferential
    | BorrowAsyncMoveCapture
    | BorrowBorrowInMatchGuard2
    | BorrowStaticBorrowViolation
    | BorrowInteriorMutRace
    | BorrowBorrowOfUnsized
    | BorrowScopedBorrowEnd
    | BorrowMoveInClosure
    | BorrowBorrowInMatchGuard3
    | BorrowTemporaryBorrowDrop
    | BorrowTraitObjectBorrow
    | BorrowCoerceBorrowMismatch
    | LifetimeUnboundedLifetime
    | LifetimeLifetimeMismatch
    | LifetimeMissingLifetime
    | LifetimeAnonymousLifetimeConflict
    | LifetimeStaticRequirements
    | LifetimeLifetimeInTypeAlias
    | LifetimeVarianceViolation
    | LifetimeHigherRankedLifetime
    | LifetimeLifetimeElisionFail
    | LifetimeStructFieldLifetime
    | LifetimeBorrowLifetimeShort
    | LifetimeOutlivesFailure
    | LifetimePhantomLifetime
    | LifetimeAsyncLifetimeCapture
    | LifetimeClosureLifetimeCapture
    | LifetimeIteratorLifetime
    | LifetimeTraitObjectLifetime
    | LifetimeReturnRefLifetime
    | LifetimeSelfLifetime
    | LifetimeGenericLifetimeBound
    | LifetimeCovariantReturnLifetime
    | LifetimeLifetimeInImplTrait
    | LifetimeNestedLifetime
    | LifetimeStaticRefCapture
    | LifetimeDropLifetime
    | LifetimeLifetimeSubtyping
    | LifetimeEarlyBoundLateBound
    | LifetimeLifetimeInConst
    | LifetimeYieldLifetime
    | LifetimeBorrowSplitLifetime
    | LifetimeFunctionPointerLifetime
    | LifetimeArrayLifetime
    | LifetimeUnionLifetime
    | LifetimeTraitMethodLifetime
    | LifetimeLifetimeNameConflict
    | LifetimeRAIILifetime
    | LifetimeGenericAssocLifetime
    | LifetimeReferenceToTempLifetime
    | LifetimeLifetimeOnTrait
    | GenericArgumentCountMismatch
    | GenericTypeArgumentInference
    | GenericConstraintViolation
    | GenericMissingTraitBound
    | GenericRecursiveAlias
    | GenericMonomorphizationFailed
    | GenericCodeBloatLimit
    | GenericHigherRankedBound
    | GenericDefaultArgumentMissing
    | GenericDefaultArgumentConflict
    | GenericVarianceMismatch
    | GenericUnsizedGeneric
    | GenericAssociatedTypeUnbound
    | GenericGATNotSupported
    | GenericConstGenericMismatch
    | GenericConstGenericNonConst
    | GenericConstGenericOverflow
    | GenericTraitObjectGeneric
    | GenericImplGenericConflict
    | GenericBlanketImplConflict
    | GenericGenericMethodResolution
    | GenericTypeParamShadow
    | GenericGenericInEnum
    | GenericGenericFunctionPointer
    | GenericSpecializationFailed
    | GenericPhantomTypeMismatch
    | GenericWhereClauseUnmet
    | GenericTypeParamCountInImpl
    | GenericGenericAliasCycle
    | GenericNegativeImplAmbig
    | GenericGenericStructField
    | GenericHigherRankedInType
    | GenericGenericTraitBound
    | GenericExistentialGeneric
    | GenericGenericDefaultCycle
    | GenericUnsoundGeneric
    | GenericGenericCoherence
    | GenericTupleGenericMismatch
    | GenericArrayGenericLen
    | GenericImplTraitPosition
    | GenericGenericInlineCycle
    | ModuleModuleNotFound
    | ModuleFileNotFound
    | ModuleCyclicModule
    | ModuleDuplicateModule
    | ModuleVisibilityViolation
    | ModuleReexportConflict
    | ModuleGlobConflict
    | ModuleWrongModuleTree
    | ModuleAnonymousModule
    | ModuleModuleNameConflict
    | ModuleNestedModuleDepth
    | ModuleMacroUseScope
    | ModulePathResolution
    | ModuleSuperOutside
    | ModuleCrateRootMissing
    | ModuleInlineModuleConflict
    | ModuleExternalCrateNotFound
    | ModuleExternalCrateVersion
    | ModuleFeatureGateModule
    | ModulePrivateModuleLeak
    | ModuleModuleInitOrder
    | ModuleCfgModuleDisabled
    | ModuleAmbiguousPath
    | ModuleUseAsConflict
    | ModuleTraitInModule
    | ModuleStructInModule
    | ModuleEnumVariantPath
    | ModuleModuleDocConflict
    | ModuleUnsafeModuleExport
    | ModuleGenericModuleParam
    | ModulePlatformModule
    | ModuleTestModuleLeak
    | ModuleBenchModule
    | ModuleMacroModuleSep
    | ModuleModuleCyclicReexport
    | ModuleHiddenModule
    | ModuleModuleAttrConflict
    | ModuleNamespaceConflict
    | ModuleInlineInFile
    | ModuleEmptyModule
    | BackendLlvmVerifyFailed
    | BackendLlvmLoweringFailed
    | BackendLlvmOptCrash
    | BackendLlvmUnsupported
    | BackendIrInvalid
    | BackendIrTypeMismatch
    | BackendIrMissingDef
    | BackendIrUnreachable
    | BackendRegisterAllocFailed
    | BackendStackFrameTooLarge
    | BackendCodeLayoutFailed
    | BackendSectionEmitFailed
    | BackendRelocationUnsupported
    | BackendTargetFeatureAbsent
    | BackendCallingConvUnknown
    | BackendDebugInfoLost
    | BackendEhTableTooLarge
    | BackendGlobalInitFailed
    | BackendConstantFoldBackend
    | BackendAsmEmitFailed
    | BackendVectorBackend
    | BackendTailCallUnsupported
    | BackendInlineAsmConstraint
    | BackendMetadataEmit
    | BackendModuleParse
    | BackendTargetMachineInit
    | BackendDataLayoutMismatch
    | BackendABILowering
    | BackendUnwindInfoFailed
    | BackendProfileInstrument
    | BackendSanitizerUnsupported
    | BackendThinLtoFailed
    | BackendLtoModuleConflict
    | BackendBackendTimeout
    | BackendBackendOOM
    | BackendVerifierLimit
    | BackendIntrinsicLowering
    | BackendBlockAddressInvalid
    | BackendComdatFailed
    | BackendAliasEmitFailed
    | BackendWeakSymbolConflict
    | OptPassFailed
    | OptPassCrashed
    | OptInvalidation
    | OptLoopUnrollFailed
    | OptVectorizationFailed
    | OptInliningFailed
    | OptInliningTooDeep
    | OptDeadCodeNotRemoved
    | OptConstPropOverflow
    | OptGvnConflict
    | OptSccpFailed
    | OptMem2RegFailed
    | OptLoopInvariantFailed
    | OptTailDuplicateFailed
    | OptPeepholeFailed
    | OptStrengthReduction
    | OptAliasAnalysisFailed
    | OptOptLevelInvalid
    | OptOptSizeConflict
    | OptProfileMismatch
    | OptOptCorruptIr
    | OptLoopRotateFailed
    | OptGlobalOptFailed
    | OptIpConstantProp
    | OptArgumentPromotion
    | OptStructRetOpt
    | OptTailCallOptFailed
    | OptSLPVectorizeFailed
    | OptLoopVersioning
    | OptPartialInline
    | OptHotColdSplit
    | OptMergeFuncFailed
    | OptGVNLoadElim
    | OptOptzLoopUnswitch
    | OptReassociateFailed
    | OptOptLoopIdiom
    | OptCFGSimplifyFailed
    | OptOptIndVar
    | OptDivRemOpt
    | OptOptShiftBase
    | OptOptFloatReassoc
    | LinkerLinkerNotFound
    | LinkerLinkerInvocation
    | LinkerUndefinedSymbol
    | LinkerDuplicateSymbol
    | LinkerLibraryNotFound
    | LinkerLibraryVersion
    | LinkerMissingEntryPoint
    | LinkerRelocOverflow
    | LinkerArchMismatch
    | LinkerAbiMismatch
    | LinkerLinkScriptError
    | LinkerStaticDynamicConflict
    | LinkerStdLibLinkFailed
    | LinkerRuntimeLibMissing
    | LinkerLinkerOOM
    | LinkerLinkerTimeout
    | LinkerThreadLocalLink
    | LinkerWeakSymbolUnresolved
    | LinkerExportSymbolMissing
    | LinkerImportLibraryMissing
    | LinkerCOMDATConflict
    | LinkerLinkOrderError
    | LinkerBitcodeLinkFailed
    | LinkerLTOFailed
    | LinkerLinkerScriptUnknown
    | LinkerDynamicLibMissing
    | LinkerRpathInvalid
    | LinkerSymbolVisibility
    | LinkerLinkerLangMismatch
    | LinkerGCSectionsFailed
    | LinkerMmapLinkFailed
    | LinkerLinkSanitizer
    | LinkerDeadStripFailed
    | LinkerLinkerPluginError
    | LinkerCrtFileMissing
    | LinkerLinkerVersionOld
    | LinkerMangledNameConflict
    | LinkerPieUnsupported
    | LinkerLinkerStackSize
    | LinkerUnwindLibMissing
    | AbiFfiSignatureMismatch
    | AbiFfiTypeUnsupported
    | AbiCAbiMismatch
    | AbiStructLayoutMismatch
    | AbiEnumReprMismatch
    | AbiUnionLayout
    | AbiCallbackAbiMismatch
    | AbiVarargsUnsupported
    | AbiFfiUnsafeCall
    | AbiFfiLifetimeViolation
    | AbiFfiPanicAcross
    | AbiFfiAllocMismatch
    | AbiFloatAbiMismatch
    | AbiRegisterAbiMismatch
    | AbiEndiannessMismatch
    | AbiAlignAbiMismatch
    | AbiNameMangling
    | AbiFfiCharEncoding
    | AbiFfiBoolSize
    | AbiFfiEnumSize
    | AbiFfiPointerNull
    | AbiFfiWideChar
    | AbiFfiLongSize
    | AbiFfiStructPass
    | AbiFfiUnwindAbi
    | AbiFfiVectorAbi
    | AbiFfiComplexType
    | AbiFfiBitfield
    | AbiFfiVaList
    | AbiFfiThreadLocal
    | AbiFfiCallingConvention
    | AbiFfiNonPod
    | AbiFfiDtorLeak
    | AbiFfiCallbackLifetime
    | AbiFfiResourceLeak
    | AbiFfiSignalUnsafe
    | AbiFfiLongjmp
    | AbiFfiComdat
    | AbiFfiTypeSize
    | AbiFfiConstMismatch
    | ConcurrencyThreadSpawnFailed
    | ConcurrencyThreadLimitExceeded
    | ConcurrencyDataRaceDetected
    | ConcurrencyDeadlockDetected
    | ConcurrencyLockPoisoned
    | ConcurrencyCondVarSpurious
    | ConcurrencyChannelClosed
    | ConcurrencyChannelSendBlocked
    | ConcurrencyChannelRecvEmpty
    | ConcurrencyActorMailboxFull
    | ConcurrencyActorStopped
    | ConcurrencyFutureNotPolled
    | ConcurrencyExecutorShutdown
    | ConcurrencyAwaitOutsideAsync
    | ConcurrencyAsyncRecursion
    | ConcurrencyCoroutineSuspendInvalid
    | ConcurrencyCoroutineLeak
    | ConcurrencyAtomicMisuse
    | ConcurrencyMemoryOrderInvalid
    | ConcurrencyRwLockDeadlock
    | ConcurrencyMutexDoubleLock
    | ConcurrencyBarrierWait
    | ConcurrencySemaphoreOverflow
    | ConcurrencyOnceInitPanic
    | ConcurrencyThreadLocalAccess
    | ConcurrencyRaceOnInit
    | ConcurrencyParkUnparkLost
    | ConcurrencyTaskCanceled
    | ConcurrencyAffinityFailed
    | ConcurrencyStackSizeInvalid
    | ConcurrencyAsyncDropCycle
    | ConcurrencyExecutorStarvation
    | ConcurrencySelectArmConflict
    | ConcurrencyChannelCapacityZero
    | ConcurrencyLockOrderInversion
    | ConcurrencyNonSendCaptured
    | ConcurrencyNonSyncShared
    | ConcurrencyWatchdogTimeout
    | ConcurrencyCpuAffinityUnsupported
    | ConcurrencyCoroutineStackExhaust
    | ConcurrencyWorkStealFailed
    | MemOutOfMemory
    | MemDoubleFree
    | MemUseAfterFree
    | MemHeapCorruption
    | MemLeakDetected
    | MemInvalidFree
    | MemUnalignedAccess
    | MemNullDereference
    | MemBufferOverflow
    | MemBufferUnderflow
    | MemStackOverflow
    | MemGcPauseTooLong
    | MemGcPromotionFailed
    | MemGcFragmentation
    | MemGcCycleLeak
    | MemFinalizerDeadlock
    | MemFinalizerRunsLate
    | MemAllocatorMismatch
    | MemCustomAllocFail
    | MemAlignmentTooLarge
    | MemZeroSizeAlloc
    | MemReallocShrinkLost
    | MemMemoryMapFailed
    | MemGuardPageViolation
    | MemDanglingPointer
    | MemWildPointer
    | MemReferenceCycle
    | MemArcStrongZero
    | MemWeakUpgradeFail
    | MemArenaExhausted
    | MemArenaDoubleFree
    | MemStackUnwindCorrupt
    | MemMoveUninit
    | MemReadUninit
    | MemPaddingLeak
    | MemMemoryTagError
    | MemHugepageFailed
    | MemNumaBindFailed
    | MemOvercommitExceeded
    | MemGcRootLost
    | MemAllocatorDeadlock
    | OsFileNotFound
    | OsPermissionDenied
    | OsIoError
    | OsBrokenPipe
    | OsTooManyOpenFiles
    | OsDiskFull
    | OsNoSuchProcess
    | OsProcessSpawnFailed
    | OsSignalReceived
    | OsTimeoutExceeded
    | OsResourceLimit
    | OsAddressInUse
    | OsConnectionRefused
    | OsNetworkUnreachable
    | OsDnsResolveFailed
    | OsEnvVarMissing
    | OsEnvVarInvalid
    | OsWorkingDirMissing
    | OsSymlinkLoop
    | OsReadOnlyFileSystem
    | OsQuotaExceeded
    | OsInvalidUtf8Path
    | OsThreadPriorityFailed
    | OsClockError
    | OsInsufficientMemory
    | OsLockFileHeld
    | OsSharedMemFailed
    | OsMmapExecDenied
    | OsSeccompBlocked
    | OsCapabilityMissing
    | OsChrootFailed
    | OsMountFailed
    | OsNoSuchDevice
    | OsDeviceBusy
    | OsInvalidFd
    | OsPollFailed
    | OsPipeBufferFull
    | OsForkNotAllowed
    | OsProcessAlreadyExited
    | OsUserNamespaceFailed
    | OsFileSystemType
    | LspInvalidRequest
    | LspDocumentNotFound
    | LspPositionOutOfRange
    | LspUnsupportedCapability
    | LspDiagnosticsStale
    | LspSemanticTokensFailed
    | LspCompletionFailed
    | LspHoverFailed
    | LspDefinitionNotFound
    | LspReferenceSearchFailed
    | LspRenameFailed
    | LspFormatFailed
    | LspCodeActionFailed
    | LspInlayHintFailed
    | LspFoldingFailed
    | LspDocumentLinkFailed
    | LspWorkspaceSymbolFailed
    | LspConfigurationMissing
    | LspServerPanic
    | LspProtocolVersion
    | LspEncodingMismatch
    | LspLineEndingMismatch
    | LspLargeDocument
    | LspDebounceSkipped
    | LspIndexCorrupt
    | LspSlowAnalysis
    | LspMissingSource
    | LspUnknownDiagnostic
    | LspRpcParseFailed
    | LspCancelledRequest
    | LspCrashRecovery
    | LspWorkspaceFolder
    | LspFileWatcherFailed
    | LspDiagnosticDuplicate
    | LspTelemetryDisabled
    | LspClientInitFailed
    | LspProgressFailed
    | LspLinkedEditingFailed
    | LspCallHierarchyFailed
    | LspTypeHierarchyFailed
    | LspDocumentColorFailed
    | IncrementalCacheMissing
    | IncrementalCacheCorrupt
    | IncrementalCacheVersionMismatch
    | IncrementalDepFileStale
    | IncrementalHashMismatch
    | IncrementalFingerprintFailed
    | IncrementalQueryCycle
    | IncrementalDirtyNode
    | IncrementalSerializedFailed
    | IncrementalDeserializeFailed
    | IncrementalCacheEvicted
    | IncrementalUpToDateFalse
    | IncrementalRebuildCascade
    | IncrementalLockContention
    | IncrementalPermissionDenied
    | IncrementalDiskFull
    | IncrementalConcurrentWrite
    | IncrementalMetadataMismatch
    | IncrementalIncrementalDisabled
    | IncrementalChangedEnv
    | IncrementalChangedFlags
    | IncrementalChangedTarget
    | IncrementalFingerprintSalt
    | IncrementalNodeLimit
    | IncrementalGraphTooLarge
    | IncrementalCachePathTooLong
    | IncrementalSymlinkCache
    | IncrementalToolchainChanged
    | IncrementalIncrementalPanic
    | IncrementalQueryStackOverflow
    | IncrementalCacheReadTimeout
    | IncrementalPersistentCache
    | IncrementalDirtyAll
    | IncrementalHashCollision
    | IncrementalDepTrackingLost
    | IncrementalIncrementalOOM
    | IncrementalVersionDowngrade
    | IncrementalCacheMigration
    | IncrementalUntrackedInput
    | PkgManifestNotFound
    | PkgManifestParse
    | PkgDependencyMissing
    | PkgDependencyVersion
    | PkgDependencyConflict
    | PkgRegistryUnreachable
    | PkgDownloadFailed
    | PkgChecksumMismatch
    | PkgLockfileStale
    | PkgLockfileConflict
    | PkgCircularDependency
    | PkgFeatureNotFound
    | PkgFeatureConflict
    | PkgBuildScriptFailed
    | PkgGitDependencyFailed
    | PkgLocalPathMissing
    | PkgPublishDenied
    | PkgPackageNameInvalid
    | PkgPackageVersionInvalid
    | PkgYankedPackage
    | PkgUnresolvedProxy
    | PkgMirrorSync
    | PkgLicenseMissing
    | PkgLicenseConflict
    | PkgPrivatePackage
    | PkgTokenExpired
    | PkgPackageTooLarge
    | PkgInvalidMetadata
    | PkgSourceIncompatible
    | PkgPlatformSpecificDep
    | PkgOptionalDepMissing
    | PkgDevDependencyLeak
    | PkgPatchConflict
    | PkgWorkspaceMember
    | PkgWorkspaceInherit
    | PkgOverridesConflict
    | PkgVendoredMismatch
    | PkgCachePermission
    | PkgResolveTimeout
    | PkgDuplicatePackage
    | PkgTargetSpecificManifest
    | BuildBuildScriptPanic
    | BuildBuildTargetMissing
    | BuildBuildProfileUnknown
    | BuildArtifactNotFound
    | BuildCompileStepFailed
    | BuildLinkStepFailed
    | BuildCustomTargetFailed
    | BuildBuildCacheInvalid
    | BuildParallelBuildDeadlock
    | BuildJobServerUnavailable
    | BuildOutputDirLocked
    | BuildPermissionDenied
    | BuildDiskFull
    | BuildBuildTimeout
    | BuildIncrementalDisabled
    | BuildFeatureGateBuild
    | BuildCrossCompileToolchain
    | BuildSysrootMissing
    | BuildEnvVarMissing
    | BuildBuildScriptEnv
    | BuildFingerprintMismatch
    | BuildDepInfoStale
    | BuildTargetTripleInvalid
    | BuildBuildPlanFailed
    | BuildPostBuildFailed
    | BuildTestHarnessFailed
    | BuildBenchHarnessFailed
    | BuildDocBuildFailed
    | BuildExampleBuildFailed
    | BuildToolchainDownload
    | BuildRustflagsConflict
    | BuildCfgNotDefined
    | BuildBuildScriptRebuild
    | BuildLockContention
    | BuildTargetSpecificFail
    | BuildOutOfMemory
    | BuildSignalInterrupted
    | BuildTmpDirUnwritable
    | BuildBuildHookFailed
    | BuildUnsupportedAction
    | DebugDwarfEmitFailed
    | DebugDebugInfoStripped
    | DebugLineTableMissing
    | DebugVariableLocation
    | DebugTypeInfoMissing
    | DebugInlinedFrame
    | DebugBreakpointUnavailable
    | DebugWatchpointFailed
    | DebugSymbolNotFound
    | DebugSourceMapMissing
    | DebugPdbEmitFailed
    | DebugDebuggerAttachFailed
    | DebugCoreDumpFailed
    | DebugBacktraceUnavailable
    | DebugOptimizedOut
    | DebugDebugMacroInfo
    | DebugNamespaceInfoMissing
    | DebugTemplateInfoMissing
    | DebugSplitDebugFailed
    | DebugDebugCompression
    | DebugLineZero
    | DebugColumnInfoMissing
    | DebugInheritanceInfo
    | DebugAsyncBacktrace
    | DebugDebugPrettyPrinter
    | DebugEvalFailed
    | DebugConditionalBreakpoint
    | DebugDebugServerDown
    | DebugProtocolHandshake
    | DebugSymbolicateFailed
    | DebugDebugInfoMismatch
    | DebugFrameCorrupt
    | DebugUnwindInfoMissing
    | DebugDebugSectionsStripped
    | DebugTypeAliasInfo
    | DebugLocalVarOmitted
    | DebugDebugInfoTooLarge
    | DebugCorruptDebugInfo
    | DebugMissingCompilationUnit
    | DebugDebugArangesMissing
    | DistRemoteNodeDown
    | DistSchedulerUnreachable
    | DistJobDispatchFailed
    | DistResultFetchFailed
    | DistNodeAuthFailed
    | DistInconsistentEnv
    | DistCacheSyncFailed
    | DistNetworkPartition
    | DistTimeoutExceeded
    | DistResultCorrupt
    | DistNodeOverloaded
    | DistArtifactMismatch
    | DistUnsupportedTarget
    | DistCompilationUnitTooBig
    | DistDependencyNotCached
    | DistSecureChannelFailed
    | DistHeartbeatLost
    | DistQuotaExceeded
    | DistRegionMismatch
    | DistSerializationFailed
    | DistDeserializationFailed
    | DistVersionSkew
    | DistPartialFailure
    | DistLoadImbalance
    | DistIdempotencyViolation
    | DistCachePoisoned
    | DistBandwidthLimited
    | DistNodeBlacklisted
    | DistCompilationAborted
    | DistCheckpointFailed
    | DistRecoverFailed
    | DistTokenExpired
    | DistMisconfiguredPool
    | DistCompilationDrift
    | DistAuditLogMissing
    | DistColdStart
    | DistResourceContention
    | DistUnsupportedFeature
    | PluginPluginNotFound
    | PluginPluginLoadFailed
    | PluginPluginVersionMismatch
    | PluginPluginApiChanged
    | PluginPluginPanic
    | PluginPluginTimeout
    | PluginPluginPermissionDenied
    | PluginPluginConflict
    | PluginPluginSignatureInvalid
    | PluginPluginUnsafeOperation
    | PluginPluginInitFailed
    | PluginPluginDepMissing
    | PluginPluginConfigInvalid
    | PluginPluginHookError
    | PluginPluginResourceLeak
    | PluginPluginCrashed
    | PluginPluginDisabled
    | PluginPluginTooOld
    | PluginPluginTooNew
    | PluginPluginNameConflict
    | PluginPluginCycle
    | PluginPluginSandboxViolation
    | PluginPluginOutOfMemory
    | PluginPluginDeadlock
    | PluginPluginNetworkBlocked
    | PluginPluginFileSystemBlocked
    | PluginPluginEnvBlocked
    | PluginPluginUnserialize
    | PluginPluginHotReloadFailed
    | PluginPluginUnloadFailed
    | PluginPluginCapabilityMissing
    | PluginPluginDeprecated
    | PluginPluginManifestInvalid
    | PluginPluginEntryMissing
    | PluginPluginAbiMismatch
    | PluginPluginLangMismatch
    | PluginPluginBadExit
    | PluginPluginStdoutParse
    | PluginPluginLockContention
    | TgtTargetTripleInvalid
    | TgtTargetUnsupported
    | TgtTargetFeatureMissing
    | TgtTargetArchUnknown
    | TgtTargetOsUnknown
    | TgtTargetEnvUnknown
    | TgtTargetVendorUnknown
    | TgtTargetPointerWidth
    | TgtTargetEndianUnknown
    | TgtTargetFloatUnsupported
    | TgtTargetAtomicMissing
    | TgtTargetSimdAbsent
    | TgtTargetTlsModel
    | TgtTargetRelocation
    | TgtTargetCodeModel
    | TgtTargetCpuUnknown
    | TgtTargetFpuUnknown
    | TgtTargetAbiUnknown
    | TgtTargetPanicStrategy
    | TgtTargetAllocStrategy
    | TgtTargetSyscallConv
    | TgtTargetStackProbe
    | TgtTargetExceptionModel
    | TgtTargetDebugFormat
    | TgtTargetObjFormat
    | TgtTargetLinkerMissing
    | TgtTargetRuntimeMissing
    | TgtTargetLibcMissing
    | TgtTargetNoStd
    | TgtTargetNoAtomic
    | TgtTargetUnsupportedFloat
    | TgtTargetRegisterWidth
    | TgtTargetProfiling
    | TgtTargetSanitizerAbsent
    | TgtTargetCoverage
    | TgtTargetPositionIndependent
    | TgtTargetThreadLocal
    | TgtTargetUnwindUnsupported
    | TgtTargetVendorLibMissing
    | SimdSimdWidthUnsupported
    | SimdSimdTypeMismatch
    | SimdSimdLaneCount
    | SimdSimdUnaligned
    | SimdSimdMaskInvalid
    | SimdSimdReductionFailed
    | SimdSimdShuffleInvalid
    | SimdSimdGatherScatter
    | SimdSimdIntrinsicMissing
    | SimdSimdOverflow
    | SimdSimdDivByZero
    | SimdSimdNanPropagate
    | SimdSimdConstantInvalid
    | SimdSimdCvtFailed
    | SimdSimdPermuteFailed
    | SimdSimdBlendInvalid
    | SimdSimdExtractOob
    | SimdSimdInsertOob
    | SimdSimdCompareResult
    | SimdSimdBitcast
    | SimdSimdAlignment
    | SimdSimdTargetAbsent
    | SimdSimdLengthMismatch
    | SimdSimdSignedUnsigned
    | SimdSimdRounding
    | SimdSimdSaturation
    | SimdSimdFmaMissing
    | SimdSimdConflict
    | SimdSimdRegisterPressure
    | SimdSimdLaneOrder
    | SimdSimdPredicateInvalid
    | SimdSimdRotated
    | SimdSimdPopcount
    | SimdSimdShiftOob
    | SimdSimdSelectInvalid
    | SimdSimdWidenFailed
    | SimdSimdNarrowFailed
    | SimdSimdInterleave
    | SimdSimdDeinterleave
    | EmbedEmbedNoStd
    | EmbedEmbedNoAlloc
    | EmbedEmbedFlashFull
    | EmbedEmbedRamFull
    | EmbedEmbedNoFloat
    | EmbedEmbedNoException
    | EmbedEmbedNoRtti
    | EmbedEmbedHardFault
    | EmbedEmbedWatchdog
    | EmbedEmbedInterruptNested
    | EmbedEmbedStackOverflow
    | EmbedEmbedHeapCorrupt
    | EmbedEmbedPeripheralBusy
    | EmbedEmbedDmaFailed
    | EmbedEmbedClockMisconfig
    | EmbedEmbedPinConflict
    | EmbedEmbedNoSyscall
    | EmbedCgoSymbolClash
    | EmbedCgoTypeMismatch
    | EmbedCgoCallbackNull
    | EmbedCgoPanicCross
    | EmbedCgoThreadLocal
    | EmbedCgoAllocMismatch
    | EmbedEmbedInterruptPriority
    | EmbedEmbedBootFailed
    | EmbedEmbedLinkerScript
    | EmbedEmbedVectorTable
    | EmbedEmbedNoAtomic
    | EmbedEmbedWatchpoint
    | EmbedEmbedPowerFail
    | EmbedEmbedStackCanary
    | EmbedEmbedMpuViolation
    | EmbedEmbedCacheCoherency
    | EmbedCgoCcNotFound
    | EmbedCgoBuildFailed
    | EmbedEmbedNoStdio
    | EmbedEmbedTickFailed
    | EmbedEmbedCriticalSection
    | EmbedEmbedNoFpu
    | EmbedCgoCallbackLifetime
    | TestTestCompileFailed
    | TestTestBinaryMissing
    | TestTestTimeout
    | TestTestPanic
    | TestTestAssertFailed
    | TestTestFixtureFailed
    | TestTestTeardownFailed
    | TestTestFilterNoMatch
    | TestTestDuplicateName
    | TestTestDependencyOrder
    | TestTestResourceLeak
    | TestTestIgnored
    | TestTestShouldPanic
    | TestTestUnexpectedPanic
    | TestTestFlaky
    | TestTestHarnessCrash
    | TestTestStdoutCapture
    | TestTestEnvMissing
    | TestTestDataMissing
    | TestTestMockFailed
    | TestTestConcurrency
    | TestTestDeadlock
    | TestTestLeakSanitizer
    | TestTestCoverageFailed
    | TestTestReportFailed
    | TestTestParallelConflict
    | TestTestBeforeAllFailed
    | TestTestAfterAllFailed
    | TestTestSkipCondition
    | TestTestParamMismatch
    | TestTestTimeoutConfig
    | TestTestBinaryCrash
    | TestTestSignal
    | TestTestMemoryLimit
    | TestTestIsolation
    | TestTestRandomSeed
    | TestTestImportFailed
    | TestTestUnknownAttr
    | TestTestDoubleRun
    | TestTestSummaryLost
    | TestTestHang
    | DocDocBrokenLink
    | DocDocMissingItem
    | DocDocCodeBlockFailed
    | DocDocTestFailed
    | DocDocExamplePanic
    | DocDocCompileFailed
    | DocDocMalformedAttr
    | DocDocCyclicModule
    | DocDocPrivateLeak
    | DocDocHtmlEscape
    | DocDocMissingSummary
    | DocDocBrokenIntraLink
    | DocDocAliasConflict
    | DocDocSearchIndex
    | DocDocThemeFailed
    | DocDocAssetMissing
    | DocDocCommentTooLong
    | DocDocNonAsciiPath
    | DocDocVersionMismatch
    | DocDocExampleOutdated
    | DocDocInvalidMarkdown
    | DocDocTableBroken
    | DocDocCodeLangUnknown
    | DocDocRedirectLoop
    | DocDocCrossCrate
    | DocDocFeatureGate
    | DocDocJsonFailed
    | DocDocTestCompileTimeout
    | DocDocHiddenItemRef
    | DocDocDuplicateAnchor
    | DocDocMacroDoc
    | DocDocTraitImplMissing
    | DocDocGenericParam
    | DocDocCfgFiltered
    | DocDocPlatformSpecific
    | DocDocIncludeFailed
    | DocDocEduLinkBroken
    | LintLintUnusedVariable
    | LintLintUnusedImport
    | LintLintUnusedFunction
    | LintLintDeadCode
    | LintLintDeprecatedUse
    | LintLintNonSnakeCase
    | LintLintNonCamelCase
    | LintLintNonUpperCaseConst
    | LintLintHardcodedPath
    | LintLintMagicNumber
    | LintLintTodoLeft
    | LintLintPrintStatement
    | LintLintUnsafeBlock
    | LintLintCloneInLoop
    | LintLintComplexity
    | LintLintTooManyArgs
    | LintLintDeepNesting
    | LintLintLineTooLong
    | LintLintDocMissing
    | LintLintCopyInsteadRef
    | LintLintWildcardImport
    | LintLintUnreachablePattern
    | LintLintNonExhaustiveLet
    | LintLintRedundantClone
    | LintLintShadowing
    | LintLintMutableNotNeeded
    | LintLintUnnecessaryMut
    | LintLintInefficientToStr
    | LintLintPanicInProd
    | LintLintFloatEquality
    | LintLintUnwrapUsed
    | LintLintExpectUsed
    | LintLintIndexUnchecked
    | LintLintIteratorValue
    | LintLintLargeEnumVariant
    | LintLintDerefClone
    | LintLintRedundantField
    | LintLintNonIdiomatic
    | LintLintStyleViolation
    | LintLintUnsafeSuggest
    | LintLintPossibleBug
    | SecSecHardcodedSecret
    | SecSecSqlInjection
    | SecSecCommandInjection
    | SecSecPathTraversal
    | SecSecUnsafeDeserialize
    | SecSecWeakCrypto
    | SecSecInsecureRandom
    | SecSecTlsVerificationOff
    | SecSecCleartextTransport
    | SecSecUnsafeEval
    | SecSecBufferOverflowRisk
    | SecSecFormatString
    | SecSecIntegerOverflow
    | SecSecRaceCondition
    | SecSecUseAfterFreeRisk
    | SecSecDoubleFreeRisk
    | SecSecNullDerefRisk
    | SecSecSensitiveLog
    | SecSecInsecureTemp
    | SecSecSymlinkAttack
    | SecSecUnsafeCast
    | SecSecMemoryDisclosure
    | SecSecMissingAuthz
    | SecSecMissingAuthn
    | SecSecCsrfRisk
    | SecSecXssRisk
    | SecSecInsecureCookie
    | SecSecOpenRedirect
    | SecSecUnsafeReflection
    | SecSecDependencyVuln
    | SecSecUnsafePermission
    | SecSecKeySizeSmall
    | SecSecHashWeak
    | SecSecCipherModeWeak
    | SecSecNonceReuse
    | SecSecCertExpired
    | SecSecInsecureProto
    | SecSecPrivilegeDrop
    | SecSecInfoLeak
    | ConfConfigFileNotFound
    | ConfConfigParseFailed
    | ConfConfigSchemaInvalid
    | ConfConfigKeyUnknown
    | ConfConfigTypeMismatch
    | ConfConfigMissingRequired
    | ConfConfigDeprecated
    | ConfConfigConflict
    | ConfConfigEnvOverride
    | ConfConfigProfileUnknown
    | ConfConfigIncludeFailed
    | ConfConfigCycle
    | ConfConfigPermission
    | ConfConfigEncoding
    | ConfConfigTooLarge
    | ConfConfigValidationFailed
    | ConfConfigDefaultInvalid
    | ConfConfigRangeViolation
    | ConfConfigEnumInvalid
    | ConfConfigPathInvalid
    | ConfConfigUrlInvalid
    | ConfConfigTimeoutInvalid
    | ConfConfigFeatureConflict
    | ConfConfigTargetMismatch
    | ConfConfigRuntimeMismatch
    | ConfConfigHotReloadFailed
    | ConfConfigSecretLeak
    | ConfConfigFormatUnknown
    | ConfConfigMergeConflict
    | ConfConfigVersionMismatch
    | ConfConfigUnsafeValue
    | ConfConfigRedundant
    | ConfConfigDocMissing
    | ConfConfigTypeCoercion
    | ConfConfigPlaceholder
    | ConfConfigConditional
    | ConfConfigLocked
    | ConfConfigEnvMissing
    | ConfConfigInvalidBool
    | ConfConfigListEmpty
    | TelemTelemDisabled
    | TelemTelemInitFailed
    | TelemTelemExportFailed
    | TelemTelemQueueFull
    | TelemTelemTimeout
    | TelemTelemUnauthorized
    | TelemTelemEndpointUnreachable
    | TelemTelemSchemaInvalid
    | TelemTelemDropSpans
    | TelemTelemMissingContext
    | TelemTelemCardinality
    | TelemTelemPiiLeak
    | TelemTelemDuplicate
    | TelemTelemClockSkew
    | TelemTelemBufferFlush
    | TelemTelemOOM
    | TelemTelemMisconfigured
    | TelemTelemVersionMismatch
    | TelemTelemSamplerInvalid
    | TelemTelemAttrTooLong
    | TelemTelemNameInvalid
    | TelemTelemDropMetrics
    | TelemTelemLogFailed
    | TelemTelemCrashNoReport
    | TelemTelemRateLimited
    | TelemTelemSecretInAttr
    | TelemTelemExportBlocked
    | TelemTelemBackpressure
    | TelemTelemSpanOrphan
    | TelemTelemLateArrival
    | TelemTelemStorageFull
    | TelemTelemEncodingFailed
    | TelemTelemBatchFailed
    | TelemTelemNoCollector
    | TelemTelemInconsistent
    | TelemTelemDisabledFeature
    | TelemTelemPrivacyPolicy
    | TelemTelemAttrCountExceed
    | XcompileXcompileToolchainMissing
    | XcompileXcompileSysrootMissing
    | XcompileXcompileLinkerMissing
    | XcompileXcompileTargetLibMissing
    | XcompileXcompileAbiMismatch
    | XcompileXcompileSyscallDiff
    | XcompileXcompileEndianDiff
    | XcompileXcompilePointerWidth
    | XcompileXcompileFpuDiff
    | XcompileXcompileAtomicAbsent
    | XcompileXcompileCrtMissing
    | XcompileXcompileUnwindDiff
    | XcompileXcompileEnvMismatch
    | XcompileXcompileQemuMissing
    | XcompileXcompileRunFailed
    | XcompileXcompileHostDep
    | XcompileXcompilePathSep
    | XcompileXcompileDlopen
    | XcompileXcompileTlsModel
    | XcompileXcompileStackProbe
    | XcompileXcompileCodeModel
    | XcompileXcompileArchFeature
    | XcompileXcompileLinkScript
    | XcompileXcompileObjFormat
    | XcompileXcompileDebugFormat
    | XcompileXcompileVendorLib
    | XcompileXcompileSyscallTable
    | XcompileXcompileFloatAbi
    | XcompileXcompileAlignDiff
    | XcompileXcompileVaList
    | XcompileXcompileTimeT
    | XcompileXcompileWchar
    | XcompileXcompileLongDouble
    | XcompileXcompileUnwindLib
    | XcompileXcompileSanitizer
    | XcompileXcompileCoverage
    | XcompileXcompileProfile
    | XcompileXcompileEmulatorCrash
    | XcompileXcompileTargetJson
    | WasmWasmTargetUnsupported
    | WasmWasmInvalidOpcode
    | WasmWasmMemoryGrowFailed
    | WasmWasmTableFull
    | WasmWasmFuncIndexOob
    | WasmWasmTypeMismatch
    | WasmWasmImportMissing
    | WasmWasmExportMissing
    | WasmWasmStackOverflow
    | WasmWasmUnreachable
    | WasmWasmGasExceeded
    | WasmWasmSyscallAbsent
    | WasmWasmBindgenFailed
    | WasmWasmAbiMismatch
    | WasmWasmJsInterop
    | WasmWasmNoThreads
    | WasmWasmNoSimd
    | WasmWasmNoException
    | WasmWasmSharedMemory
    | WasmWasmTailCall
    | WasmWasmBulkMemory
    | WasmWasmReferenceTypes
    | WasmWasmMultiValue
    | WasmWasmSignExtension
    | WasmWasmSatFloat
    | WasmWasmMutableGlobal
    | WasmWasmExceptionEncoding
    | WasmWasmImportTypeError
    | WasmWasmStartFunc
    | WasmWasmDataCount
    | WasmWasmCustomSection
    | WasmWasmNameSection
    | WasmWasmLinkerFailed
    | WasmWasmValidationFailed
    | WasmWasmInstantiationFailed
    | WasmWasmNoStd
    | WasmWasmNoFilesystem
    | WasmWasmNoNetwork
    | WasmWasmSizeLimit
    | GpuGpuTargetUnsupported
    | GpuGpuKernelCompileFailed
    | GpuGpuDeviceNotFound
    | GpuGpuOutOfMemory
    | GpuGpuIllegalAccess
    | GpuGpuWarpDivergence
    | GpuGpuSyncFailed
    | GpuGpuTimeout
    | GpuGpuInvalidDim
    | GpuGpuSharedMemExceed
    | GpuGpuNoDouble
    | GpuGpuUnifiedMemory
    | GpuGpuDriverMismatch
    | GpuGpuContextLost
    | GpuGpuStreamFailed
    | GpuGpuEventFailed
    | GpuGpuCopyFailed
    | GpuGpuKernelArg
    | GpuGpuOccupancyLow
    | GpuGpuRegisterSpill
    | GpuGpuBankConflict
    | GpuGpuAtomicUnsupported
    | GpuGpuCooperativeGroup
    | GpuGpuTensorCore
    | GpuGpuGraphFailed
    | GpuGpuMpsUnavailable
    | GpuGpuMultiDevice
    | GpuGpuPeerAccess
    | GpuGpuProfilerFailed
    | GpuGpuDebugUnsupported
    | GpuGpuPrintfFailed
    | GpuGpuAssertFailed
    | GpuGpuUnsupportedType
    | GpuGpuLaunchFailed
    | GpuGpuNoHostCode
    | GpuGpuLinkFailed
    | GpuGpuFatbinMissing
    | GpuGpuArchMismatch
    | GpuGpuResourceLeak
    public static func all(): ArrayList<ErrorCode> {
        let list = ArrayList<ErrorCode>()
        list.add(ErrorCode.LexerUnterminatedString)
        list.add(ErrorCode.LexerUnterminatedBlockComment)
        list.add(ErrorCode.LexerInvalidEscapeSequence)
        list.add(ErrorCode.LexerInvalidNumberLiteral)
        list.add(ErrorCode.LexerUnexpectedCharacter)
        list.add(ErrorCode.LexerInvalidIdentifier)
        list.add(ErrorCode.LexerNumericOverflow)
        list.add(ErrorCode.LexerUnterminatedCharLiteral)
        list.add(ErrorCode.LexerEmptyCharLiteral)
        list.add(ErrorCode.LexerInvalidUtf8Sequence)
        list.add(ErrorCode.LexerInvalidNumericSuffix)
        list.add(ErrorCode.LexerNewlineInStringLiteral)
        list.add(ErrorCode.LexerInvalidIdentifierStart)
        list.add(ErrorCode.LexerInvalidRawStringDelimiter)
        list.add(ErrorCode.LexerNestedCommentTooDeep)
        list.add(ErrorCode.LexerInvalidUnicodeEscape)
        list.add(ErrorCode.LexerLeadingZero)
        list.add(ErrorCode.LexerCharLiteralTooLong)
        list.add(ErrorCode.LexerUnsupportedLineEnding)
        list.add(ErrorCode.LexerBOMEncodingConflict)
        list.add(ErrorCode.LexerDigitSeparatorMisplaced)
        list.add(ErrorCode.LexerUnterminatedRawString)
        list.add(ErrorCode.LexerInvalidStringPrefix)
        list.add(ErrorCode.LexerConflictingSourceEncoding)
        list.add(ErrorCode.LexerZeroWidthCharacter)
        list.add(ErrorCode.LexerFloatingPointFormat)
        list.add(ErrorCode.LexerRadixLiteralFormat)
        list.add(ErrorCode.LexerLiteralTooLong)
        list.add(ErrorCode.LexerTruncatedMultibyte)
        list.add(ErrorCode.ParserMissingOperand)
        list.add(ErrorCode.ParserInvalidModifierOrder)
        list.add(ErrorCode.ParserDuplicateImport)
        list.add(ErrorCode.ParserUnexpectedExpressionStatement)
        list.add(ErrorCode.ParserIllegalTopLevelStatement)
        list.add(ErrorCode.ParserExpectedIdentifier)
        list.add(ErrorCode.ParserMissingTypeAnnotation)
        list.add(ErrorCode.ParserUnclosedTypeParams)
        list.add(ErrorCode.ParserDuplicateParameterName)
        list.add(ErrorCode.ParserMisplacedAnnotation)
        list.add(ErrorCode.ParserUnterminatedString)
        list.add(ErrorCode.ParserUnexpectedToken)
        list.add(ErrorCode.ParserMissingSemicolon)
        list.add(ErrorCode.ParserMismatchedBracket)
        list.add(ErrorCode.ParserInvalidExpression)
        list.add(ErrorCode.ParserMissingColon)
        list.add(ErrorCode.ParserDuplicateModifier)
        list.add(ErrorCode.ParserInvalidDeclaration)
        list.add(ErrorCode.ParserTrailingComma)
        list.add(ErrorCode.ParserUnexpectedEOF)
        list.add(ErrorCode.ParserInvalidGenericConstraint)
        list.add(ErrorCode.ParserMissingReturnType)
        list.add(ErrorCode.ParserDanglingDocComment)
        list.add(ErrorCode.ParserInvalidAttributeTarget)
        list.add(ErrorCode.ParserConflictingMutability)
        list.add(ErrorCode.ParserInvalidPattern)
        list.add(ErrorCode.ParserInvalidMemberDecl)
        list.add(ErrorCode.ParserInvalidLambdaSyntax)
        list.add(ErrorCode.ParserInvalidStringInterpolation)
        list.add(ErrorCode.ParserMissingElseBranch)
        list.add(ErrorCode.ParserOperatorPrecedenceAmbiguous)
        list.add(ErrorCode.SemaUninitializedConstant)
        list.add(ErrorCode.SemaDuplicateImportItem)
        list.add(ErrorCode.SemaIllegalRecursion)
        list.add(ErrorCode.SemaNonExhaustiveMatch)
        list.add(ErrorCode.SemaUnreachableMatchArm)
        list.add(ErrorCode.SemaTypeInferenceFailed)
        list.add(ErrorCode.SemaMutableOpOnImmutable)
        list.add(ErrorCode.SemaOperatorOverloadMismatch)
        list.add(ErrorCode.SemaInterfaceDefaultConflict)
        list.add(ErrorCode.SemaUnusedConstructorParam)
        list.add(ErrorCode.SemaUnreachableLoop)
        list.add(ErrorCode.SemaInvalidCastSafety)
        list.add(ErrorCode.SemaMissingMainFunction)
        list.add(ErrorCode.SemaConflictingTraitImpl)
        list.add(ErrorCode.SemaUnsafeEscape)
        list.add(ErrorCode.SemaTraitMethodMissing)
        list.add(ErrorCode.SemaClosureCaptureError)
        list.add(ErrorCode.SemaNoViableOverload)
        list.add(ErrorCode.SemaNamedArgumentMismatch)
        list.add(ErrorCode.SemaMutabilityPropagation)
        list.add(ErrorCode.SemaInvalidAsyncContext)
        list.add(ErrorCode.SemaCyclicInitialization)
        list.add(ErrorCode.SemaUndefinedSymbol)
        list.add(ErrorCode.SemaRedeclaration)
        list.add(ErrorCode.SemaInvalidArgumentCount)
        list.add(ErrorCode.SemaImmutableAssignment)
        list.add(ErrorCode.SemaUseBeforeDeclaration)
        list.add(ErrorCode.SemaInvalidBreakContinue)
        list.add(ErrorCode.SemaMissingReturn)
        list.add(ErrorCode.SemaUnreachableCode)
        list.add(ErrorCode.SemaShadowedVariable)
        list.add(ErrorCode.SemaDeprecatedUsage)
        list.add(ErrorCode.TypeInvalidVariancePosition)
        list.add(ErrorCode.TypeWhereClauseViolation)
        list.add(ErrorCode.TypeClosureTypeMismatch)
        list.add(ErrorCode.TypeBorrowConflict)
        list.add(ErrorCode.TypeCyclicInference)
        list.add(ErrorCode.TypeCovariantReturnInvalid)
        list.add(ErrorCode.TypeEmptyEnum)
        list.add(ErrorCode.TypeUnsafeTraitUpcast)
        list.add(ErrorCode.TypeArgumentCountMismatch)
        list.add(ErrorCode.TypeCyclicInterfaceInheritance)
        list.add(ErrorCode.TypeIncompatibleReturn)
        list.add(ErrorCode.TypeUnresolvedAssociatedType)
        list.add(ErrorCode.TypeInvalidSelfType)
        list.add(ErrorCode.TypeHigherRankedBound)
        list.add(ErrorCode.TypePhantomTypeMismatch)
        list.add(ErrorCode.TypeConstEvalFailure)
        list.add(ErrorCode.TypeConstOverflow)
        list.add(ErrorCode.TypeNullableUnwrap)
        list.add(ErrorCode.TypeTupleElementMismatch)
        list.add(ErrorCode.TypeFunctionPointerMismatch)
        list.add(ErrorCode.TypeLiteralAmbiguity)
        list.add(ErrorCode.TypeMismatch)
        list.add(ErrorCode.TypeInferenceFailed)
        list.add(ErrorCode.TypeInvalidCast)
        list.add(ErrorCode.TypeAmbiguousOverload)
        list.add(ErrorCode.TypeMissingGenericArgument)
        list.add(ErrorCode.TypeConstraintViolation)
        list.add(ErrorCode.TypeRecursiveAlias)
        list.add(ErrorCode.TypeUnsizedInStack)
        list.add(ErrorCode.TypeImplicitConversionLossy)
        list.add(ErrorCode.TypeIncompatibleVariance)
        list.add(ErrorCode.ResolutionMacroExpansionFailed)
        list.add(ErrorCode.ResolutionCyclicTypeAlias)
        list.add(ErrorCode.ResolutionMissingExport)
        list.add(ErrorCode.ResolutionTransitiveVisibility)
        list.add(ErrorCode.ResolutionUncoveredCfgBranch)
        list.add(ErrorCode.ResolutionMacroImportNotFound)
        list.add(ErrorCode.ResolutionReexportConflict)
        list.add(ErrorCode.ResolutionPackageInitCycle)
        list.add(ErrorCode.ResolutionUndefinedCfgSymbol)
        list.add(ErrorCode.ResolutionVisibilityLeak)
        list.add(ErrorCode.ResolutionConflictingImportAlias)
        list.add(ErrorCode.ResolutionUnstableApi)
        list.add(ErrorCode.ResolutionMissingFeatureFlag)
        list.add(ErrorCode.ResolutionSymbolPrecedence)
        list.add(ErrorCode.ResolutionOrphanedImpl)
        list.add(ErrorCode.ResolutionGlobImportAmbiguous)
        list.add(ErrorCode.ResolutionMacroHygiene)
        list.add(ErrorCode.ResolutionVisibilityTierViolation)
        list.add(ErrorCode.ResolutionTraitMethodConflict)
        list.add(ErrorCode.ResolutionCfgExpressionError)
        list.add(ErrorCode.ResolutionModuleNotFound)
        list.add(ErrorCode.ResolutionImportNotFound)
        list.add(ErrorCode.ResolutionAmbiguousImport)
        list.add(ErrorCode.ResolutionPrivateAccess)
        list.add(ErrorCode.ResolutionUnresolvedPath)
        list.add(ErrorCode.ResolutionCircularImport)
        list.add(ErrorCode.ResolutionTraitNotImplemented)
        list.add(ErrorCode.ResolutionInvalidSuperCall)
        list.add(ErrorCode.ResolutionNameClash)
        list.add(ErrorCode.ResolutionVersionMismatch)
        list.add(ErrorCode.CodegenRegisterAllocationFailed)
        list.add(ErrorCode.CodegenUnsupportedTailCall)
        list.add(ErrorCode.CodegenInlineFailed)
        list.add(ErrorCode.CodegenConstFoldOverflow)
        list.add(ErrorCode.CodegenTargetFeatureUnsupported)
        list.add(ErrorCode.CodegenUnreachableBlock)
        list.add(ErrorCode.CodegenVtableOverflow)
        list.add(ErrorCode.CodegenLargeEhTable)
        list.add(ErrorCode.CodegenInvalidInlineAsm)
        list.add(ErrorCode.CodegenAlignmentUnsupported)
        list.add(ErrorCode.CodegenUnsupportedSimd)
        list.add(ErrorCode.CodegenDebugInfoFailed)
        list.add(ErrorCode.CodegenSectionTooLarge)
        list.add(ErrorCode.CodegenRelocUnsupported)
        list.add(ErrorCode.CodegenProfileInstrumentFailed)
        list.add(ErrorCode.CodegenMonomorphizationFailed)
        list.add(ErrorCode.CodegenLinkerFailed)
        list.add(ErrorCode.CodegenBuiltinUnsupported)
        list.add(ErrorCode.CodegenCallingConventionMismatch)
        list.add(ErrorCode.CodegenTlsUnsupported)
        list.add(ErrorCode.CodegenFfiAbiMismatch)
        list.add(ErrorCode.CodegenInvalidTargetTriple)
        list.add(ErrorCode.CodegenDebugFormatError)
        list.add(ErrorCode.CodegenUnsupportedConstruct)
        list.add(ErrorCode.CodegenStackOverflowRisk)
        list.add(ErrorCode.CodegenInvalidIntrinsic)
        list.add(ErrorCode.CodegenLinkageError)
        list.add(ErrorCode.CodegenABIIncompatible)
        list.add(ErrorCode.CodegenOptimizationFailed)
        list.add(ErrorCode.CodegenUninitializedUse)
        list.add(ErrorCode.CodegenLargeConstant)
        list.add(ErrorCode.CodegenTargetNotSupported)
        list.add(ErrorCode.CodegenEmissionInterrupted)
        list.add(ErrorCode.RuntimeUseAfterMove)
        list.add(ErrorCode.RuntimeDataRace)
        list.add(ErrorCode.RuntimeBufferOverflow)
        list.add(ErrorCode.RuntimeInfiniteRecursion)
        list.add(ErrorCode.RuntimeFFICallFailed)
        list.add(ErrorCode.RuntimeDestructorThrow)
        list.add(ErrorCode.RuntimeDanglingWeakRef)
        list.add(ErrorCode.RuntimeNegativeIndex)
        list.add(ErrorCode.RuntimeInvalidSuspend)
        list.add(ErrorCode.RuntimeAlignmentFault)
        list.add(ErrorCode.RuntimeLeakedResource)
        list.add(ErrorCode.RuntimeContractViolation)
        list.add(ErrorCode.RuntimeTimeoutExceeded)
        list.add(ErrorCode.RuntimeStackCorruption)
        list.add(ErrorCode.RuntimeUnknownError)
        list.add(ErrorCode.RuntimeDoubleFree)
        list.add(ErrorCode.RuntimeUseAfterFree)
        list.add(ErrorCode.RuntimeChannelClosed)
        list.add(ErrorCode.RuntimeAtomicMisuse)
        list.add(ErrorCode.RuntimeThreadLimitExceeded)
        list.add(ErrorCode.RuntimeMemoryMapFailed)
        list.add(ErrorCode.RuntimeNullDereference)
        list.add(ErrorCode.RuntimeIndexOutOfBounds)
        list.add(ErrorCode.RuntimeDivisionByZero)
        list.add(ErrorCode.RuntimeStackOverflow)
        list.add(ErrorCode.RuntimeIntegerOverflow)
        list.add(ErrorCode.RuntimeInvalidCast)
        list.add(ErrorCode.RuntimeResourceExhausted)
        list.add(ErrorCode.RuntimeDeadlockDetected)
        list.add(ErrorCode.RuntimeAssertionFailed)
        list.add(ErrorCode.RuntimeUnwindAborted)
        list.add(ErrorCode.SystemConcurrencyLimit)
        list.add(ErrorCode.SystemDiagnosticSerializeFailed)
        list.add(ErrorCode.SystemIncompatibleCompilerVersion)
        list.add(ErrorCode.SystemMissingEnvVar)
        list.add(ErrorCode.SystemInternalAssertion)
        list.add(ErrorCode.SystemTempDirUnwritable)
        list.add(ErrorCode.SystemOutputChannelBusy)
        list.add(ErrorCode.SystemPluginVersionMismatch)
        list.add(ErrorCode.SystemInterrupted)
        list.add(ErrorCode.SystemUnknownInternal)
        list.add(ErrorCode.SystemInternalError)
        list.add(ErrorCode.SystemIOError)
        list.add(ErrorCode.SystemOutOfMemory)
        list.add(ErrorCode.SystemTimeout)
        list.add(ErrorCode.SystemInvalidConfig)
        list.add(ErrorCode.SystemPluginLoadFailed)
        list.add(ErrorCode.SystemCacheCorrupted)
        list.add(ErrorCode.SystemNetworkError)
        list.add(ErrorCode.SystemPermissionDenied)
        list.add(ErrorCode.SystemUnknown)
        list.add(ErrorCode.SystemResourceLimit)
        list.add(ErrorCode.SystemFeatureUnsupported)
        list.add(ErrorCode.SystemFatalSignal)
        list.add(ErrorCode.SystemUnrecoverableState)
        list.add(ErrorCode.SystemShutdownRequested)
        list.add(ErrorCode.SystemIncrementalCacheInvalidated)
        list.add(ErrorCode.SystemRemoteBuildFailed)
        list.add(ErrorCode.SystemSandboxLimitExceeded)
        list.add(ErrorCode.MacroUndefinedIdentifier)
        list.add(ErrorCode.MacroArityMismatch)
        list.add(ErrorCode.MacroRecursiveExpansion)
        list.add(ErrorCode.MacroHygieneViolation)
        list.add(ErrorCode.MacroInvalidTokenTree)
        list.add(ErrorCode.MacroMissingMacroDef)
        list.add(ErrorCode.MacroDuplicateMacroDef)
        list.add(ErrorCode.MacroWrongFragmentKind)
        list.add(ErrorCode.MacroMetavarReuse)
        list.add(ErrorCode.MacroNoMatchingRule)
        list.add(ErrorCode.MacroReservedName)
        list.add(ErrorCode.MacroContextualKeyword)
        list.add(ErrorCode.MacroExpansionDepthLimit)
        list.add(ErrorCode.MacroMalformedAttribute)
        list.add(ErrorCode.MacroDeriveConflict)
        list.add(ErrorCode.MacroProcMacroPanic)
        list.add(ErrorCode.MacroProcMacroTimeout)
        list.add(ErrorCode.MacroProcMacroIOError)
        list.add(ErrorCode.MacroQuoteSpanLost)
        list.add(ErrorCode.MacroRuleAmbiguity)
        list.add(ErrorCode.MacroEmptyRepetition)
        list.add(ErrorCode.MacroSeparatorMismatch)
        list.add(ErrorCode.MacroTTNotBalance)
        list.add(ErrorCode.MacroUnresolvedFragment)
        list.add(ErrorCode.MacroBuiltinMacroUnsupported)
        list.add(ErrorCode.MacroMacroInConst)
        list.add(ErrorCode.MacroCfgMacroBranch)
        list.add(ErrorCode.MacroDocMacroBroken)
        list.add(ErrorCode.MacroFormatMacroParse)
        list.add(ErrorCode.MacroLogMacroLevel)
        list.add(ErrorCode.MacroAssertMacroMsg)
        list.add(ErrorCode.MacroVecMacroNonUniform)
        list.add(ErrorCode.MacroIncludeMacroFail)
        list.add(ErrorCode.MacroConcatMacroType)
        list.add(ErrorCode.MacroEnvMacroMissing)
        list.add(ErrorCode.MacroSelectMacroConflict)
        list.add(ErrorCode.MacroMacroDefRecursion)
        list.add(ErrorCode.MacroGenericMacroParam)
        list.add(ErrorCode.MacroUnsafeMacroExpansion)
        list.add(ErrorCode.MacroMacroSpanOverflow)
        list.add(ErrorCode.TraitMethodNotImplemented)
        list.add(ErrorCode.TraitMethodSignatureMismatch)
        list.add(ErrorCode.TraitMissingSupertrait)
        list.add(ErrorCode.TraitConflictingImpl)
        list.add(ErrorCode.TraitOrphanRuleViolation)
        list.add(ErrorCode.TraitNegativeImplConflict)
        list.add(ErrorCode.TraitSealedTraitLeak)
        list.add(ErrorCode.TraitAssociatedTypeMissing)
        list.add(ErrorCode.TraitAssociatedTypeBound)
        list.add(ErrorCode.TraitDefaultImplConflict)
        list.add(ErrorCode.TraitMarkerTraitMisuse)
        list.add(ErrorCode.TraitDynTraitNotObjectSafe)
        list.add(ErrorCode.TraitDynTraitGeneric)
        list.add(ErrorCode.TraitTraitBoundUnmet)
        list.add(ErrorCode.TraitHigherRankedBound)
        list.add(ErrorCode.TraitTraitAliasCycle)
        list.add(ErrorCode.TraitImplForBoundParam)
        list.add(ErrorCode.TraitSpecializationFailure)
        list.add(ErrorCode.TraitAutoTraitNotImpl)
        list.add(ErrorCode.TraitAutoTraitConflict)
        list.add(ErrorCode.TraitCoordTraitAmbig)
        list.add(ErrorCode.TraitUnsafeTraitImpl)
        list.add(ErrorCode.TraitTraitMethodVisibility)
        list.add(ErrorCode.TraitWhereClauseOnImpl)
        list.add(ErrorCode.TraitBlanketImplConflict)
        list.add(ErrorCode.TraitTraitObjectCovariance)
        list.add(ErrorCode.TraitAssocTypeProjection)
        list.add(ErrorCode.TraitTraitMethodDefaultParam)
        list.add(ErrorCode.TraitAsyncTraitNotSupported)
        list.add(ErrorCode.TraitTraitMethodGenericClash)
        list.add(ErrorCode.TraitDuplicateAssocConst)
        list.add(ErrorCode.TraitAssocConstType)
        list.add(ErrorCode.TraitTraitMethodByName)
        list.add(ErrorCode.TraitImplGenericCount)
        list.add(ErrorCode.TraitTraitRequirementCycle)
        list.add(ErrorCode.TraitDispatchResolution)
        list.add(ErrorCode.TraitTraitMethodOverride)
        list.add(ErrorCode.TraitLateBoundParam)
        list.add(ErrorCode.TraitTraitInheritanceDepth)
        list.add(ErrorCode.TraitSelfImplConflict)
        list.add(ErrorCode.BorrowMoveOutOfBorrowed)
        list.add(ErrorCode.BorrowBorrowAfterMove)
        list.add(ErrorCode.BorrowMutableBorrowConflict)
        list.add(ErrorCode.BorrowAliasingMutableBorrow)
        list.add(ErrorCode.BorrowBorrowEscapesScope)
        list.add(ErrorCode.BorrowUseOfMovedValue)
        list.add(ErrorCode.BorrowPartialMoveStruct)
        list.add(ErrorCode.BorrowMoveInMatchGuard)
        list.add(ErrorCode.BorrowClosureCaptureByMove)
        list.add(ErrorCode.BorrowReturnReferenceToLocal)
        list.add(ErrorCode.BorrowTemporaryLifetime)
        list.add(ErrorCode.BorrowBorrowOfMovedField)
        list.add(ErrorCode.BorrowSelfBorrowInMethod)
        list.add(ErrorCode.BorrowReborrowFailed)
        list.add(ErrorCode.BorrowCopyTraitMissing)
        list.add(ErrorCode.BorrowDropDuringBorrow)
        list.add(ErrorCode.BorrowBorrowInMatchArm)
        list.add(ErrorCode.BorrowDoubleMutableBorrow)
        list.add(ErrorCode.BorrowImmutableToMutable)
        list.add(ErrorCode.BorrowBorrowInClosureArg)
        list.add(ErrorCode.BorrowUnsafeBypassBorrow)
        list.add(ErrorCode.BorrowPhantomBorrow)
        list.add(ErrorCode.BorrowBorrowInLoop)
        list.add(ErrorCode.BorrowFieldBorrowEscape)
        list.add(ErrorCode.BorrowGenericBorrowBound)
        list.add(ErrorCode.BorrowMoveAcrossAwait)
        list.add(ErrorCode.BorrowBorrowOfDropType)
        list.add(ErrorCode.BorrowReturnBorrowedParam)
        list.add(ErrorCode.BorrowSelfReferential)
        list.add(ErrorCode.BorrowAsyncMoveCapture)
        list.add(ErrorCode.BorrowBorrowInMatchGuard2)
        list.add(ErrorCode.BorrowStaticBorrowViolation)
        list.add(ErrorCode.BorrowInteriorMutRace)
        list.add(ErrorCode.BorrowBorrowOfUnsized)
        list.add(ErrorCode.BorrowScopedBorrowEnd)
        list.add(ErrorCode.BorrowMoveInClosure)
        list.add(ErrorCode.BorrowBorrowInMatchGuard3)
        list.add(ErrorCode.BorrowTemporaryBorrowDrop)
        list.add(ErrorCode.BorrowTraitObjectBorrow)
        list.add(ErrorCode.BorrowCoerceBorrowMismatch)
        list.add(ErrorCode.LifetimeUnboundedLifetime)
        list.add(ErrorCode.LifetimeLifetimeMismatch)
        list.add(ErrorCode.LifetimeMissingLifetime)
        list.add(ErrorCode.LifetimeAnonymousLifetimeConflict)
        list.add(ErrorCode.LifetimeStaticRequirements)
        list.add(ErrorCode.LifetimeLifetimeInTypeAlias)
        list.add(ErrorCode.LifetimeVarianceViolation)
        list.add(ErrorCode.LifetimeHigherRankedLifetime)
        list.add(ErrorCode.LifetimeLifetimeElisionFail)
        list.add(ErrorCode.LifetimeStructFieldLifetime)
        list.add(ErrorCode.LifetimeBorrowLifetimeShort)
        list.add(ErrorCode.LifetimeOutlivesFailure)
        list.add(ErrorCode.LifetimePhantomLifetime)
        list.add(ErrorCode.LifetimeAsyncLifetimeCapture)
        list.add(ErrorCode.LifetimeClosureLifetimeCapture)
        list.add(ErrorCode.LifetimeIteratorLifetime)
        list.add(ErrorCode.LifetimeTraitObjectLifetime)
        list.add(ErrorCode.LifetimeReturnRefLifetime)
        list.add(ErrorCode.LifetimeSelfLifetime)
        list.add(ErrorCode.LifetimeGenericLifetimeBound)
        list.add(ErrorCode.LifetimeCovariantReturnLifetime)
        list.add(ErrorCode.LifetimeLifetimeInImplTrait)
        list.add(ErrorCode.LifetimeNestedLifetime)
        list.add(ErrorCode.LifetimeStaticRefCapture)
        list.add(ErrorCode.LifetimeDropLifetime)
        list.add(ErrorCode.LifetimeLifetimeSubtyping)
        list.add(ErrorCode.LifetimeEarlyBoundLateBound)
        list.add(ErrorCode.LifetimeLifetimeInConst)
        list.add(ErrorCode.LifetimeYieldLifetime)
        list.add(ErrorCode.LifetimeBorrowSplitLifetime)
        list.add(ErrorCode.LifetimeFunctionPointerLifetime)
        list.add(ErrorCode.LifetimeArrayLifetime)
        list.add(ErrorCode.LifetimeUnionLifetime)
        list.add(ErrorCode.LifetimeTraitMethodLifetime)
        list.add(ErrorCode.LifetimeLifetimeNameConflict)
        list.add(ErrorCode.LifetimeRAIILifetime)
        list.add(ErrorCode.LifetimeGenericAssocLifetime)
        list.add(ErrorCode.LifetimeReferenceToTempLifetime)
        list.add(ErrorCode.LifetimeLifetimeOnTrait)
        list.add(ErrorCode.GenericArgumentCountMismatch)
        list.add(ErrorCode.GenericTypeArgumentInference)
        list.add(ErrorCode.GenericConstraintViolation)
        list.add(ErrorCode.GenericMissingTraitBound)
        list.add(ErrorCode.GenericRecursiveAlias)
        list.add(ErrorCode.GenericMonomorphizationFailed)
        list.add(ErrorCode.GenericCodeBloatLimit)
        list.add(ErrorCode.GenericHigherRankedBound)
        list.add(ErrorCode.GenericDefaultArgumentMissing)
        list.add(ErrorCode.GenericDefaultArgumentConflict)
        list.add(ErrorCode.GenericVarianceMismatch)
        list.add(ErrorCode.GenericUnsizedGeneric)
        list.add(ErrorCode.GenericAssociatedTypeUnbound)
        list.add(ErrorCode.GenericGATNotSupported)
        list.add(ErrorCode.GenericConstGenericMismatch)
        list.add(ErrorCode.GenericConstGenericNonConst)
        list.add(ErrorCode.GenericConstGenericOverflow)
        list.add(ErrorCode.GenericTraitObjectGeneric)
        list.add(ErrorCode.GenericImplGenericConflict)
        list.add(ErrorCode.GenericBlanketImplConflict)
        list.add(ErrorCode.GenericGenericMethodResolution)
        list.add(ErrorCode.GenericTypeParamShadow)
        list.add(ErrorCode.GenericGenericInEnum)
        list.add(ErrorCode.GenericGenericFunctionPointer)
        list.add(ErrorCode.GenericSpecializationFailed)
        list.add(ErrorCode.GenericPhantomTypeMismatch)
        list.add(ErrorCode.GenericWhereClauseUnmet)
        list.add(ErrorCode.GenericTypeParamCountInImpl)
        list.add(ErrorCode.GenericGenericAliasCycle)
        list.add(ErrorCode.GenericNegativeImplAmbig)
        list.add(ErrorCode.GenericGenericStructField)
        list.add(ErrorCode.GenericHigherRankedInType)
        list.add(ErrorCode.GenericGenericTraitBound)
        list.add(ErrorCode.GenericExistentialGeneric)
        list.add(ErrorCode.GenericGenericDefaultCycle)
        list.add(ErrorCode.GenericUnsoundGeneric)
        list.add(ErrorCode.GenericGenericCoherence)
        list.add(ErrorCode.GenericTupleGenericMismatch)
        list.add(ErrorCode.GenericArrayGenericLen)
        list.add(ErrorCode.GenericImplTraitPosition)
        list.add(ErrorCode.GenericGenericInlineCycle)
        list.add(ErrorCode.ModuleModuleNotFound)
        list.add(ErrorCode.ModuleFileNotFound)
        list.add(ErrorCode.ModuleCyclicModule)
        list.add(ErrorCode.ModuleDuplicateModule)
        list.add(ErrorCode.ModuleVisibilityViolation)
        list.add(ErrorCode.ModuleReexportConflict)
        list.add(ErrorCode.ModuleGlobConflict)
        list.add(ErrorCode.ModuleWrongModuleTree)
        list.add(ErrorCode.ModuleAnonymousModule)
        list.add(ErrorCode.ModuleModuleNameConflict)
        list.add(ErrorCode.ModuleNestedModuleDepth)
        list.add(ErrorCode.ModuleMacroUseScope)
        list.add(ErrorCode.ModulePathResolution)
        list.add(ErrorCode.ModuleSuperOutside)
        list.add(ErrorCode.ModuleCrateRootMissing)
        list.add(ErrorCode.ModuleInlineModuleConflict)
        list.add(ErrorCode.ModuleExternalCrateNotFound)
        list.add(ErrorCode.ModuleExternalCrateVersion)
        list.add(ErrorCode.ModuleFeatureGateModule)
        list.add(ErrorCode.ModulePrivateModuleLeak)
        list.add(ErrorCode.ModuleModuleInitOrder)
        list.add(ErrorCode.ModuleCfgModuleDisabled)
        list.add(ErrorCode.ModuleAmbiguousPath)
        list.add(ErrorCode.ModuleUseAsConflict)
        list.add(ErrorCode.ModuleTraitInModule)
        list.add(ErrorCode.ModuleStructInModule)
        list.add(ErrorCode.ModuleEnumVariantPath)
        list.add(ErrorCode.ModuleModuleDocConflict)
        list.add(ErrorCode.ModuleUnsafeModuleExport)
        list.add(ErrorCode.ModuleGenericModuleParam)
        list.add(ErrorCode.ModulePlatformModule)
        list.add(ErrorCode.ModuleTestModuleLeak)
        list.add(ErrorCode.ModuleBenchModule)
        list.add(ErrorCode.ModuleMacroModuleSep)
        list.add(ErrorCode.ModuleModuleCyclicReexport)
        list.add(ErrorCode.ModuleHiddenModule)
        list.add(ErrorCode.ModuleModuleAttrConflict)
        list.add(ErrorCode.ModuleNamespaceConflict)
        list.add(ErrorCode.ModuleInlineInFile)
        list.add(ErrorCode.ModuleEmptyModule)
        list.add(ErrorCode.BackendLlvmVerifyFailed)
        list.add(ErrorCode.BackendLlvmLoweringFailed)
        list.add(ErrorCode.BackendLlvmOptCrash)
        list.add(ErrorCode.BackendLlvmUnsupported)
        list.add(ErrorCode.BackendIrInvalid)
        list.add(ErrorCode.BackendIrTypeMismatch)
        list.add(ErrorCode.BackendIrMissingDef)
        list.add(ErrorCode.BackendIrUnreachable)
        list.add(ErrorCode.BackendRegisterAllocFailed)
        list.add(ErrorCode.BackendStackFrameTooLarge)
        list.add(ErrorCode.BackendCodeLayoutFailed)
        list.add(ErrorCode.BackendSectionEmitFailed)
        list.add(ErrorCode.BackendRelocationUnsupported)
        list.add(ErrorCode.BackendTargetFeatureAbsent)
        list.add(ErrorCode.BackendCallingConvUnknown)
        list.add(ErrorCode.BackendDebugInfoLost)
        list.add(ErrorCode.BackendEhTableTooLarge)
        list.add(ErrorCode.BackendGlobalInitFailed)
        list.add(ErrorCode.BackendConstantFoldBackend)
        list.add(ErrorCode.BackendAsmEmitFailed)
        list.add(ErrorCode.BackendVectorBackend)
        list.add(ErrorCode.BackendTailCallUnsupported)
        list.add(ErrorCode.BackendInlineAsmConstraint)
        list.add(ErrorCode.BackendMetadataEmit)
        list.add(ErrorCode.BackendModuleParse)
        list.add(ErrorCode.BackendTargetMachineInit)
        list.add(ErrorCode.BackendDataLayoutMismatch)
        list.add(ErrorCode.BackendABILowering)
        list.add(ErrorCode.BackendUnwindInfoFailed)
        list.add(ErrorCode.BackendProfileInstrument)
        list.add(ErrorCode.BackendSanitizerUnsupported)
        list.add(ErrorCode.BackendThinLtoFailed)
        list.add(ErrorCode.BackendLtoModuleConflict)
        list.add(ErrorCode.BackendBackendTimeout)
        list.add(ErrorCode.BackendBackendOOM)
        list.add(ErrorCode.BackendVerifierLimit)
        list.add(ErrorCode.BackendIntrinsicLowering)
        list.add(ErrorCode.BackendBlockAddressInvalid)
        list.add(ErrorCode.BackendComdatFailed)
        list.add(ErrorCode.BackendAliasEmitFailed)
        list.add(ErrorCode.BackendWeakSymbolConflict)
        list.add(ErrorCode.OptPassFailed)
        list.add(ErrorCode.OptPassCrashed)
        list.add(ErrorCode.OptInvalidation)
        list.add(ErrorCode.OptLoopUnrollFailed)
        list.add(ErrorCode.OptVectorizationFailed)
        list.add(ErrorCode.OptInliningFailed)
        list.add(ErrorCode.OptInliningTooDeep)
        list.add(ErrorCode.OptDeadCodeNotRemoved)
        list.add(ErrorCode.OptConstPropOverflow)
        list.add(ErrorCode.OptGvnConflict)
        list.add(ErrorCode.OptSccpFailed)
        list.add(ErrorCode.OptMem2RegFailed)
        list.add(ErrorCode.OptLoopInvariantFailed)
        list.add(ErrorCode.OptTailDuplicateFailed)
        list.add(ErrorCode.OptPeepholeFailed)
        list.add(ErrorCode.OptStrengthReduction)
        list.add(ErrorCode.OptAliasAnalysisFailed)
        list.add(ErrorCode.OptOptLevelInvalid)
        list.add(ErrorCode.OptOptSizeConflict)
        list.add(ErrorCode.OptProfileMismatch)
        list.add(ErrorCode.OptOptCorruptIr)
        list.add(ErrorCode.OptLoopRotateFailed)
        list.add(ErrorCode.OptGlobalOptFailed)
        list.add(ErrorCode.OptIpConstantProp)
        list.add(ErrorCode.OptArgumentPromotion)
        list.add(ErrorCode.OptStructRetOpt)
        list.add(ErrorCode.OptTailCallOptFailed)
        list.add(ErrorCode.OptSLPVectorizeFailed)
        list.add(ErrorCode.OptLoopVersioning)
        list.add(ErrorCode.OptPartialInline)
        list.add(ErrorCode.OptHotColdSplit)
        list.add(ErrorCode.OptMergeFuncFailed)
        list.add(ErrorCode.OptGVNLoadElim)
        list.add(ErrorCode.OptOptzLoopUnswitch)
        list.add(ErrorCode.OptReassociateFailed)
        list.add(ErrorCode.OptOptLoopIdiom)
        list.add(ErrorCode.OptCFGSimplifyFailed)
        list.add(ErrorCode.OptOptIndVar)
        list.add(ErrorCode.OptDivRemOpt)
        list.add(ErrorCode.OptOptShiftBase)
        list.add(ErrorCode.OptOptFloatReassoc)
        list.add(ErrorCode.LinkerLinkerNotFound)
        list.add(ErrorCode.LinkerLinkerInvocation)
        list.add(ErrorCode.LinkerUndefinedSymbol)
        list.add(ErrorCode.LinkerDuplicateSymbol)
        list.add(ErrorCode.LinkerLibraryNotFound)
        list.add(ErrorCode.LinkerLibraryVersion)
        list.add(ErrorCode.LinkerMissingEntryPoint)
        list.add(ErrorCode.LinkerRelocOverflow)
        list.add(ErrorCode.LinkerArchMismatch)
        list.add(ErrorCode.LinkerAbiMismatch)
        list.add(ErrorCode.LinkerLinkScriptError)
        list.add(ErrorCode.LinkerStaticDynamicConflict)
        list.add(ErrorCode.LinkerStdLibLinkFailed)
        list.add(ErrorCode.LinkerRuntimeLibMissing)
        list.add(ErrorCode.LinkerLinkerOOM)
        list.add(ErrorCode.LinkerLinkerTimeout)
        list.add(ErrorCode.LinkerThreadLocalLink)
        list.add(ErrorCode.LinkerWeakSymbolUnresolved)
        list.add(ErrorCode.LinkerExportSymbolMissing)
        list.add(ErrorCode.LinkerImportLibraryMissing)
        list.add(ErrorCode.LinkerCOMDATConflict)
        list.add(ErrorCode.LinkerLinkOrderError)
        list.add(ErrorCode.LinkerBitcodeLinkFailed)
        list.add(ErrorCode.LinkerLTOFailed)
        list.add(ErrorCode.LinkerLinkerScriptUnknown)
        list.add(ErrorCode.LinkerDynamicLibMissing)
        list.add(ErrorCode.LinkerRpathInvalid)
        list.add(ErrorCode.LinkerSymbolVisibility)
        list.add(ErrorCode.LinkerLinkerLangMismatch)
        list.add(ErrorCode.LinkerGCSectionsFailed)
        list.add(ErrorCode.LinkerMmapLinkFailed)
        list.add(ErrorCode.LinkerLinkSanitizer)
        list.add(ErrorCode.LinkerDeadStripFailed)
        list.add(ErrorCode.LinkerLinkerPluginError)
        list.add(ErrorCode.LinkerCrtFileMissing)
        list.add(ErrorCode.LinkerLinkerVersionOld)
        list.add(ErrorCode.LinkerMangledNameConflict)
        list.add(ErrorCode.LinkerPieUnsupported)
        list.add(ErrorCode.LinkerLinkerStackSize)
        list.add(ErrorCode.LinkerUnwindLibMissing)
        list.add(ErrorCode.AbiFfiSignatureMismatch)
        list.add(ErrorCode.AbiFfiTypeUnsupported)
        list.add(ErrorCode.AbiCAbiMismatch)
        list.add(ErrorCode.AbiStructLayoutMismatch)
        list.add(ErrorCode.AbiEnumReprMismatch)
        list.add(ErrorCode.AbiUnionLayout)
        list.add(ErrorCode.AbiCallbackAbiMismatch)
        list.add(ErrorCode.AbiVarargsUnsupported)
        list.add(ErrorCode.AbiFfiUnsafeCall)
        list.add(ErrorCode.AbiFfiLifetimeViolation)
        list.add(ErrorCode.AbiFfiPanicAcross)
        list.add(ErrorCode.AbiFfiAllocMismatch)
        list.add(ErrorCode.AbiFloatAbiMismatch)
        list.add(ErrorCode.AbiRegisterAbiMismatch)
        list.add(ErrorCode.AbiEndiannessMismatch)
        list.add(ErrorCode.AbiAlignAbiMismatch)
        list.add(ErrorCode.AbiNameMangling)
        list.add(ErrorCode.AbiFfiCharEncoding)
        list.add(ErrorCode.AbiFfiBoolSize)
        list.add(ErrorCode.AbiFfiEnumSize)
        list.add(ErrorCode.AbiFfiPointerNull)
        list.add(ErrorCode.AbiFfiWideChar)
        list.add(ErrorCode.AbiFfiLongSize)
        list.add(ErrorCode.AbiFfiStructPass)
        list.add(ErrorCode.AbiFfiUnwindAbi)
        list.add(ErrorCode.AbiFfiVectorAbi)
        list.add(ErrorCode.AbiFfiComplexType)
        list.add(ErrorCode.AbiFfiBitfield)
        list.add(ErrorCode.AbiFfiVaList)
        list.add(ErrorCode.AbiFfiThreadLocal)
        list.add(ErrorCode.AbiFfiCallingConvention)
        list.add(ErrorCode.AbiFfiNonPod)
        list.add(ErrorCode.AbiFfiDtorLeak)
        list.add(ErrorCode.AbiFfiCallbackLifetime)
        list.add(ErrorCode.AbiFfiResourceLeak)
        list.add(ErrorCode.AbiFfiSignalUnsafe)
        list.add(ErrorCode.AbiFfiLongjmp)
        list.add(ErrorCode.AbiFfiComdat)
        list.add(ErrorCode.AbiFfiTypeSize)
        list.add(ErrorCode.AbiFfiConstMismatch)
        list.add(ErrorCode.ConcurrencyThreadSpawnFailed)
        list.add(ErrorCode.ConcurrencyThreadLimitExceeded)
        list.add(ErrorCode.ConcurrencyDataRaceDetected)
        list.add(ErrorCode.ConcurrencyDeadlockDetected)
        list.add(ErrorCode.ConcurrencyLockPoisoned)
        list.add(ErrorCode.ConcurrencyCondVarSpurious)
        list.add(ErrorCode.ConcurrencyChannelClosed)
        list.add(ErrorCode.ConcurrencyChannelSendBlocked)
        list.add(ErrorCode.ConcurrencyChannelRecvEmpty)
        list.add(ErrorCode.ConcurrencyActorMailboxFull)
        list.add(ErrorCode.ConcurrencyActorStopped)
        list.add(ErrorCode.ConcurrencyFutureNotPolled)
        list.add(ErrorCode.ConcurrencyExecutorShutdown)
        list.add(ErrorCode.ConcurrencyAwaitOutsideAsync)
        list.add(ErrorCode.ConcurrencyAsyncRecursion)
        list.add(ErrorCode.ConcurrencyCoroutineSuspendInvalid)
        list.add(ErrorCode.ConcurrencyCoroutineLeak)
        list.add(ErrorCode.ConcurrencyAtomicMisuse)
        list.add(ErrorCode.ConcurrencyMemoryOrderInvalid)
        list.add(ErrorCode.ConcurrencyRwLockDeadlock)
        list.add(ErrorCode.ConcurrencyMutexDoubleLock)
        list.add(ErrorCode.ConcurrencyBarrierWait)
        list.add(ErrorCode.ConcurrencySemaphoreOverflow)
        list.add(ErrorCode.ConcurrencyOnceInitPanic)
        list.add(ErrorCode.ConcurrencyThreadLocalAccess)
        list.add(ErrorCode.ConcurrencyRaceOnInit)
        list.add(ErrorCode.ConcurrencyParkUnparkLost)
        list.add(ErrorCode.ConcurrencyTaskCanceled)
        list.add(ErrorCode.ConcurrencyAffinityFailed)
        list.add(ErrorCode.ConcurrencyStackSizeInvalid)
        list.add(ErrorCode.ConcurrencyAsyncDropCycle)
        list.add(ErrorCode.ConcurrencyExecutorStarvation)
        list.add(ErrorCode.ConcurrencySelectArmConflict)
        list.add(ErrorCode.ConcurrencyChannelCapacityZero)
        list.add(ErrorCode.ConcurrencyLockOrderInversion)
        list.add(ErrorCode.ConcurrencyNonSendCaptured)
        list.add(ErrorCode.ConcurrencyNonSyncShared)
        list.add(ErrorCode.ConcurrencyWatchdogTimeout)
        list.add(ErrorCode.ConcurrencyCpuAffinityUnsupported)
        list.add(ErrorCode.ConcurrencyCoroutineStackExhaust)
        list.add(ErrorCode.ConcurrencyWorkStealFailed)
        list.add(ErrorCode.MemOutOfMemory)
        list.add(ErrorCode.MemDoubleFree)
        list.add(ErrorCode.MemUseAfterFree)
        list.add(ErrorCode.MemHeapCorruption)
        list.add(ErrorCode.MemLeakDetected)
        list.add(ErrorCode.MemInvalidFree)
        list.add(ErrorCode.MemUnalignedAccess)
        list.add(ErrorCode.MemNullDereference)
        list.add(ErrorCode.MemBufferOverflow)
        list.add(ErrorCode.MemBufferUnderflow)
        list.add(ErrorCode.MemStackOverflow)
        list.add(ErrorCode.MemGcPauseTooLong)
        list.add(ErrorCode.MemGcPromotionFailed)
        list.add(ErrorCode.MemGcFragmentation)
        list.add(ErrorCode.MemGcCycleLeak)
        list.add(ErrorCode.MemFinalizerDeadlock)
        list.add(ErrorCode.MemFinalizerRunsLate)
        list.add(ErrorCode.MemAllocatorMismatch)
        list.add(ErrorCode.MemCustomAllocFail)
        list.add(ErrorCode.MemAlignmentTooLarge)
        list.add(ErrorCode.MemZeroSizeAlloc)
        list.add(ErrorCode.MemReallocShrinkLost)
        list.add(ErrorCode.MemMemoryMapFailed)
        list.add(ErrorCode.MemGuardPageViolation)
        list.add(ErrorCode.MemDanglingPointer)
        list.add(ErrorCode.MemWildPointer)
        list.add(ErrorCode.MemReferenceCycle)
        list.add(ErrorCode.MemArcStrongZero)
        list.add(ErrorCode.MemWeakUpgradeFail)
        list.add(ErrorCode.MemArenaExhausted)
        list.add(ErrorCode.MemArenaDoubleFree)
        list.add(ErrorCode.MemStackUnwindCorrupt)
        list.add(ErrorCode.MemMoveUninit)
        list.add(ErrorCode.MemReadUninit)
        list.add(ErrorCode.MemPaddingLeak)
        list.add(ErrorCode.MemMemoryTagError)
        list.add(ErrorCode.MemHugepageFailed)
        list.add(ErrorCode.MemNumaBindFailed)
        list.add(ErrorCode.MemOvercommitExceeded)
        list.add(ErrorCode.MemGcRootLost)
        list.add(ErrorCode.MemAllocatorDeadlock)
        list.add(ErrorCode.OsFileNotFound)
        list.add(ErrorCode.OsPermissionDenied)
        list.add(ErrorCode.OsIoError)
        list.add(ErrorCode.OsBrokenPipe)
        list.add(ErrorCode.OsTooManyOpenFiles)
        list.add(ErrorCode.OsDiskFull)
        list.add(ErrorCode.OsNoSuchProcess)
        list.add(ErrorCode.OsProcessSpawnFailed)
        list.add(ErrorCode.OsSignalReceived)
        list.add(ErrorCode.OsTimeoutExceeded)
        list.add(ErrorCode.OsResourceLimit)
        list.add(ErrorCode.OsAddressInUse)
        list.add(ErrorCode.OsConnectionRefused)
        list.add(ErrorCode.OsNetworkUnreachable)
        list.add(ErrorCode.OsDnsResolveFailed)
        list.add(ErrorCode.OsEnvVarMissing)
        list.add(ErrorCode.OsEnvVarInvalid)
        list.add(ErrorCode.OsWorkingDirMissing)
        list.add(ErrorCode.OsSymlinkLoop)
        list.add(ErrorCode.OsReadOnlyFileSystem)
        list.add(ErrorCode.OsQuotaExceeded)
        list.add(ErrorCode.OsInvalidUtf8Path)
        list.add(ErrorCode.OsThreadPriorityFailed)
        list.add(ErrorCode.OsClockError)
        list.add(ErrorCode.OsInsufficientMemory)
        list.add(ErrorCode.OsLockFileHeld)
        list.add(ErrorCode.OsSharedMemFailed)
        list.add(ErrorCode.OsMmapExecDenied)
        list.add(ErrorCode.OsSeccompBlocked)
        list.add(ErrorCode.OsCapabilityMissing)
        list.add(ErrorCode.OsChrootFailed)
        list.add(ErrorCode.OsMountFailed)
        list.add(ErrorCode.OsNoSuchDevice)
        list.add(ErrorCode.OsDeviceBusy)
        list.add(ErrorCode.OsInvalidFd)
        list.add(ErrorCode.OsPollFailed)
        list.add(ErrorCode.OsPipeBufferFull)
        list.add(ErrorCode.OsForkNotAllowed)
        list.add(ErrorCode.OsProcessAlreadyExited)
        list.add(ErrorCode.OsUserNamespaceFailed)
        list.add(ErrorCode.OsFileSystemType)
        list.add(ErrorCode.LspInvalidRequest)
        list.add(ErrorCode.LspDocumentNotFound)
        list.add(ErrorCode.LspPositionOutOfRange)
        list.add(ErrorCode.LspUnsupportedCapability)
        list.add(ErrorCode.LspDiagnosticsStale)
        list.add(ErrorCode.LspSemanticTokensFailed)
        list.add(ErrorCode.LspCompletionFailed)
        list.add(ErrorCode.LspHoverFailed)
        list.add(ErrorCode.LspDefinitionNotFound)
        list.add(ErrorCode.LspReferenceSearchFailed)
        list.add(ErrorCode.LspRenameFailed)
        list.add(ErrorCode.LspFormatFailed)
        list.add(ErrorCode.LspCodeActionFailed)
        list.add(ErrorCode.LspInlayHintFailed)
        list.add(ErrorCode.LspFoldingFailed)
        list.add(ErrorCode.LspDocumentLinkFailed)
        list.add(ErrorCode.LspWorkspaceSymbolFailed)
        list.add(ErrorCode.LspConfigurationMissing)
        list.add(ErrorCode.LspServerPanic)
        list.add(ErrorCode.LspProtocolVersion)
        list.add(ErrorCode.LspEncodingMismatch)
        list.add(ErrorCode.LspLineEndingMismatch)
        list.add(ErrorCode.LspLargeDocument)
        list.add(ErrorCode.LspDebounceSkipped)
        list.add(ErrorCode.LspIndexCorrupt)
        list.add(ErrorCode.LspSlowAnalysis)
        list.add(ErrorCode.LspMissingSource)
        list.add(ErrorCode.LspUnknownDiagnostic)
        list.add(ErrorCode.LspRpcParseFailed)
        list.add(ErrorCode.LspCancelledRequest)
        list.add(ErrorCode.LspCrashRecovery)
        list.add(ErrorCode.LspWorkspaceFolder)
        list.add(ErrorCode.LspFileWatcherFailed)
        list.add(ErrorCode.LspDiagnosticDuplicate)
        list.add(ErrorCode.LspTelemetryDisabled)
        list.add(ErrorCode.LspClientInitFailed)
        list.add(ErrorCode.LspProgressFailed)
        list.add(ErrorCode.LspLinkedEditingFailed)
        list.add(ErrorCode.LspCallHierarchyFailed)
        list.add(ErrorCode.LspTypeHierarchyFailed)
        list.add(ErrorCode.LspDocumentColorFailed)
        list.add(ErrorCode.IncrementalCacheMissing)
        list.add(ErrorCode.IncrementalCacheCorrupt)
        list.add(ErrorCode.IncrementalCacheVersionMismatch)
        list.add(ErrorCode.IncrementalDepFileStale)
        list.add(ErrorCode.IncrementalHashMismatch)
        list.add(ErrorCode.IncrementalFingerprintFailed)
        list.add(ErrorCode.IncrementalQueryCycle)
        list.add(ErrorCode.IncrementalDirtyNode)
        list.add(ErrorCode.IncrementalSerializedFailed)
        list.add(ErrorCode.IncrementalDeserializeFailed)
        list.add(ErrorCode.IncrementalCacheEvicted)
        list.add(ErrorCode.IncrementalUpToDateFalse)
        list.add(ErrorCode.IncrementalRebuildCascade)
        list.add(ErrorCode.IncrementalLockContention)
        list.add(ErrorCode.IncrementalPermissionDenied)
        list.add(ErrorCode.IncrementalDiskFull)
        list.add(ErrorCode.IncrementalConcurrentWrite)
        list.add(ErrorCode.IncrementalMetadataMismatch)
        list.add(ErrorCode.IncrementalIncrementalDisabled)
        list.add(ErrorCode.IncrementalChangedEnv)
        list.add(ErrorCode.IncrementalChangedFlags)
        list.add(ErrorCode.IncrementalChangedTarget)
        list.add(ErrorCode.IncrementalFingerprintSalt)
        list.add(ErrorCode.IncrementalNodeLimit)
        list.add(ErrorCode.IncrementalGraphTooLarge)
        list.add(ErrorCode.IncrementalCachePathTooLong)
        list.add(ErrorCode.IncrementalSymlinkCache)
        list.add(ErrorCode.IncrementalToolchainChanged)
        list.add(ErrorCode.IncrementalIncrementalPanic)
        list.add(ErrorCode.IncrementalQueryStackOverflow)
        list.add(ErrorCode.IncrementalCacheReadTimeout)
        list.add(ErrorCode.IncrementalPersistentCache)
        list.add(ErrorCode.IncrementalDirtyAll)
        list.add(ErrorCode.IncrementalHashCollision)
        list.add(ErrorCode.IncrementalDepTrackingLost)
        list.add(ErrorCode.IncrementalIncrementalOOM)
        list.add(ErrorCode.IncrementalVersionDowngrade)
        list.add(ErrorCode.IncrementalCacheMigration)
        list.add(ErrorCode.IncrementalUntrackedInput)
        list.add(ErrorCode.PkgManifestNotFound)
        list.add(ErrorCode.PkgManifestParse)
        list.add(ErrorCode.PkgDependencyMissing)
        list.add(ErrorCode.PkgDependencyVersion)
        list.add(ErrorCode.PkgDependencyConflict)
        list.add(ErrorCode.PkgRegistryUnreachable)
        list.add(ErrorCode.PkgDownloadFailed)
        list.add(ErrorCode.PkgChecksumMismatch)
        list.add(ErrorCode.PkgLockfileStale)
        list.add(ErrorCode.PkgLockfileConflict)
        list.add(ErrorCode.PkgCircularDependency)
        list.add(ErrorCode.PkgFeatureNotFound)
        list.add(ErrorCode.PkgFeatureConflict)
        list.add(ErrorCode.PkgBuildScriptFailed)
        list.add(ErrorCode.PkgGitDependencyFailed)
        list.add(ErrorCode.PkgLocalPathMissing)
        list.add(ErrorCode.PkgPublishDenied)
        list.add(ErrorCode.PkgPackageNameInvalid)
        list.add(ErrorCode.PkgPackageVersionInvalid)
        list.add(ErrorCode.PkgYankedPackage)
        list.add(ErrorCode.PkgUnresolvedProxy)
        list.add(ErrorCode.PkgMirrorSync)
        list.add(ErrorCode.PkgLicenseMissing)
        list.add(ErrorCode.PkgLicenseConflict)
        list.add(ErrorCode.PkgPrivatePackage)
        list.add(ErrorCode.PkgTokenExpired)
        list.add(ErrorCode.PkgPackageTooLarge)
        list.add(ErrorCode.PkgInvalidMetadata)
        list.add(ErrorCode.PkgSourceIncompatible)
        list.add(ErrorCode.PkgPlatformSpecificDep)
        list.add(ErrorCode.PkgOptionalDepMissing)
        list.add(ErrorCode.PkgDevDependencyLeak)
        list.add(ErrorCode.PkgPatchConflict)
        list.add(ErrorCode.PkgWorkspaceMember)
        list.add(ErrorCode.PkgWorkspaceInherit)
        list.add(ErrorCode.PkgOverridesConflict)
        list.add(ErrorCode.PkgVendoredMismatch)
        list.add(ErrorCode.PkgCachePermission)
        list.add(ErrorCode.PkgResolveTimeout)
        list.add(ErrorCode.PkgDuplicatePackage)
        list.add(ErrorCode.PkgTargetSpecificManifest)
        list.add(ErrorCode.BuildBuildScriptPanic)
        list.add(ErrorCode.BuildBuildTargetMissing)
        list.add(ErrorCode.BuildBuildProfileUnknown)
        list.add(ErrorCode.BuildArtifactNotFound)
        list.add(ErrorCode.BuildCompileStepFailed)
        list.add(ErrorCode.BuildLinkStepFailed)
        list.add(ErrorCode.BuildCustomTargetFailed)
        list.add(ErrorCode.BuildBuildCacheInvalid)
        list.add(ErrorCode.BuildParallelBuildDeadlock)
        list.add(ErrorCode.BuildJobServerUnavailable)
        list.add(ErrorCode.BuildOutputDirLocked)
        list.add(ErrorCode.BuildPermissionDenied)
        list.add(ErrorCode.BuildDiskFull)
        list.add(ErrorCode.BuildBuildTimeout)
        list.add(ErrorCode.BuildIncrementalDisabled)
        list.add(ErrorCode.BuildFeatureGateBuild)
        list.add(ErrorCode.BuildCrossCompileToolchain)
        list.add(ErrorCode.BuildSysrootMissing)
        list.add(ErrorCode.BuildEnvVarMissing)
        list.add(ErrorCode.BuildBuildScriptEnv)
        list.add(ErrorCode.BuildFingerprintMismatch)
        list.add(ErrorCode.BuildDepInfoStale)
        list.add(ErrorCode.BuildTargetTripleInvalid)
        list.add(ErrorCode.BuildBuildPlanFailed)
        list.add(ErrorCode.BuildPostBuildFailed)
        list.add(ErrorCode.BuildTestHarnessFailed)
        list.add(ErrorCode.BuildBenchHarnessFailed)
        list.add(ErrorCode.BuildDocBuildFailed)
        list.add(ErrorCode.BuildExampleBuildFailed)
        list.add(ErrorCode.BuildToolchainDownload)
        list.add(ErrorCode.BuildRustflagsConflict)
        list.add(ErrorCode.BuildCfgNotDefined)
        list.add(ErrorCode.BuildBuildScriptRebuild)
        list.add(ErrorCode.BuildLockContention)
        list.add(ErrorCode.BuildTargetSpecificFail)
        list.add(ErrorCode.BuildOutOfMemory)
        list.add(ErrorCode.BuildSignalInterrupted)
        list.add(ErrorCode.BuildTmpDirUnwritable)
        list.add(ErrorCode.BuildBuildHookFailed)
        list.add(ErrorCode.BuildUnsupportedAction)
        list.add(ErrorCode.DebugDwarfEmitFailed)
        list.add(ErrorCode.DebugDebugInfoStripped)
        list.add(ErrorCode.DebugLineTableMissing)
        list.add(ErrorCode.DebugVariableLocation)
        list.add(ErrorCode.DebugTypeInfoMissing)
        list.add(ErrorCode.DebugInlinedFrame)
        list.add(ErrorCode.DebugBreakpointUnavailable)
        list.add(ErrorCode.DebugWatchpointFailed)
        list.add(ErrorCode.DebugSymbolNotFound)
        list.add(ErrorCode.DebugSourceMapMissing)
        list.add(ErrorCode.DebugPdbEmitFailed)
        list.add(ErrorCode.DebugDebuggerAttachFailed)
        list.add(ErrorCode.DebugCoreDumpFailed)
        list.add(ErrorCode.DebugBacktraceUnavailable)
        list.add(ErrorCode.DebugOptimizedOut)
        list.add(ErrorCode.DebugDebugMacroInfo)
        list.add(ErrorCode.DebugNamespaceInfoMissing)
        list.add(ErrorCode.DebugTemplateInfoMissing)
        list.add(ErrorCode.DebugSplitDebugFailed)
        list.add(ErrorCode.DebugDebugCompression)
        list.add(ErrorCode.DebugLineZero)
        list.add(ErrorCode.DebugColumnInfoMissing)
        list.add(ErrorCode.DebugInheritanceInfo)
        list.add(ErrorCode.DebugAsyncBacktrace)
        list.add(ErrorCode.DebugDebugPrettyPrinter)
        list.add(ErrorCode.DebugEvalFailed)
        list.add(ErrorCode.DebugConditionalBreakpoint)
        list.add(ErrorCode.DebugDebugServerDown)
        list.add(ErrorCode.DebugProtocolHandshake)
        list.add(ErrorCode.DebugSymbolicateFailed)
        list.add(ErrorCode.DebugDebugInfoMismatch)
        list.add(ErrorCode.DebugFrameCorrupt)
        list.add(ErrorCode.DebugUnwindInfoMissing)
        list.add(ErrorCode.DebugDebugSectionsStripped)
        list.add(ErrorCode.DebugTypeAliasInfo)
        list.add(ErrorCode.DebugLocalVarOmitted)
        list.add(ErrorCode.DebugDebugInfoTooLarge)
        list.add(ErrorCode.DebugCorruptDebugInfo)
        list.add(ErrorCode.DebugMissingCompilationUnit)
        list.add(ErrorCode.DebugDebugArangesMissing)
        list.add(ErrorCode.DistRemoteNodeDown)
        list.add(ErrorCode.DistSchedulerUnreachable)
        list.add(ErrorCode.DistJobDispatchFailed)
        list.add(ErrorCode.DistResultFetchFailed)
        list.add(ErrorCode.DistNodeAuthFailed)
        list.add(ErrorCode.DistInconsistentEnv)
        list.add(ErrorCode.DistCacheSyncFailed)
        list.add(ErrorCode.DistNetworkPartition)
        list.add(ErrorCode.DistTimeoutExceeded)
        list.add(ErrorCode.DistResultCorrupt)
        list.add(ErrorCode.DistNodeOverloaded)
        list.add(ErrorCode.DistArtifactMismatch)
        list.add(ErrorCode.DistUnsupportedTarget)
        list.add(ErrorCode.DistCompilationUnitTooBig)
        list.add(ErrorCode.DistDependencyNotCached)
        list.add(ErrorCode.DistSecureChannelFailed)
        list.add(ErrorCode.DistHeartbeatLost)
        list.add(ErrorCode.DistQuotaExceeded)
        list.add(ErrorCode.DistRegionMismatch)
        list.add(ErrorCode.DistSerializationFailed)
        list.add(ErrorCode.DistDeserializationFailed)
        list.add(ErrorCode.DistVersionSkew)
        list.add(ErrorCode.DistPartialFailure)
        list.add(ErrorCode.DistLoadImbalance)
        list.add(ErrorCode.DistIdempotencyViolation)
        list.add(ErrorCode.DistCachePoisoned)
        list.add(ErrorCode.DistBandwidthLimited)
        list.add(ErrorCode.DistNodeBlacklisted)
        list.add(ErrorCode.DistCompilationAborted)
        list.add(ErrorCode.DistCheckpointFailed)
        list.add(ErrorCode.DistRecoverFailed)
        list.add(ErrorCode.DistTokenExpired)
        list.add(ErrorCode.DistMisconfiguredPool)
        list.add(ErrorCode.DistCompilationDrift)
        list.add(ErrorCode.DistAuditLogMissing)
        list.add(ErrorCode.DistColdStart)
        list.add(ErrorCode.DistResourceContention)
        list.add(ErrorCode.DistUnsupportedFeature)
        list.add(ErrorCode.PluginPluginNotFound)
        list.add(ErrorCode.PluginPluginLoadFailed)
        list.add(ErrorCode.PluginPluginVersionMismatch)
        list.add(ErrorCode.PluginPluginApiChanged)
        list.add(ErrorCode.PluginPluginPanic)
        list.add(ErrorCode.PluginPluginTimeout)
        list.add(ErrorCode.PluginPluginPermissionDenied)
        list.add(ErrorCode.PluginPluginConflict)
        list.add(ErrorCode.PluginPluginSignatureInvalid)
        list.add(ErrorCode.PluginPluginUnsafeOperation)
        list.add(ErrorCode.PluginPluginInitFailed)
        list.add(ErrorCode.PluginPluginDepMissing)
        list.add(ErrorCode.PluginPluginConfigInvalid)
        list.add(ErrorCode.PluginPluginHookError)
        list.add(ErrorCode.PluginPluginResourceLeak)
        list.add(ErrorCode.PluginPluginCrashed)
        list.add(ErrorCode.PluginPluginDisabled)
        list.add(ErrorCode.PluginPluginTooOld)
        list.add(ErrorCode.PluginPluginTooNew)
        list.add(ErrorCode.PluginPluginNameConflict)
        list.add(ErrorCode.PluginPluginCycle)
        list.add(ErrorCode.PluginPluginSandboxViolation)
        list.add(ErrorCode.PluginPluginOutOfMemory)
        list.add(ErrorCode.PluginPluginDeadlock)
        list.add(ErrorCode.PluginPluginNetworkBlocked)
        list.add(ErrorCode.PluginPluginFileSystemBlocked)
        list.add(ErrorCode.PluginPluginEnvBlocked)
        list.add(ErrorCode.PluginPluginUnserialize)
        list.add(ErrorCode.PluginPluginHotReloadFailed)
        list.add(ErrorCode.PluginPluginUnloadFailed)
        list.add(ErrorCode.PluginPluginCapabilityMissing)
        list.add(ErrorCode.PluginPluginDeprecated)
        list.add(ErrorCode.PluginPluginManifestInvalid)
        list.add(ErrorCode.PluginPluginEntryMissing)
        list.add(ErrorCode.PluginPluginAbiMismatch)
        list.add(ErrorCode.PluginPluginLangMismatch)
        list.add(ErrorCode.PluginPluginBadExit)
        list.add(ErrorCode.PluginPluginStdoutParse)
        list.add(ErrorCode.PluginPluginLockContention)
        list.add(ErrorCode.TgtTargetTripleInvalid)
        list.add(ErrorCode.TgtTargetUnsupported)
        list.add(ErrorCode.TgtTargetFeatureMissing)
        list.add(ErrorCode.TgtTargetArchUnknown)
        list.add(ErrorCode.TgtTargetOsUnknown)
        list.add(ErrorCode.TgtTargetEnvUnknown)
        list.add(ErrorCode.TgtTargetVendorUnknown)
        list.add(ErrorCode.TgtTargetPointerWidth)
        list.add(ErrorCode.TgtTargetEndianUnknown)
        list.add(ErrorCode.TgtTargetFloatUnsupported)
        list.add(ErrorCode.TgtTargetAtomicMissing)
        list.add(ErrorCode.TgtTargetSimdAbsent)
        list.add(ErrorCode.TgtTargetTlsModel)
        list.add(ErrorCode.TgtTargetRelocation)
        list.add(ErrorCode.TgtTargetCodeModel)
        list.add(ErrorCode.TgtTargetCpuUnknown)
        list.add(ErrorCode.TgtTargetFpuUnknown)
        list.add(ErrorCode.TgtTargetAbiUnknown)
        list.add(ErrorCode.TgtTargetPanicStrategy)
        list.add(ErrorCode.TgtTargetAllocStrategy)
        list.add(ErrorCode.TgtTargetSyscallConv)
        list.add(ErrorCode.TgtTargetStackProbe)
        list.add(ErrorCode.TgtTargetExceptionModel)
        list.add(ErrorCode.TgtTargetDebugFormat)
        list.add(ErrorCode.TgtTargetObjFormat)
        list.add(ErrorCode.TgtTargetLinkerMissing)
        list.add(ErrorCode.TgtTargetRuntimeMissing)
        list.add(ErrorCode.TgtTargetLibcMissing)
        list.add(ErrorCode.TgtTargetNoStd)
        list.add(ErrorCode.TgtTargetNoAtomic)
        list.add(ErrorCode.TgtTargetUnsupportedFloat)
        list.add(ErrorCode.TgtTargetRegisterWidth)
        list.add(ErrorCode.TgtTargetProfiling)
        list.add(ErrorCode.TgtTargetSanitizerAbsent)
        list.add(ErrorCode.TgtTargetCoverage)
        list.add(ErrorCode.TgtTargetPositionIndependent)
        list.add(ErrorCode.TgtTargetThreadLocal)
        list.add(ErrorCode.TgtTargetUnwindUnsupported)
        list.add(ErrorCode.TgtTargetVendorLibMissing)
        list.add(ErrorCode.SimdSimdWidthUnsupported)
        list.add(ErrorCode.SimdSimdTypeMismatch)
        list.add(ErrorCode.SimdSimdLaneCount)
        list.add(ErrorCode.SimdSimdUnaligned)
        list.add(ErrorCode.SimdSimdMaskInvalid)
        list.add(ErrorCode.SimdSimdReductionFailed)
        list.add(ErrorCode.SimdSimdShuffleInvalid)
        list.add(ErrorCode.SimdSimdGatherScatter)
        list.add(ErrorCode.SimdSimdIntrinsicMissing)
        list.add(ErrorCode.SimdSimdOverflow)
        list.add(ErrorCode.SimdSimdDivByZero)
        list.add(ErrorCode.SimdSimdNanPropagate)
        list.add(ErrorCode.SimdSimdConstantInvalid)
        list.add(ErrorCode.SimdSimdCvtFailed)
        list.add(ErrorCode.SimdSimdPermuteFailed)
        list.add(ErrorCode.SimdSimdBlendInvalid)
        list.add(ErrorCode.SimdSimdExtractOob)
        list.add(ErrorCode.SimdSimdInsertOob)
        list.add(ErrorCode.SimdSimdCompareResult)
        list.add(ErrorCode.SimdSimdBitcast)
        list.add(ErrorCode.SimdSimdAlignment)
        list.add(ErrorCode.SimdSimdTargetAbsent)
        list.add(ErrorCode.SimdSimdLengthMismatch)
        list.add(ErrorCode.SimdSimdSignedUnsigned)
        list.add(ErrorCode.SimdSimdRounding)
        list.add(ErrorCode.SimdSimdSaturation)
        list.add(ErrorCode.SimdSimdFmaMissing)
        list.add(ErrorCode.SimdSimdConflict)
        list.add(ErrorCode.SimdSimdRegisterPressure)
        list.add(ErrorCode.SimdSimdLaneOrder)
        list.add(ErrorCode.SimdSimdPredicateInvalid)
        list.add(ErrorCode.SimdSimdRotated)
        list.add(ErrorCode.SimdSimdPopcount)
        list.add(ErrorCode.SimdSimdShiftOob)
        list.add(ErrorCode.SimdSimdSelectInvalid)
        list.add(ErrorCode.SimdSimdWidenFailed)
        list.add(ErrorCode.SimdSimdNarrowFailed)
        list.add(ErrorCode.SimdSimdInterleave)
        list.add(ErrorCode.SimdSimdDeinterleave)
        list.add(ErrorCode.EmbedEmbedNoStd)
        list.add(ErrorCode.EmbedEmbedNoAlloc)
        list.add(ErrorCode.EmbedEmbedFlashFull)
        list.add(ErrorCode.EmbedEmbedRamFull)
        list.add(ErrorCode.EmbedEmbedNoFloat)
        list.add(ErrorCode.EmbedEmbedNoException)
        list.add(ErrorCode.EmbedEmbedNoRtti)
        list.add(ErrorCode.EmbedEmbedHardFault)
        list.add(ErrorCode.EmbedEmbedWatchdog)
        list.add(ErrorCode.EmbedEmbedInterruptNested)
        list.add(ErrorCode.EmbedEmbedStackOverflow)
        list.add(ErrorCode.EmbedEmbedHeapCorrupt)
        list.add(ErrorCode.EmbedEmbedPeripheralBusy)
        list.add(ErrorCode.EmbedEmbedDmaFailed)
        list.add(ErrorCode.EmbedEmbedClockMisconfig)
        list.add(ErrorCode.EmbedEmbedPinConflict)
        list.add(ErrorCode.EmbedEmbedNoSyscall)
        list.add(ErrorCode.EmbedCgoSymbolClash)
        list.add(ErrorCode.EmbedCgoTypeMismatch)
        list.add(ErrorCode.EmbedCgoCallbackNull)
        list.add(ErrorCode.EmbedCgoPanicCross)
        list.add(ErrorCode.EmbedCgoThreadLocal)
        list.add(ErrorCode.EmbedCgoAllocMismatch)
        list.add(ErrorCode.EmbedEmbedInterruptPriority)
        list.add(ErrorCode.EmbedEmbedBootFailed)
        list.add(ErrorCode.EmbedEmbedLinkerScript)
        list.add(ErrorCode.EmbedEmbedVectorTable)
        list.add(ErrorCode.EmbedEmbedNoAtomic)
        list.add(ErrorCode.EmbedEmbedWatchpoint)
        list.add(ErrorCode.EmbedEmbedPowerFail)
        list.add(ErrorCode.EmbedEmbedStackCanary)
        list.add(ErrorCode.EmbedEmbedMpuViolation)
        list.add(ErrorCode.EmbedEmbedCacheCoherency)
        list.add(ErrorCode.EmbedCgoCcNotFound)
        list.add(ErrorCode.EmbedCgoBuildFailed)
        list.add(ErrorCode.EmbedEmbedNoStdio)
        list.add(ErrorCode.EmbedEmbedTickFailed)
        list.add(ErrorCode.EmbedEmbedCriticalSection)
        list.add(ErrorCode.EmbedEmbedNoFpu)
        list.add(ErrorCode.EmbedCgoCallbackLifetime)
        list.add(ErrorCode.TestTestCompileFailed)
        list.add(ErrorCode.TestTestBinaryMissing)
        list.add(ErrorCode.TestTestTimeout)
        list.add(ErrorCode.TestTestPanic)
        list.add(ErrorCode.TestTestAssertFailed)
        list.add(ErrorCode.TestTestFixtureFailed)
        list.add(ErrorCode.TestTestTeardownFailed)
        list.add(ErrorCode.TestTestFilterNoMatch)
        list.add(ErrorCode.TestTestDuplicateName)
        list.add(ErrorCode.TestTestDependencyOrder)
        list.add(ErrorCode.TestTestResourceLeak)
        list.add(ErrorCode.TestTestIgnored)
        list.add(ErrorCode.TestTestShouldPanic)
        list.add(ErrorCode.TestTestUnexpectedPanic)
        list.add(ErrorCode.TestTestFlaky)
        list.add(ErrorCode.TestTestHarnessCrash)
        list.add(ErrorCode.TestTestStdoutCapture)
        list.add(ErrorCode.TestTestEnvMissing)
        list.add(ErrorCode.TestTestDataMissing)
        list.add(ErrorCode.TestTestMockFailed)
        list.add(ErrorCode.TestTestConcurrency)
        list.add(ErrorCode.TestTestDeadlock)
        list.add(ErrorCode.TestTestLeakSanitizer)
        list.add(ErrorCode.TestTestCoverageFailed)
        list.add(ErrorCode.TestTestReportFailed)
        list.add(ErrorCode.TestTestParallelConflict)
        list.add(ErrorCode.TestTestBeforeAllFailed)
        list.add(ErrorCode.TestTestAfterAllFailed)
        list.add(ErrorCode.TestTestSkipCondition)
        list.add(ErrorCode.TestTestParamMismatch)
        list.add(ErrorCode.TestTestTimeoutConfig)
        list.add(ErrorCode.TestTestBinaryCrash)
        list.add(ErrorCode.TestTestSignal)
        list.add(ErrorCode.TestTestMemoryLimit)
        list.add(ErrorCode.TestTestIsolation)
        list.add(ErrorCode.TestTestRandomSeed)
        list.add(ErrorCode.TestTestImportFailed)
        list.add(ErrorCode.TestTestUnknownAttr)
        list.add(ErrorCode.TestTestDoubleRun)
        list.add(ErrorCode.TestTestSummaryLost)
        list.add(ErrorCode.TestTestHang)
        list.add(ErrorCode.DocDocBrokenLink)
        list.add(ErrorCode.DocDocMissingItem)
        list.add(ErrorCode.DocDocCodeBlockFailed)
        list.add(ErrorCode.DocDocTestFailed)
        list.add(ErrorCode.DocDocExamplePanic)
        list.add(ErrorCode.DocDocCompileFailed)
        list.add(ErrorCode.DocDocMalformedAttr)
        list.add(ErrorCode.DocDocCyclicModule)
        list.add(ErrorCode.DocDocPrivateLeak)
        list.add(ErrorCode.DocDocHtmlEscape)
        list.add(ErrorCode.DocDocMissingSummary)
        list.add(ErrorCode.DocDocBrokenIntraLink)
        list.add(ErrorCode.DocDocAliasConflict)
        list.add(ErrorCode.DocDocSearchIndex)
        list.add(ErrorCode.DocDocThemeFailed)
        list.add(ErrorCode.DocDocAssetMissing)
        list.add(ErrorCode.DocDocCommentTooLong)
        list.add(ErrorCode.DocDocNonAsciiPath)
        list.add(ErrorCode.DocDocVersionMismatch)
        list.add(ErrorCode.DocDocExampleOutdated)
        list.add(ErrorCode.DocDocInvalidMarkdown)
        list.add(ErrorCode.DocDocTableBroken)
        list.add(ErrorCode.DocDocCodeLangUnknown)
        list.add(ErrorCode.DocDocRedirectLoop)
        list.add(ErrorCode.DocDocCrossCrate)
        list.add(ErrorCode.DocDocFeatureGate)
        list.add(ErrorCode.DocDocJsonFailed)
        list.add(ErrorCode.DocDocTestCompileTimeout)
        list.add(ErrorCode.DocDocHiddenItemRef)
        list.add(ErrorCode.DocDocDuplicateAnchor)
        list.add(ErrorCode.DocDocMacroDoc)
        list.add(ErrorCode.DocDocTraitImplMissing)
        list.add(ErrorCode.DocDocGenericParam)
        list.add(ErrorCode.DocDocCfgFiltered)
        list.add(ErrorCode.DocDocPlatformSpecific)
        list.add(ErrorCode.DocDocIncludeFailed)
        list.add(ErrorCode.DocDocEduLinkBroken)
        list.add(ErrorCode.LintLintUnusedVariable)
        list.add(ErrorCode.LintLintUnusedImport)
        list.add(ErrorCode.LintLintUnusedFunction)
        list.add(ErrorCode.LintLintDeadCode)
        list.add(ErrorCode.LintLintDeprecatedUse)
        list.add(ErrorCode.LintLintNonSnakeCase)
        list.add(ErrorCode.LintLintNonCamelCase)
        list.add(ErrorCode.LintLintNonUpperCaseConst)
        list.add(ErrorCode.LintLintHardcodedPath)
        list.add(ErrorCode.LintLintMagicNumber)
        list.add(ErrorCode.LintLintTodoLeft)
        list.add(ErrorCode.LintLintPrintStatement)
        list.add(ErrorCode.LintLintUnsafeBlock)
        list.add(ErrorCode.LintLintCloneInLoop)
        list.add(ErrorCode.LintLintComplexity)
        list.add(ErrorCode.LintLintTooManyArgs)
        list.add(ErrorCode.LintLintDeepNesting)
        list.add(ErrorCode.LintLintLineTooLong)
        list.add(ErrorCode.LintLintDocMissing)
        list.add(ErrorCode.LintLintCopyInsteadRef)
        list.add(ErrorCode.LintLintWildcardImport)
        list.add(ErrorCode.LintLintUnreachablePattern)
        list.add(ErrorCode.LintLintNonExhaustiveLet)
        list.add(ErrorCode.LintLintRedundantClone)
        list.add(ErrorCode.LintLintShadowing)
        list.add(ErrorCode.LintLintMutableNotNeeded)
        list.add(ErrorCode.LintLintUnnecessaryMut)
        list.add(ErrorCode.LintLintInefficientToStr)
        list.add(ErrorCode.LintLintPanicInProd)
        list.add(ErrorCode.LintLintFloatEquality)
        list.add(ErrorCode.LintLintUnwrapUsed)
        list.add(ErrorCode.LintLintExpectUsed)
        list.add(ErrorCode.LintLintIndexUnchecked)
        list.add(ErrorCode.LintLintIteratorValue)
        list.add(ErrorCode.LintLintLargeEnumVariant)
        list.add(ErrorCode.LintLintDerefClone)
        list.add(ErrorCode.LintLintRedundantField)
        list.add(ErrorCode.LintLintNonIdiomatic)
        list.add(ErrorCode.LintLintStyleViolation)
        list.add(ErrorCode.LintLintUnsafeSuggest)
        list.add(ErrorCode.LintLintPossibleBug)
        list.add(ErrorCode.SecSecHardcodedSecret)
        list.add(ErrorCode.SecSecSqlInjection)
        list.add(ErrorCode.SecSecCommandInjection)
        list.add(ErrorCode.SecSecPathTraversal)
        list.add(ErrorCode.SecSecUnsafeDeserialize)
        list.add(ErrorCode.SecSecWeakCrypto)
        list.add(ErrorCode.SecSecInsecureRandom)
        list.add(ErrorCode.SecSecTlsVerificationOff)
        list.add(ErrorCode.SecSecCleartextTransport)
        list.add(ErrorCode.SecSecUnsafeEval)
        list.add(ErrorCode.SecSecBufferOverflowRisk)
        list.add(ErrorCode.SecSecFormatString)
        list.add(ErrorCode.SecSecIntegerOverflow)
        list.add(ErrorCode.SecSecRaceCondition)
        list.add(ErrorCode.SecSecUseAfterFreeRisk)
        list.add(ErrorCode.SecSecDoubleFreeRisk)
        list.add(ErrorCode.SecSecNullDerefRisk)
        list.add(ErrorCode.SecSecSensitiveLog)
        list.add(ErrorCode.SecSecInsecureTemp)
        list.add(ErrorCode.SecSecSymlinkAttack)
        list.add(ErrorCode.SecSecUnsafeCast)
        list.add(ErrorCode.SecSecMemoryDisclosure)
        list.add(ErrorCode.SecSecMissingAuthz)
        list.add(ErrorCode.SecSecMissingAuthn)
        list.add(ErrorCode.SecSecCsrfRisk)
        list.add(ErrorCode.SecSecXssRisk)
        list.add(ErrorCode.SecSecInsecureCookie)
        list.add(ErrorCode.SecSecOpenRedirect)
        list.add(ErrorCode.SecSecUnsafeReflection)
        list.add(ErrorCode.SecSecDependencyVuln)
        list.add(ErrorCode.SecSecUnsafePermission)
        list.add(ErrorCode.SecSecKeySizeSmall)
        list.add(ErrorCode.SecSecHashWeak)
        list.add(ErrorCode.SecSecCipherModeWeak)
        list.add(ErrorCode.SecSecNonceReuse)
        list.add(ErrorCode.SecSecCertExpired)
        list.add(ErrorCode.SecSecInsecureProto)
        list.add(ErrorCode.SecSecPrivilegeDrop)
        list.add(ErrorCode.SecSecInfoLeak)
        list.add(ErrorCode.ConfConfigFileNotFound)
        list.add(ErrorCode.ConfConfigParseFailed)
        list.add(ErrorCode.ConfConfigSchemaInvalid)
        list.add(ErrorCode.ConfConfigKeyUnknown)
        list.add(ErrorCode.ConfConfigTypeMismatch)
        list.add(ErrorCode.ConfConfigMissingRequired)
        list.add(ErrorCode.ConfConfigDeprecated)
        list.add(ErrorCode.ConfConfigConflict)
        list.add(ErrorCode.ConfConfigEnvOverride)
        list.add(ErrorCode.ConfConfigProfileUnknown)
        list.add(ErrorCode.ConfConfigIncludeFailed)
        list.add(ErrorCode.ConfConfigCycle)
        list.add(ErrorCode.ConfConfigPermission)
        list.add(ErrorCode.ConfConfigEncoding)
        list.add(ErrorCode.ConfConfigTooLarge)
        list.add(ErrorCode.ConfConfigValidationFailed)
        list.add(ErrorCode.ConfConfigDefaultInvalid)
        list.add(ErrorCode.ConfConfigRangeViolation)
        list.add(ErrorCode.ConfConfigEnumInvalid)
        list.add(ErrorCode.ConfConfigPathInvalid)
        list.add(ErrorCode.ConfConfigUrlInvalid)
        list.add(ErrorCode.ConfConfigTimeoutInvalid)
        list.add(ErrorCode.ConfConfigFeatureConflict)
        list.add(ErrorCode.ConfConfigTargetMismatch)
        list.add(ErrorCode.ConfConfigRuntimeMismatch)
        list.add(ErrorCode.ConfConfigHotReloadFailed)
        list.add(ErrorCode.ConfConfigSecretLeak)
        list.add(ErrorCode.ConfConfigFormatUnknown)
        list.add(ErrorCode.ConfConfigMergeConflict)
        list.add(ErrorCode.ConfConfigVersionMismatch)
        list.add(ErrorCode.ConfConfigUnsafeValue)
        list.add(ErrorCode.ConfConfigRedundant)
        list.add(ErrorCode.ConfConfigDocMissing)
        list.add(ErrorCode.ConfConfigTypeCoercion)
        list.add(ErrorCode.ConfConfigPlaceholder)
        list.add(ErrorCode.ConfConfigConditional)
        list.add(ErrorCode.ConfConfigLocked)
        list.add(ErrorCode.ConfConfigEnvMissing)
        list.add(ErrorCode.ConfConfigInvalidBool)
        list.add(ErrorCode.ConfConfigListEmpty)
        list.add(ErrorCode.TelemTelemDisabled)
        list.add(ErrorCode.TelemTelemInitFailed)
        list.add(ErrorCode.TelemTelemExportFailed)
        list.add(ErrorCode.TelemTelemQueueFull)
        list.add(ErrorCode.TelemTelemTimeout)
        list.add(ErrorCode.TelemTelemUnauthorized)
        list.add(ErrorCode.TelemTelemEndpointUnreachable)
        list.add(ErrorCode.TelemTelemSchemaInvalid)
        list.add(ErrorCode.TelemTelemDropSpans)
        list.add(ErrorCode.TelemTelemMissingContext)
        list.add(ErrorCode.TelemTelemCardinality)
        list.add(ErrorCode.TelemTelemPiiLeak)
        list.add(ErrorCode.TelemTelemDuplicate)
        list.add(ErrorCode.TelemTelemClockSkew)
        list.add(ErrorCode.TelemTelemBufferFlush)
        list.add(ErrorCode.TelemTelemOOM)
        list.add(ErrorCode.TelemTelemMisconfigured)
        list.add(ErrorCode.TelemTelemVersionMismatch)
        list.add(ErrorCode.TelemTelemSamplerInvalid)
        list.add(ErrorCode.TelemTelemAttrTooLong)
        list.add(ErrorCode.TelemTelemNameInvalid)
        list.add(ErrorCode.TelemTelemDropMetrics)
        list.add(ErrorCode.TelemTelemLogFailed)
        list.add(ErrorCode.TelemTelemCrashNoReport)
        list.add(ErrorCode.TelemTelemRateLimited)
        list.add(ErrorCode.TelemTelemSecretInAttr)
        list.add(ErrorCode.TelemTelemExportBlocked)
        list.add(ErrorCode.TelemTelemBackpressure)
        list.add(ErrorCode.TelemTelemSpanOrphan)
        list.add(ErrorCode.TelemTelemLateArrival)
        list.add(ErrorCode.TelemTelemStorageFull)
        list.add(ErrorCode.TelemTelemEncodingFailed)
        list.add(ErrorCode.TelemTelemBatchFailed)
        list.add(ErrorCode.TelemTelemNoCollector)
        list.add(ErrorCode.TelemTelemInconsistent)
        list.add(ErrorCode.TelemTelemDisabledFeature)
        list.add(ErrorCode.TelemTelemPrivacyPolicy)
        list.add(ErrorCode.TelemTelemAttrCountExceed)
        list.add(ErrorCode.XcompileXcompileToolchainMissing)
        list.add(ErrorCode.XcompileXcompileSysrootMissing)
        list.add(ErrorCode.XcompileXcompileLinkerMissing)
        list.add(ErrorCode.XcompileXcompileTargetLibMissing)
        list.add(ErrorCode.XcompileXcompileAbiMismatch)
        list.add(ErrorCode.XcompileXcompileSyscallDiff)
        list.add(ErrorCode.XcompileXcompileEndianDiff)
        list.add(ErrorCode.XcompileXcompilePointerWidth)
        list.add(ErrorCode.XcompileXcompileFpuDiff)
        list.add(ErrorCode.XcompileXcompileAtomicAbsent)
        list.add(ErrorCode.XcompileXcompileCrtMissing)
        list.add(ErrorCode.XcompileXcompileUnwindDiff)
        list.add(ErrorCode.XcompileXcompileEnvMismatch)
        list.add(ErrorCode.XcompileXcompileQemuMissing)
        list.add(ErrorCode.XcompileXcompileRunFailed)
        list.add(ErrorCode.XcompileXcompileHostDep)
        list.add(ErrorCode.XcompileXcompilePathSep)
        list.add(ErrorCode.XcompileXcompileDlopen)
        list.add(ErrorCode.XcompileXcompileTlsModel)
        list.add(ErrorCode.XcompileXcompileStackProbe)
        list.add(ErrorCode.XcompileXcompileCodeModel)
        list.add(ErrorCode.XcompileXcompileArchFeature)
        list.add(ErrorCode.XcompileXcompileLinkScript)
        list.add(ErrorCode.XcompileXcompileObjFormat)
        list.add(ErrorCode.XcompileXcompileDebugFormat)
        list.add(ErrorCode.XcompileXcompileVendorLib)
        list.add(ErrorCode.XcompileXcompileSyscallTable)
        list.add(ErrorCode.XcompileXcompileFloatAbi)
        list.add(ErrorCode.XcompileXcompileAlignDiff)
        list.add(ErrorCode.XcompileXcompileVaList)
        list.add(ErrorCode.XcompileXcompileTimeT)
        list.add(ErrorCode.XcompileXcompileWchar)
        list.add(ErrorCode.XcompileXcompileLongDouble)
        list.add(ErrorCode.XcompileXcompileUnwindLib)
        list.add(ErrorCode.XcompileXcompileSanitizer)
        list.add(ErrorCode.XcompileXcompileCoverage)
        list.add(ErrorCode.XcompileXcompileProfile)
        list.add(ErrorCode.XcompileXcompileEmulatorCrash)
        list.add(ErrorCode.XcompileXcompileTargetJson)
        list.add(ErrorCode.WasmWasmTargetUnsupported)
        list.add(ErrorCode.WasmWasmInvalidOpcode)
        list.add(ErrorCode.WasmWasmMemoryGrowFailed)
        list.add(ErrorCode.WasmWasmTableFull)
        list.add(ErrorCode.WasmWasmFuncIndexOob)
        list.add(ErrorCode.WasmWasmTypeMismatch)
        list.add(ErrorCode.WasmWasmImportMissing)
        list.add(ErrorCode.WasmWasmExportMissing)
        list.add(ErrorCode.WasmWasmStackOverflow)
        list.add(ErrorCode.WasmWasmUnreachable)
        list.add(ErrorCode.WasmWasmGasExceeded)
        list.add(ErrorCode.WasmWasmSyscallAbsent)
        list.add(ErrorCode.WasmWasmBindgenFailed)
        list.add(ErrorCode.WasmWasmAbiMismatch)
        list.add(ErrorCode.WasmWasmJsInterop)
        list.add(ErrorCode.WasmWasmNoThreads)
        list.add(ErrorCode.WasmWasmNoSimd)
        list.add(ErrorCode.WasmWasmNoException)
        list.add(ErrorCode.WasmWasmSharedMemory)
        list.add(ErrorCode.WasmWasmTailCall)
        list.add(ErrorCode.WasmWasmBulkMemory)
        list.add(ErrorCode.WasmWasmReferenceTypes)
        list.add(ErrorCode.WasmWasmMultiValue)
        list.add(ErrorCode.WasmWasmSignExtension)
        list.add(ErrorCode.WasmWasmSatFloat)
        list.add(ErrorCode.WasmWasmMutableGlobal)
        list.add(ErrorCode.WasmWasmExceptionEncoding)
        list.add(ErrorCode.WasmWasmImportTypeError)
        list.add(ErrorCode.WasmWasmStartFunc)
        list.add(ErrorCode.WasmWasmDataCount)
        list.add(ErrorCode.WasmWasmCustomSection)
        list.add(ErrorCode.WasmWasmNameSection)
        list.add(ErrorCode.WasmWasmLinkerFailed)
        list.add(ErrorCode.WasmWasmValidationFailed)
        list.add(ErrorCode.WasmWasmInstantiationFailed)
        list.add(ErrorCode.WasmWasmNoStd)
        list.add(ErrorCode.WasmWasmNoFilesystem)
        list.add(ErrorCode.WasmWasmNoNetwork)
        list.add(ErrorCode.WasmWasmSizeLimit)
        list.add(ErrorCode.GpuGpuTargetUnsupported)
        list.add(ErrorCode.GpuGpuKernelCompileFailed)
        list.add(ErrorCode.GpuGpuDeviceNotFound)
        list.add(ErrorCode.GpuGpuOutOfMemory)
        list.add(ErrorCode.GpuGpuIllegalAccess)
        list.add(ErrorCode.GpuGpuWarpDivergence)
        list.add(ErrorCode.GpuGpuSyncFailed)
        list.add(ErrorCode.GpuGpuTimeout)
        list.add(ErrorCode.GpuGpuInvalidDim)
        list.add(ErrorCode.GpuGpuSharedMemExceed)
        list.add(ErrorCode.GpuGpuNoDouble)
        list.add(ErrorCode.GpuGpuUnifiedMemory)
        list.add(ErrorCode.GpuGpuDriverMismatch)
        list.add(ErrorCode.GpuGpuContextLost)
        list.add(ErrorCode.GpuGpuStreamFailed)
        list.add(ErrorCode.GpuGpuEventFailed)
        list.add(ErrorCode.GpuGpuCopyFailed)
        list.add(ErrorCode.GpuGpuKernelArg)
        list.add(ErrorCode.GpuGpuOccupancyLow)
        list.add(ErrorCode.GpuGpuRegisterSpill)
        list.add(ErrorCode.GpuGpuBankConflict)
        list.add(ErrorCode.GpuGpuAtomicUnsupported)
        list.add(ErrorCode.GpuGpuCooperativeGroup)
        list.add(ErrorCode.GpuGpuTensorCore)
        list.add(ErrorCode.GpuGpuGraphFailed)
        list.add(ErrorCode.GpuGpuMpsUnavailable)
        list.add(ErrorCode.GpuGpuMultiDevice)
        list.add(ErrorCode.GpuGpuPeerAccess)
        list.add(ErrorCode.GpuGpuProfilerFailed)
        list.add(ErrorCode.GpuGpuDebugUnsupported)
        list.add(ErrorCode.GpuGpuPrintfFailed)
        list.add(ErrorCode.GpuGpuAssertFailed)
        list.add(ErrorCode.GpuGpuUnsupportedType)
        list.add(ErrorCode.GpuGpuLaunchFailed)
        list.add(ErrorCode.GpuGpuNoHostCode)
        list.add(ErrorCode.GpuGpuLinkFailed)
        list.add(ErrorCode.GpuGpuFatbinMissing)
        list.add(ErrorCode.GpuGpuArchMismatch)
        list.add(ErrorCode.GpuGpuResourceLeak)
        return list
    }


    /// 错误码字符串（如 "E2001"）
    public func code(): String {
        match (this) {
            case ErrorCode.MacroUndefinedIdentifier => "E0201"
            case ErrorCode.MacroArityMismatch => "E0202"
            case ErrorCode.MacroRecursiveExpansion => "E0203"
            case ErrorCode.MacroHygieneViolation => "E0204"
            case ErrorCode.MacroInvalidTokenTree => "E0205"
            case ErrorCode.MacroMissingMacroDef => "E0206"
            case ErrorCode.MacroDuplicateMacroDef => "E0207"
            case ErrorCode.MacroWrongFragmentKind => "E0208"
            case ErrorCode.MacroMetavarReuse => "E0209"
            case ErrorCode.MacroNoMatchingRule => "E0210"
            case ErrorCode.MacroReservedName => "E0211"
            case ErrorCode.MacroContextualKeyword => "E0212"
            case ErrorCode.MacroExpansionDepthLimit => "E0213"
            case ErrorCode.MacroMalformedAttribute => "E0214"
            case ErrorCode.MacroDeriveConflict => "E0215"
            case ErrorCode.MacroProcMacroPanic => "E0216"
            case ErrorCode.MacroProcMacroTimeout => "E0217"
            case ErrorCode.MacroProcMacroIOError => "E0218"
            case ErrorCode.MacroQuoteSpanLost => "E0219"
            case ErrorCode.MacroRuleAmbiguity => "E0220"
            case ErrorCode.MacroEmptyRepetition => "E0221"
            case ErrorCode.MacroSeparatorMismatch => "E0222"
            case ErrorCode.MacroTTNotBalance => "E0223"
            case ErrorCode.MacroUnresolvedFragment => "E0224"
            case ErrorCode.MacroBuiltinMacroUnsupported => "E0225"
            case ErrorCode.MacroMacroInConst => "E0226"
            case ErrorCode.MacroCfgMacroBranch => "E0227"
            case ErrorCode.MacroDocMacroBroken => "E0228"
            case ErrorCode.MacroFormatMacroParse => "E0229"
            case ErrorCode.MacroLogMacroLevel => "E0230"
            case ErrorCode.MacroAssertMacroMsg => "E0231"
            case ErrorCode.MacroVecMacroNonUniform => "E0232"
            case ErrorCode.MacroIncludeMacroFail => "E0233"
            case ErrorCode.MacroConcatMacroType => "E0234"
            case ErrorCode.MacroEnvMacroMissing => "E0235"
            case ErrorCode.MacroSelectMacroConflict => "E0236"
            case ErrorCode.MacroMacroDefRecursion => "E0237"
            case ErrorCode.MacroGenericMacroParam => "E0238"
            case ErrorCode.MacroUnsafeMacroExpansion => "E0239"
            case ErrorCode.MacroMacroSpanOverflow => "E0240"
            case ErrorCode.TraitMethodNotImplemented => "E0301"
            case ErrorCode.TraitMethodSignatureMismatch => "E0302"
            case ErrorCode.TraitMissingSupertrait => "E0303"
            case ErrorCode.TraitConflictingImpl => "E0304"
            case ErrorCode.TraitOrphanRuleViolation => "E0305"
            case ErrorCode.TraitNegativeImplConflict => "E0306"
            case ErrorCode.TraitSealedTraitLeak => "E0307"
            case ErrorCode.TraitAssociatedTypeMissing => "E0308"
            case ErrorCode.TraitAssociatedTypeBound => "E0309"
            case ErrorCode.TraitDefaultImplConflict => "E0310"
            case ErrorCode.TraitMarkerTraitMisuse => "E0311"
            case ErrorCode.TraitDynTraitNotObjectSafe => "E0312"
            case ErrorCode.TraitDynTraitGeneric => "E0313"
            case ErrorCode.TraitTraitBoundUnmet => "E0314"
            case ErrorCode.TraitHigherRankedBound => "E0315"
            case ErrorCode.TraitTraitAliasCycle => "E0316"
            case ErrorCode.TraitImplForBoundParam => "E0317"
            case ErrorCode.TraitSpecializationFailure => "E0318"
            case ErrorCode.TraitAutoTraitNotImpl => "E0319"
            case ErrorCode.TraitAutoTraitConflict => "E0320"
            case ErrorCode.TraitCoordTraitAmbig => "E0321"
            case ErrorCode.TraitUnsafeTraitImpl => "E0322"
            case ErrorCode.TraitTraitMethodVisibility => "E0323"
            case ErrorCode.TraitWhereClauseOnImpl => "E0324"
            case ErrorCode.TraitBlanketImplConflict => "E0325"
            case ErrorCode.TraitTraitObjectCovariance => "E0326"
            case ErrorCode.TraitAssocTypeProjection => "E0327"
            case ErrorCode.TraitTraitMethodDefaultParam => "E0328"
            case ErrorCode.TraitAsyncTraitNotSupported => "E0329"
            case ErrorCode.TraitTraitMethodGenericClash => "E0330"
            case ErrorCode.TraitDuplicateAssocConst => "E0331"
            case ErrorCode.TraitAssocConstType => "E0332"
            case ErrorCode.TraitTraitMethodByName => "E0333"
            case ErrorCode.TraitImplGenericCount => "E0334"
            case ErrorCode.TraitTraitRequirementCycle => "E0335"
            case ErrorCode.TraitDispatchResolution => "E0336"
            case ErrorCode.TraitTraitMethodOverride => "E0337"
            case ErrorCode.TraitLateBoundParam => "E0338"
            case ErrorCode.TraitTraitInheritanceDepth => "E0339"
            case ErrorCode.TraitSelfImplConflict => "E0340"
            case ErrorCode.BorrowMoveOutOfBorrowed => "E0401"
            case ErrorCode.BorrowBorrowAfterMove => "E0402"
            case ErrorCode.BorrowMutableBorrowConflict => "E0403"
            case ErrorCode.BorrowAliasingMutableBorrow => "E0404"
            case ErrorCode.BorrowBorrowEscapesScope => "E0405"
            case ErrorCode.BorrowUseOfMovedValue => "E0406"
            case ErrorCode.BorrowPartialMoveStruct => "E0407"
            case ErrorCode.BorrowMoveInMatchGuard => "E0408"
            case ErrorCode.BorrowClosureCaptureByMove => "E0409"
            case ErrorCode.BorrowReturnReferenceToLocal => "E0410"
            case ErrorCode.BorrowTemporaryLifetime => "E0411"
            case ErrorCode.BorrowBorrowOfMovedField => "E0412"
            case ErrorCode.BorrowSelfBorrowInMethod => "E0413"
            case ErrorCode.BorrowReborrowFailed => "E0414"
            case ErrorCode.BorrowCopyTraitMissing => "E0415"
            case ErrorCode.BorrowDropDuringBorrow => "E0416"
            case ErrorCode.BorrowBorrowInMatchArm => "E0417"
            case ErrorCode.BorrowDoubleMutableBorrow => "E0418"
            case ErrorCode.BorrowImmutableToMutable => "E0419"
            case ErrorCode.BorrowBorrowInClosureArg => "E0420"
            case ErrorCode.BorrowUnsafeBypassBorrow => "E0421"
            case ErrorCode.BorrowPhantomBorrow => "E0422"
            case ErrorCode.BorrowBorrowInLoop => "E0423"
            case ErrorCode.BorrowFieldBorrowEscape => "E0424"
            case ErrorCode.BorrowGenericBorrowBound => "E0425"
            case ErrorCode.BorrowMoveAcrossAwait => "E0426"
            case ErrorCode.BorrowBorrowOfDropType => "E0427"
            case ErrorCode.BorrowReturnBorrowedParam => "E0428"
            case ErrorCode.BorrowSelfReferential => "E0429"
            case ErrorCode.BorrowAsyncMoveCapture => "E0430"
            case ErrorCode.BorrowBorrowInMatchGuard2 => "E0431"
            case ErrorCode.BorrowStaticBorrowViolation => "E0432"
            case ErrorCode.BorrowInteriorMutRace => "E0433"
            case ErrorCode.BorrowBorrowOfUnsized => "E0434"
            case ErrorCode.BorrowScopedBorrowEnd => "E0435"
            case ErrorCode.BorrowMoveInClosure => "E0436"
            case ErrorCode.BorrowBorrowInMatchGuard3 => "E0437"
            case ErrorCode.BorrowTemporaryBorrowDrop => "E0438"
            case ErrorCode.BorrowTraitObjectBorrow => "E0439"
            case ErrorCode.BorrowCoerceBorrowMismatch => "E0440"
            case ErrorCode.LifetimeUnboundedLifetime => "E0501"
            case ErrorCode.LifetimeLifetimeMismatch => "E0502"
            case ErrorCode.LifetimeMissingLifetime => "E0503"
            case ErrorCode.LifetimeAnonymousLifetimeConflict => "E0504"
            case ErrorCode.LifetimeStaticRequirements => "E0505"
            case ErrorCode.LifetimeLifetimeInTypeAlias => "E0506"
            case ErrorCode.LifetimeVarianceViolation => "E0507"
            case ErrorCode.LifetimeHigherRankedLifetime => "E0508"
            case ErrorCode.LifetimeLifetimeElisionFail => "E0509"
            case ErrorCode.LifetimeStructFieldLifetime => "E0510"
            case ErrorCode.LifetimeBorrowLifetimeShort => "E0511"
            case ErrorCode.LifetimeOutlivesFailure => "E0512"
            case ErrorCode.LifetimePhantomLifetime => "E0513"
            case ErrorCode.LifetimeAsyncLifetimeCapture => "E0514"
            case ErrorCode.LifetimeClosureLifetimeCapture => "E0515"
            case ErrorCode.LifetimeIteratorLifetime => "E0516"
            case ErrorCode.LifetimeTraitObjectLifetime => "E0517"
            case ErrorCode.LifetimeReturnRefLifetime => "E0518"
            case ErrorCode.LifetimeSelfLifetime => "E0519"
            case ErrorCode.LifetimeGenericLifetimeBound => "E0520"
            case ErrorCode.LifetimeCovariantReturnLifetime => "E0521"
            case ErrorCode.LifetimeLifetimeInImplTrait => "E0522"
            case ErrorCode.LifetimeNestedLifetime => "E0523"
            case ErrorCode.LifetimeStaticRefCapture => "E0524"
            case ErrorCode.LifetimeDropLifetime => "E0525"
            case ErrorCode.LifetimeLifetimeSubtyping => "E0526"
            case ErrorCode.LifetimeEarlyBoundLateBound => "E0527"
            case ErrorCode.LifetimeLifetimeInConst => "E0528"
            case ErrorCode.LifetimeYieldLifetime => "E0529"
            case ErrorCode.LifetimeBorrowSplitLifetime => "E0530"
            case ErrorCode.LifetimeFunctionPointerLifetime => "E0531"
            case ErrorCode.LifetimeArrayLifetime => "E0532"
            case ErrorCode.LifetimeUnionLifetime => "E0533"
            case ErrorCode.LifetimeTraitMethodLifetime => "E0534"
            case ErrorCode.LifetimeLifetimeNameConflict => "E0535"
            case ErrorCode.LifetimeRAIILifetime => "E0536"
            case ErrorCode.LifetimeGenericAssocLifetime => "E0537"
            case ErrorCode.LifetimeReferenceToTempLifetime => "E0538"
            case ErrorCode.LifetimeLifetimeOnTrait => "E0539"
            case ErrorCode.GenericArgumentCountMismatch => "E0601"
            case ErrorCode.GenericTypeArgumentInference => "E0602"
            case ErrorCode.GenericConstraintViolation => "E0603"
            case ErrorCode.GenericMissingTraitBound => "E0604"
            case ErrorCode.GenericRecursiveAlias => "E0605"
            case ErrorCode.GenericMonomorphizationFailed => "E0606"
            case ErrorCode.GenericCodeBloatLimit => "E0607"
            case ErrorCode.GenericHigherRankedBound => "E0608"
            case ErrorCode.GenericDefaultArgumentMissing => "E0609"
            case ErrorCode.GenericDefaultArgumentConflict => "E0610"
            case ErrorCode.GenericVarianceMismatch => "E0611"
            case ErrorCode.GenericUnsizedGeneric => "E0612"
            case ErrorCode.GenericAssociatedTypeUnbound => "E0613"
            case ErrorCode.GenericGATNotSupported => "E0614"
            case ErrorCode.GenericConstGenericMismatch => "E0615"
            case ErrorCode.GenericConstGenericNonConst => "E0616"
            case ErrorCode.GenericConstGenericOverflow => "E0617"
            case ErrorCode.GenericTraitObjectGeneric => "E0618"
            case ErrorCode.GenericImplGenericConflict => "E0619"
            case ErrorCode.GenericBlanketImplConflict => "E0620"
            case ErrorCode.GenericGenericMethodResolution => "E0621"
            case ErrorCode.GenericTypeParamShadow => "E0622"
            case ErrorCode.GenericGenericInEnum => "E0623"
            case ErrorCode.GenericGenericFunctionPointer => "E0624"
            case ErrorCode.GenericSpecializationFailed => "E0625"
            case ErrorCode.GenericPhantomTypeMismatch => "E0626"
            case ErrorCode.GenericWhereClauseUnmet => "E0627"
            case ErrorCode.GenericTypeParamCountInImpl => "E0628"
            case ErrorCode.GenericGenericAliasCycle => "E0629"
            case ErrorCode.GenericNegativeImplAmbig => "E0630"
            case ErrorCode.GenericGenericStructField => "E0631"
            case ErrorCode.GenericHigherRankedInType => "E0632"
            case ErrorCode.GenericGenericTraitBound => "E0633"
            case ErrorCode.GenericExistentialGeneric => "E0634"
            case ErrorCode.GenericGenericDefaultCycle => "E0635"
            case ErrorCode.GenericUnsoundGeneric => "E0636"
            case ErrorCode.GenericGenericCoherence => "E0637"
            case ErrorCode.GenericTupleGenericMismatch => "E0638"
            case ErrorCode.GenericArrayGenericLen => "E0639"
            case ErrorCode.GenericImplTraitPosition => "E0640"
            case ErrorCode.GenericGenericInlineCycle => "E0641"
            case ErrorCode.ModuleModuleNotFound => "E0701"
            case ErrorCode.ModuleFileNotFound => "E0702"
            case ErrorCode.ModuleCyclicModule => "E0703"
            case ErrorCode.ModuleDuplicateModule => "E0704"
            case ErrorCode.ModuleVisibilityViolation => "E0705"
            case ErrorCode.ModuleReexportConflict => "E0706"
            case ErrorCode.ModuleGlobConflict => "E0707"
            case ErrorCode.ModuleWrongModuleTree => "E0708"
            case ErrorCode.ModuleAnonymousModule => "E0709"
            case ErrorCode.ModuleModuleNameConflict => "E0710"
            case ErrorCode.ModuleNestedModuleDepth => "E0711"
            case ErrorCode.ModuleMacroUseScope => "E0712"
            case ErrorCode.ModulePathResolution => "E0713"
            case ErrorCode.ModuleSuperOutside => "E0714"
            case ErrorCode.ModuleCrateRootMissing => "E0715"
            case ErrorCode.ModuleInlineModuleConflict => "E0716"
            case ErrorCode.ModuleExternalCrateNotFound => "E0717"
            case ErrorCode.ModuleExternalCrateVersion => "E0718"
            case ErrorCode.ModuleFeatureGateModule => "E0719"
            case ErrorCode.ModulePrivateModuleLeak => "E0720"
            case ErrorCode.ModuleModuleInitOrder => "E0721"
            case ErrorCode.ModuleCfgModuleDisabled => "E0722"
            case ErrorCode.ModuleAmbiguousPath => "E0723"
            case ErrorCode.ModuleUseAsConflict => "E0724"
            case ErrorCode.ModuleTraitInModule => "E0725"
            case ErrorCode.ModuleStructInModule => "E0726"
            case ErrorCode.ModuleEnumVariantPath => "E0727"
            case ErrorCode.ModuleModuleDocConflict => "E0728"
            case ErrorCode.ModuleUnsafeModuleExport => "E0729"
            case ErrorCode.ModuleGenericModuleParam => "E0730"
            case ErrorCode.ModulePlatformModule => "E0731"
            case ErrorCode.ModuleTestModuleLeak => "E0732"
            case ErrorCode.ModuleBenchModule => "E0733"
            case ErrorCode.ModuleMacroModuleSep => "E0734"
            case ErrorCode.ModuleModuleCyclicReexport => "E0735"
            case ErrorCode.ModuleHiddenModule => "E0736"
            case ErrorCode.ModuleModuleAttrConflict => "E0737"
            case ErrorCode.ModuleNamespaceConflict => "E0738"
            case ErrorCode.ModuleInlineInFile => "E0739"
            case ErrorCode.ModuleEmptyModule => "E0740"
            case ErrorCode.BackendLlvmVerifyFailed => "E1101"
            case ErrorCode.BackendLlvmLoweringFailed => "E1102"
            case ErrorCode.BackendLlvmOptCrash => "E1103"
            case ErrorCode.BackendLlvmUnsupported => "E1104"
            case ErrorCode.BackendIrInvalid => "E1105"
            case ErrorCode.BackendIrTypeMismatch => "E1106"
            case ErrorCode.BackendIrMissingDef => "E1107"
            case ErrorCode.BackendIrUnreachable => "E1108"
            case ErrorCode.BackendRegisterAllocFailed => "E1109"
            case ErrorCode.BackendStackFrameTooLarge => "E1110"
            case ErrorCode.BackendCodeLayoutFailed => "E1111"
            case ErrorCode.BackendSectionEmitFailed => "E1112"
            case ErrorCode.BackendRelocationUnsupported => "E1113"
            case ErrorCode.BackendTargetFeatureAbsent => "E1114"
            case ErrorCode.BackendCallingConvUnknown => "E1115"
            case ErrorCode.BackendDebugInfoLost => "E1116"
            case ErrorCode.BackendEhTableTooLarge => "E1117"
            case ErrorCode.BackendGlobalInitFailed => "E1118"
            case ErrorCode.BackendConstantFoldBackend => "E1119"
            case ErrorCode.BackendAsmEmitFailed => "E1120"
            case ErrorCode.BackendVectorBackend => "E1121"
            case ErrorCode.BackendTailCallUnsupported => "E1122"
            case ErrorCode.BackendInlineAsmConstraint => "E1123"
            case ErrorCode.BackendMetadataEmit => "E1124"
            case ErrorCode.BackendModuleParse => "E1125"
            case ErrorCode.BackendTargetMachineInit => "E1126"
            case ErrorCode.BackendDataLayoutMismatch => "E1127"
            case ErrorCode.BackendABILowering => "E1128"
            case ErrorCode.BackendUnwindInfoFailed => "E1129"
            case ErrorCode.BackendProfileInstrument => "E1130"
            case ErrorCode.BackendSanitizerUnsupported => "E1131"
            case ErrorCode.BackendThinLtoFailed => "E1132"
            case ErrorCode.BackendLtoModuleConflict => "E1133"
            case ErrorCode.BackendBackendTimeout => "E1134"
            case ErrorCode.BackendBackendOOM => "E1135"
            case ErrorCode.BackendVerifierLimit => "E1136"
            case ErrorCode.BackendIntrinsicLowering => "E1137"
            case ErrorCode.BackendBlockAddressInvalid => "E1138"
            case ErrorCode.BackendComdatFailed => "E1139"
            case ErrorCode.BackendAliasEmitFailed => "E1140"
            case ErrorCode.BackendWeakSymbolConflict => "E1141"
            case ErrorCode.OptPassFailed => "E1201"
            case ErrorCode.OptPassCrashed => "E1202"
            case ErrorCode.OptInvalidation => "E1203"
            case ErrorCode.OptLoopUnrollFailed => "E1204"
            case ErrorCode.OptVectorizationFailed => "E1205"
            case ErrorCode.OptInliningFailed => "E1206"
            case ErrorCode.OptInliningTooDeep => "E1207"
            case ErrorCode.OptDeadCodeNotRemoved => "E1208"
            case ErrorCode.OptConstPropOverflow => "E1209"
            case ErrorCode.OptGvnConflict => "E1210"
            case ErrorCode.OptSccpFailed => "E1211"
            case ErrorCode.OptMem2RegFailed => "E1212"
            case ErrorCode.OptLoopInvariantFailed => "E1213"
            case ErrorCode.OptTailDuplicateFailed => "E1214"
            case ErrorCode.OptPeepholeFailed => "E1215"
            case ErrorCode.OptStrengthReduction => "E1216"
            case ErrorCode.OptAliasAnalysisFailed => "E1217"
            case ErrorCode.OptOptLevelInvalid => "E1218"
            case ErrorCode.OptOptSizeConflict => "E1219"
            case ErrorCode.OptProfileMismatch => "E1220"
            case ErrorCode.OptOptCorruptIr => "E1221"
            case ErrorCode.OptLoopRotateFailed => "E1222"
            case ErrorCode.OptGlobalOptFailed => "E1223"
            case ErrorCode.OptIpConstantProp => "E1224"
            case ErrorCode.OptArgumentPromotion => "E1225"
            case ErrorCode.OptStructRetOpt => "E1226"
            case ErrorCode.OptTailCallOptFailed => "E1227"
            case ErrorCode.OptSLPVectorizeFailed => "E1228"
            case ErrorCode.OptLoopVersioning => "E1229"
            case ErrorCode.OptPartialInline => "E1230"
            case ErrorCode.OptHotColdSplit => "E1231"
            case ErrorCode.OptMergeFuncFailed => "E1232"
            case ErrorCode.OptGVNLoadElim => "E1233"
            case ErrorCode.OptOptzLoopUnswitch => "E1234"
            case ErrorCode.OptReassociateFailed => "E1235"
            case ErrorCode.OptOptLoopIdiom => "E1236"
            case ErrorCode.OptCFGSimplifyFailed => "E1237"
            case ErrorCode.OptOptIndVar => "E1238"
            case ErrorCode.OptDivRemOpt => "E1239"
            case ErrorCode.OptOptShiftBase => "E1240"
            case ErrorCode.OptOptFloatReassoc => "E1241"
            case ErrorCode.LinkerLinkerNotFound => "E1301"
            case ErrorCode.LinkerLinkerInvocation => "E1302"
            case ErrorCode.LinkerUndefinedSymbol => "E1303"
            case ErrorCode.LinkerDuplicateSymbol => "E1304"
            case ErrorCode.LinkerLibraryNotFound => "E1305"
            case ErrorCode.LinkerLibraryVersion => "E1306"
            case ErrorCode.LinkerMissingEntryPoint => "E1307"
            case ErrorCode.LinkerRelocOverflow => "E1308"
            case ErrorCode.LinkerArchMismatch => "E1309"
            case ErrorCode.LinkerAbiMismatch => "E1310"
            case ErrorCode.LinkerLinkScriptError => "E1311"
            case ErrorCode.LinkerStaticDynamicConflict => "E1312"
            case ErrorCode.LinkerStdLibLinkFailed => "E1313"
            case ErrorCode.LinkerRuntimeLibMissing => "E1314"
            case ErrorCode.LinkerLinkerOOM => "E1315"
            case ErrorCode.LinkerLinkerTimeout => "E1316"
            case ErrorCode.LinkerThreadLocalLink => "E1317"
            case ErrorCode.LinkerWeakSymbolUnresolved => "E1318"
            case ErrorCode.LinkerExportSymbolMissing => "E1319"
            case ErrorCode.LinkerImportLibraryMissing => "E1320"
            case ErrorCode.LinkerCOMDATConflict => "E1321"
            case ErrorCode.LinkerLinkOrderError => "E1322"
            case ErrorCode.LinkerBitcodeLinkFailed => "E1323"
            case ErrorCode.LinkerLTOFailed => "E1324"
            case ErrorCode.LinkerLinkerScriptUnknown => "E1325"
            case ErrorCode.LinkerDynamicLibMissing => "E1326"
            case ErrorCode.LinkerRpathInvalid => "E1327"
            case ErrorCode.LinkerSymbolVisibility => "E1328"
            case ErrorCode.LinkerLinkerLangMismatch => "E1329"
            case ErrorCode.LinkerGCSectionsFailed => "E1330"
            case ErrorCode.LinkerMmapLinkFailed => "E1331"
            case ErrorCode.LinkerLinkSanitizer => "E1332"
            case ErrorCode.LinkerDeadStripFailed => "E1333"
            case ErrorCode.LinkerLinkerPluginError => "E1334"
            case ErrorCode.LinkerCrtFileMissing => "E1335"
            case ErrorCode.LinkerLinkerVersionOld => "E1336"
            case ErrorCode.LinkerMangledNameConflict => "E1337"
            case ErrorCode.LinkerPieUnsupported => "E1338"
            case ErrorCode.LinkerLinkerStackSize => "E1339"
            case ErrorCode.LinkerUnwindLibMissing => "E1340"
            case ErrorCode.AbiFfiSignatureMismatch => "E1401"
            case ErrorCode.AbiFfiTypeUnsupported => "E1402"
            case ErrorCode.AbiCAbiMismatch => "E1403"
            case ErrorCode.AbiStructLayoutMismatch => "E1404"
            case ErrorCode.AbiEnumReprMismatch => "E1405"
            case ErrorCode.AbiUnionLayout => "E1406"
            case ErrorCode.AbiCallbackAbiMismatch => "E1407"
            case ErrorCode.AbiVarargsUnsupported => "E1408"
            case ErrorCode.AbiFfiUnsafeCall => "E1409"
            case ErrorCode.AbiFfiLifetimeViolation => "E1410"
            case ErrorCode.AbiFfiPanicAcross => "E1411"
            case ErrorCode.AbiFfiAllocMismatch => "E1412"
            case ErrorCode.AbiFloatAbiMismatch => "E1413"
            case ErrorCode.AbiRegisterAbiMismatch => "E1414"
            case ErrorCode.AbiEndiannessMismatch => "E1415"
            case ErrorCode.AbiAlignAbiMismatch => "E1416"
            case ErrorCode.AbiNameMangling => "E1417"
            case ErrorCode.AbiFfiCharEncoding => "E1418"
            case ErrorCode.AbiFfiBoolSize => "E1419"
            case ErrorCode.AbiFfiEnumSize => "E1420"
            case ErrorCode.AbiFfiPointerNull => "E1421"
            case ErrorCode.AbiFfiWideChar => "E1422"
            case ErrorCode.AbiFfiLongSize => "E1423"
            case ErrorCode.AbiFfiStructPass => "E1424"
            case ErrorCode.AbiFfiUnwindAbi => "E1425"
            case ErrorCode.AbiFfiVectorAbi => "E1426"
            case ErrorCode.AbiFfiComplexType => "E1427"
            case ErrorCode.AbiFfiBitfield => "E1428"
            case ErrorCode.AbiFfiVaList => "E1429"
            case ErrorCode.AbiFfiThreadLocal => "E1430"
            case ErrorCode.AbiFfiCallingConvention => "E1431"
            case ErrorCode.AbiFfiNonPod => "E1432"
            case ErrorCode.AbiFfiDtorLeak => "E1433"
            case ErrorCode.AbiFfiCallbackLifetime => "E1434"
            case ErrorCode.AbiFfiResourceLeak => "E1435"
            case ErrorCode.AbiFfiSignalUnsafe => "E1436"
            case ErrorCode.AbiFfiLongjmp => "E1437"
            case ErrorCode.AbiFfiComdat => "E1438"
            case ErrorCode.AbiFfiTypeSize => "E1439"
            case ErrorCode.AbiFfiConstMismatch => "E1440"
            case ErrorCode.ConcurrencyThreadSpawnFailed => "E5101"
            case ErrorCode.ConcurrencyThreadLimitExceeded => "E5102"
            case ErrorCode.ConcurrencyDataRaceDetected => "E5103"
            case ErrorCode.ConcurrencyDeadlockDetected => "E5104"
            case ErrorCode.ConcurrencyLockPoisoned => "E5105"
            case ErrorCode.ConcurrencyCondVarSpurious => "E5106"
            case ErrorCode.ConcurrencyChannelClosed => "E5107"
            case ErrorCode.ConcurrencyChannelSendBlocked => "E5108"
            case ErrorCode.ConcurrencyChannelRecvEmpty => "E5109"
            case ErrorCode.ConcurrencyActorMailboxFull => "E5110"
            case ErrorCode.ConcurrencyActorStopped => "E5111"
            case ErrorCode.ConcurrencyFutureNotPolled => "E5112"
            case ErrorCode.ConcurrencyExecutorShutdown => "E5113"
            case ErrorCode.ConcurrencyAwaitOutsideAsync => "E5114"
            case ErrorCode.ConcurrencyAsyncRecursion => "E5115"
            case ErrorCode.ConcurrencyCoroutineSuspendInvalid => "E5116"
            case ErrorCode.ConcurrencyCoroutineLeak => "E5117"
            case ErrorCode.ConcurrencyAtomicMisuse => "E5118"
            case ErrorCode.ConcurrencyMemoryOrderInvalid => "E5119"
            case ErrorCode.ConcurrencyRwLockDeadlock => "E5120"
            case ErrorCode.ConcurrencyMutexDoubleLock => "E5121"
            case ErrorCode.ConcurrencyBarrierWait => "E5122"
            case ErrorCode.ConcurrencySemaphoreOverflow => "E5123"
            case ErrorCode.ConcurrencyOnceInitPanic => "E5124"
            case ErrorCode.ConcurrencyThreadLocalAccess => "E5125"
            case ErrorCode.ConcurrencyRaceOnInit => "E5126"
            case ErrorCode.ConcurrencyParkUnparkLost => "E5127"
            case ErrorCode.ConcurrencyTaskCanceled => "E5128"
            case ErrorCode.ConcurrencyAffinityFailed => "E5129"
            case ErrorCode.ConcurrencyStackSizeInvalid => "E5130"
            case ErrorCode.ConcurrencyAsyncDropCycle => "E5131"
            case ErrorCode.ConcurrencyExecutorStarvation => "E5132"
            case ErrorCode.ConcurrencySelectArmConflict => "E5133"
            case ErrorCode.ConcurrencyChannelCapacityZero => "E5134"
            case ErrorCode.ConcurrencyLockOrderInversion => "E5135"
            case ErrorCode.ConcurrencyNonSendCaptured => "E5136"
            case ErrorCode.ConcurrencyNonSyncShared => "E5137"
            case ErrorCode.ConcurrencyWatchdogTimeout => "E5138"
            case ErrorCode.ConcurrencyCpuAffinityUnsupported => "E5139"
            case ErrorCode.ConcurrencyCoroutineStackExhaust => "E5140"
            case ErrorCode.ConcurrencyWorkStealFailed => "E5141"
            case ErrorCode.MemOutOfMemory => "E5201"
            case ErrorCode.MemDoubleFree => "E5202"
            case ErrorCode.MemUseAfterFree => "E5203"
            case ErrorCode.MemHeapCorruption => "E5204"
            case ErrorCode.MemLeakDetected => "E5205"
            case ErrorCode.MemInvalidFree => "E5206"
            case ErrorCode.MemUnalignedAccess => "E5207"
            case ErrorCode.MemNullDereference => "E5208"
            case ErrorCode.MemBufferOverflow => "E5209"
            case ErrorCode.MemBufferUnderflow => "E5210"
            case ErrorCode.MemStackOverflow => "E5211"
            case ErrorCode.MemGcPauseTooLong => "E5212"
            case ErrorCode.MemGcPromotionFailed => "E5213"
            case ErrorCode.MemGcFragmentation => "E5214"
            case ErrorCode.MemGcCycleLeak => "E5215"
            case ErrorCode.MemFinalizerDeadlock => "E5216"
            case ErrorCode.MemFinalizerRunsLate => "E5217"
            case ErrorCode.MemAllocatorMismatch => "E5218"
            case ErrorCode.MemCustomAllocFail => "E5219"
            case ErrorCode.MemAlignmentTooLarge => "E5220"
            case ErrorCode.MemZeroSizeAlloc => "E5221"
            case ErrorCode.MemReallocShrinkLost => "E5222"
            case ErrorCode.MemMemoryMapFailed => "E5223"
            case ErrorCode.MemGuardPageViolation => "E5224"
            case ErrorCode.MemDanglingPointer => "E5225"
            case ErrorCode.MemWildPointer => "E5226"
            case ErrorCode.MemReferenceCycle => "E5227"
            case ErrorCode.MemArcStrongZero => "E5228"
            case ErrorCode.MemWeakUpgradeFail => "E5229"
            case ErrorCode.MemArenaExhausted => "E5230"
            case ErrorCode.MemArenaDoubleFree => "E5231"
            case ErrorCode.MemStackUnwindCorrupt => "E5232"
            case ErrorCode.MemMoveUninit => "E5233"
            case ErrorCode.MemReadUninit => "E5234"
            case ErrorCode.MemPaddingLeak => "E5235"
            case ErrorCode.MemMemoryTagError => "E5236"
            case ErrorCode.MemHugepageFailed => "E5237"
            case ErrorCode.MemNumaBindFailed => "E5238"
            case ErrorCode.MemOvercommitExceeded => "E5239"
            case ErrorCode.MemGcRootLost => "E5240"
            case ErrorCode.MemAllocatorDeadlock => "E5241"
            case ErrorCode.OsFileNotFound => "E5301"
            case ErrorCode.OsPermissionDenied => "E5302"
            case ErrorCode.OsIoError => "E5303"
            case ErrorCode.OsBrokenPipe => "E5304"
            case ErrorCode.OsTooManyOpenFiles => "E5305"
            case ErrorCode.OsDiskFull => "E5306"
            case ErrorCode.OsNoSuchProcess => "E5307"
            case ErrorCode.OsProcessSpawnFailed => "E5308"
            case ErrorCode.OsSignalReceived => "E5309"
            case ErrorCode.OsTimeoutExceeded => "E5310"
            case ErrorCode.OsResourceLimit => "E5311"
            case ErrorCode.OsAddressInUse => "E5312"
            case ErrorCode.OsConnectionRefused => "E5313"
            case ErrorCode.OsNetworkUnreachable => "E5314"
            case ErrorCode.OsDnsResolveFailed => "E5315"
            case ErrorCode.OsEnvVarMissing => "E5316"
            case ErrorCode.OsEnvVarInvalid => "E5317"
            case ErrorCode.OsWorkingDirMissing => "E5318"
            case ErrorCode.OsSymlinkLoop => "E5319"
            case ErrorCode.OsReadOnlyFileSystem => "E5320"
            case ErrorCode.OsQuotaExceeded => "E5321"
            case ErrorCode.OsInvalidUtf8Path => "E5322"
            case ErrorCode.OsThreadPriorityFailed => "E5323"
            case ErrorCode.OsClockError => "E5324"
            case ErrorCode.OsInsufficientMemory => "E5325"
            case ErrorCode.OsLockFileHeld => "E5326"
            case ErrorCode.OsSharedMemFailed => "E5327"
            case ErrorCode.OsMmapExecDenied => "E5328"
            case ErrorCode.OsSeccompBlocked => "E5329"
            case ErrorCode.OsCapabilityMissing => "E5330"
            case ErrorCode.OsChrootFailed => "E5331"
            case ErrorCode.OsMountFailed => "E5332"
            case ErrorCode.OsNoSuchDevice => "E5333"
            case ErrorCode.OsDeviceBusy => "E5334"
            case ErrorCode.OsInvalidFd => "E5335"
            case ErrorCode.OsPollFailed => "E5336"
            case ErrorCode.OsPipeBufferFull => "E5337"
            case ErrorCode.OsForkNotAllowed => "E5338"
            case ErrorCode.OsProcessAlreadyExited => "E5339"
            case ErrorCode.OsUserNamespaceFailed => "E5340"
            case ErrorCode.OsFileSystemType => "E5341"
            case ErrorCode.LspInvalidRequest => "E6001"
            case ErrorCode.LspDocumentNotFound => "E6002"
            case ErrorCode.LspPositionOutOfRange => "E6003"
            case ErrorCode.LspUnsupportedCapability => "E6004"
            case ErrorCode.LspDiagnosticsStale => "E6005"
            case ErrorCode.LspSemanticTokensFailed => "E6006"
            case ErrorCode.LspCompletionFailed => "E6007"
            case ErrorCode.LspHoverFailed => "E6008"
            case ErrorCode.LspDefinitionNotFound => "E6009"
            case ErrorCode.LspReferenceSearchFailed => "E6010"
            case ErrorCode.LspRenameFailed => "E6011"
            case ErrorCode.LspFormatFailed => "E6012"
            case ErrorCode.LspCodeActionFailed => "E6013"
            case ErrorCode.LspInlayHintFailed => "E6014"
            case ErrorCode.LspFoldingFailed => "E6015"
            case ErrorCode.LspDocumentLinkFailed => "E6016"
            case ErrorCode.LspWorkspaceSymbolFailed => "E6017"
            case ErrorCode.LspConfigurationMissing => "E6018"
            case ErrorCode.LspServerPanic => "E6019"
            case ErrorCode.LspProtocolVersion => "E6020"
            case ErrorCode.LspEncodingMismatch => "E6021"
            case ErrorCode.LspLineEndingMismatch => "E6022"
            case ErrorCode.LspLargeDocument => "E6023"
            case ErrorCode.LspDebounceSkipped => "E6024"
            case ErrorCode.LspIndexCorrupt => "E6025"
            case ErrorCode.LspSlowAnalysis => "E6026"
            case ErrorCode.LspMissingSource => "E6027"
            case ErrorCode.LspUnknownDiagnostic => "E6028"
            case ErrorCode.LspRpcParseFailed => "E6029"
            case ErrorCode.LspCancelledRequest => "E6030"
            case ErrorCode.LspCrashRecovery => "E6031"
            case ErrorCode.LspWorkspaceFolder => "E6032"
            case ErrorCode.LspFileWatcherFailed => "E6033"
            case ErrorCode.LspDiagnosticDuplicate => "E6034"
            case ErrorCode.LspTelemetryDisabled => "E6035"
            case ErrorCode.LspClientInitFailed => "E6036"
            case ErrorCode.LspProgressFailed => "E6037"
            case ErrorCode.LspLinkedEditingFailed => "E6038"
            case ErrorCode.LspCallHierarchyFailed => "E6039"
            case ErrorCode.LspTypeHierarchyFailed => "E6040"
            case ErrorCode.LspDocumentColorFailed => "E6041"
            case ErrorCode.IncrementalCacheMissing => "E6101"
            case ErrorCode.IncrementalCacheCorrupt => "E6102"
            case ErrorCode.IncrementalCacheVersionMismatch => "E6103"
            case ErrorCode.IncrementalDepFileStale => "E6104"
            case ErrorCode.IncrementalHashMismatch => "E6105"
            case ErrorCode.IncrementalFingerprintFailed => "E6106"
            case ErrorCode.IncrementalQueryCycle => "E6107"
            case ErrorCode.IncrementalDirtyNode => "E6108"
            case ErrorCode.IncrementalSerializedFailed => "E6109"
            case ErrorCode.IncrementalDeserializeFailed => "E6110"
            case ErrorCode.IncrementalCacheEvicted => "E6111"
            case ErrorCode.IncrementalUpToDateFalse => "E6112"
            case ErrorCode.IncrementalRebuildCascade => "E6113"
            case ErrorCode.IncrementalLockContention => "E6114"
            case ErrorCode.IncrementalPermissionDenied => "E6115"
            case ErrorCode.IncrementalDiskFull => "E6116"
            case ErrorCode.IncrementalConcurrentWrite => "E6117"
            case ErrorCode.IncrementalMetadataMismatch => "E6118"
            case ErrorCode.IncrementalIncrementalDisabled => "E6119"
            case ErrorCode.IncrementalChangedEnv => "E6120"
            case ErrorCode.IncrementalChangedFlags => "E6121"
            case ErrorCode.IncrementalChangedTarget => "E6122"
            case ErrorCode.IncrementalFingerprintSalt => "E6123"
            case ErrorCode.IncrementalNodeLimit => "E6124"
            case ErrorCode.IncrementalGraphTooLarge => "E6125"
            case ErrorCode.IncrementalCachePathTooLong => "E6126"
            case ErrorCode.IncrementalSymlinkCache => "E6127"
            case ErrorCode.IncrementalToolchainChanged => "E6128"
            case ErrorCode.IncrementalIncrementalPanic => "E6129"
            case ErrorCode.IncrementalQueryStackOverflow => "E6130"
            case ErrorCode.IncrementalCacheReadTimeout => "E6131"
            case ErrorCode.IncrementalPersistentCache => "E6132"
            case ErrorCode.IncrementalDirtyAll => "E6133"
            case ErrorCode.IncrementalHashCollision => "E6134"
            case ErrorCode.IncrementalDepTrackingLost => "E6135"
            case ErrorCode.IncrementalIncrementalOOM => "E6136"
            case ErrorCode.IncrementalVersionDowngrade => "E6137"
            case ErrorCode.IncrementalCacheMigration => "E6138"
            case ErrorCode.IncrementalUntrackedInput => "E6139"
            case ErrorCode.PkgManifestNotFound => "E6201"
            case ErrorCode.PkgManifestParse => "E6202"
            case ErrorCode.PkgDependencyMissing => "E6203"
            case ErrorCode.PkgDependencyVersion => "E6204"
            case ErrorCode.PkgDependencyConflict => "E6205"
            case ErrorCode.PkgRegistryUnreachable => "E6206"
            case ErrorCode.PkgDownloadFailed => "E6207"
            case ErrorCode.PkgChecksumMismatch => "E6208"
            case ErrorCode.PkgLockfileStale => "E6209"
            case ErrorCode.PkgLockfileConflict => "E6210"
            case ErrorCode.PkgCircularDependency => "E6211"
            case ErrorCode.PkgFeatureNotFound => "E6212"
            case ErrorCode.PkgFeatureConflict => "E6213"
            case ErrorCode.PkgBuildScriptFailed => "E6214"
            case ErrorCode.PkgGitDependencyFailed => "E6215"
            case ErrorCode.PkgLocalPathMissing => "E6216"
            case ErrorCode.PkgPublishDenied => "E6217"
            case ErrorCode.PkgPackageNameInvalid => "E6218"
            case ErrorCode.PkgPackageVersionInvalid => "E6219"
            case ErrorCode.PkgYankedPackage => "E6220"
            case ErrorCode.PkgUnresolvedProxy => "E6221"
            case ErrorCode.PkgMirrorSync => "E6222"
            case ErrorCode.PkgLicenseMissing => "E6223"
            case ErrorCode.PkgLicenseConflict => "E6224"
            case ErrorCode.PkgPrivatePackage => "E6225"
            case ErrorCode.PkgTokenExpired => "E6226"
            case ErrorCode.PkgPackageTooLarge => "E6227"
            case ErrorCode.PkgInvalidMetadata => "E6228"
            case ErrorCode.PkgSourceIncompatible => "E6229"
            case ErrorCode.PkgPlatformSpecificDep => "E6230"
            case ErrorCode.PkgOptionalDepMissing => "E6231"
            case ErrorCode.PkgDevDependencyLeak => "E6232"
            case ErrorCode.PkgPatchConflict => "E6233"
            case ErrorCode.PkgWorkspaceMember => "E6234"
            case ErrorCode.PkgWorkspaceInherit => "E6235"
            case ErrorCode.PkgOverridesConflict => "E6236"
            case ErrorCode.PkgVendoredMismatch => "E6237"
            case ErrorCode.PkgCachePermission => "E6238"
            case ErrorCode.PkgResolveTimeout => "E6239"
            case ErrorCode.PkgDuplicatePackage => "E6240"
            case ErrorCode.PkgTargetSpecificManifest => "E6241"
            case ErrorCode.BuildBuildScriptPanic => "E6301"
            case ErrorCode.BuildBuildTargetMissing => "E6302"
            case ErrorCode.BuildBuildProfileUnknown => "E6303"
            case ErrorCode.BuildArtifactNotFound => "E6304"
            case ErrorCode.BuildCompileStepFailed => "E6305"
            case ErrorCode.BuildLinkStepFailed => "E6306"
            case ErrorCode.BuildCustomTargetFailed => "E6307"
            case ErrorCode.BuildBuildCacheInvalid => "E6308"
            case ErrorCode.BuildParallelBuildDeadlock => "E6309"
            case ErrorCode.BuildJobServerUnavailable => "E6310"
            case ErrorCode.BuildOutputDirLocked => "E6311"
            case ErrorCode.BuildPermissionDenied => "E6312"
            case ErrorCode.BuildDiskFull => "E6313"
            case ErrorCode.BuildBuildTimeout => "E6314"
            case ErrorCode.BuildIncrementalDisabled => "E6315"
            case ErrorCode.BuildFeatureGateBuild => "E6316"
            case ErrorCode.BuildCrossCompileToolchain => "E6317"
            case ErrorCode.BuildSysrootMissing => "E6318"
            case ErrorCode.BuildEnvVarMissing => "E6319"
            case ErrorCode.BuildBuildScriptEnv => "E6320"
            case ErrorCode.BuildFingerprintMismatch => "E6321"
            case ErrorCode.BuildDepInfoStale => "E6322"
            case ErrorCode.BuildTargetTripleInvalid => "E6323"
            case ErrorCode.BuildBuildPlanFailed => "E6324"
            case ErrorCode.BuildPostBuildFailed => "E6325"
            case ErrorCode.BuildTestHarnessFailed => "E6326"
            case ErrorCode.BuildBenchHarnessFailed => "E6327"
            case ErrorCode.BuildDocBuildFailed => "E6328"
            case ErrorCode.BuildExampleBuildFailed => "E6329"
            case ErrorCode.BuildToolchainDownload => "E6330"
            case ErrorCode.BuildRustflagsConflict => "E6331"
            case ErrorCode.BuildCfgNotDefined => "E6332"
            case ErrorCode.BuildBuildScriptRebuild => "E6333"
            case ErrorCode.BuildLockContention => "E6334"
            case ErrorCode.BuildTargetSpecificFail => "E6335"
            case ErrorCode.BuildOutOfMemory => "E6336"
            case ErrorCode.BuildSignalInterrupted => "E6337"
            case ErrorCode.BuildTmpDirUnwritable => "E6338"
            case ErrorCode.BuildBuildHookFailed => "E6339"
            case ErrorCode.BuildUnsupportedAction => "E6340"
            case ErrorCode.DebugDwarfEmitFailed => "E6401"
            case ErrorCode.DebugDebugInfoStripped => "E6402"
            case ErrorCode.DebugLineTableMissing => "E6403"
            case ErrorCode.DebugVariableLocation => "E6404"
            case ErrorCode.DebugTypeInfoMissing => "E6405"
            case ErrorCode.DebugInlinedFrame => "E6406"
            case ErrorCode.DebugBreakpointUnavailable => "E6407"
            case ErrorCode.DebugWatchpointFailed => "E6408"
            case ErrorCode.DebugSymbolNotFound => "E6409"
            case ErrorCode.DebugSourceMapMissing => "E6410"
            case ErrorCode.DebugPdbEmitFailed => "E6411"
            case ErrorCode.DebugDebuggerAttachFailed => "E6412"
            case ErrorCode.DebugCoreDumpFailed => "E6413"
            case ErrorCode.DebugBacktraceUnavailable => "E6414"
            case ErrorCode.DebugOptimizedOut => "E6415"
            case ErrorCode.DebugDebugMacroInfo => "E6416"
            case ErrorCode.DebugNamespaceInfoMissing => "E6417"
            case ErrorCode.DebugTemplateInfoMissing => "E6418"
            case ErrorCode.DebugSplitDebugFailed => "E6419"
            case ErrorCode.DebugDebugCompression => "E6420"
            case ErrorCode.DebugLineZero => "E6421"
            case ErrorCode.DebugColumnInfoMissing => "E6422"
            case ErrorCode.DebugInheritanceInfo => "E6423"
            case ErrorCode.DebugAsyncBacktrace => "E6424"
            case ErrorCode.DebugDebugPrettyPrinter => "E6425"
            case ErrorCode.DebugEvalFailed => "E6426"
            case ErrorCode.DebugConditionalBreakpoint => "E6427"
            case ErrorCode.DebugDebugServerDown => "E6428"
            case ErrorCode.DebugProtocolHandshake => "E6429"
            case ErrorCode.DebugSymbolicateFailed => "E6430"
            case ErrorCode.DebugDebugInfoMismatch => "E6431"
            case ErrorCode.DebugFrameCorrupt => "E6432"
            case ErrorCode.DebugUnwindInfoMissing => "E6433"
            case ErrorCode.DebugDebugSectionsStripped => "E6434"
            case ErrorCode.DebugTypeAliasInfo => "E6435"
            case ErrorCode.DebugLocalVarOmitted => "E6436"
            case ErrorCode.DebugDebugInfoTooLarge => "E6437"
            case ErrorCode.DebugCorruptDebugInfo => "E6438"
            case ErrorCode.DebugMissingCompilationUnit => "E6439"
            case ErrorCode.DebugDebugArangesMissing => "E6440"
            case ErrorCode.DistRemoteNodeDown => "E6501"
            case ErrorCode.DistSchedulerUnreachable => "E6502"
            case ErrorCode.DistJobDispatchFailed => "E6503"
            case ErrorCode.DistResultFetchFailed => "E6504"
            case ErrorCode.DistNodeAuthFailed => "E6505"
            case ErrorCode.DistInconsistentEnv => "E6506"
            case ErrorCode.DistCacheSyncFailed => "E6507"
            case ErrorCode.DistNetworkPartition => "E6508"
            case ErrorCode.DistTimeoutExceeded => "E6509"
            case ErrorCode.DistResultCorrupt => "E6510"
            case ErrorCode.DistNodeOverloaded => "E6511"
            case ErrorCode.DistArtifactMismatch => "E6512"
            case ErrorCode.DistUnsupportedTarget => "E6513"
            case ErrorCode.DistCompilationUnitTooBig => "E6514"
            case ErrorCode.DistDependencyNotCached => "E6515"
            case ErrorCode.DistSecureChannelFailed => "E6516"
            case ErrorCode.DistHeartbeatLost => "E6517"
            case ErrorCode.DistQuotaExceeded => "E6518"
            case ErrorCode.DistRegionMismatch => "E6519"
            case ErrorCode.DistSerializationFailed => "E6520"
            case ErrorCode.DistDeserializationFailed => "E6521"
            case ErrorCode.DistVersionSkew => "E6522"
            case ErrorCode.DistPartialFailure => "E6523"
            case ErrorCode.DistLoadImbalance => "E6524"
            case ErrorCode.DistIdempotencyViolation => "E6525"
            case ErrorCode.DistCachePoisoned => "E6526"
            case ErrorCode.DistBandwidthLimited => "E6527"
            case ErrorCode.DistNodeBlacklisted => "E6528"
            case ErrorCode.DistCompilationAborted => "E6529"
            case ErrorCode.DistCheckpointFailed => "E6530"
            case ErrorCode.DistRecoverFailed => "E6531"
            case ErrorCode.DistTokenExpired => "E6532"
            case ErrorCode.DistMisconfiguredPool => "E6533"
            case ErrorCode.DistCompilationDrift => "E6534"
            case ErrorCode.DistAuditLogMissing => "E6535"
            case ErrorCode.DistColdStart => "E6536"
            case ErrorCode.DistResourceContention => "E6537"
            case ErrorCode.DistUnsupportedFeature => "E6538"
            case ErrorCode.PluginPluginNotFound => "E6601"
            case ErrorCode.PluginPluginLoadFailed => "E6602"
            case ErrorCode.PluginPluginVersionMismatch => "E6603"
            case ErrorCode.PluginPluginApiChanged => "E6604"
            case ErrorCode.PluginPluginPanic => "E6605"
            case ErrorCode.PluginPluginTimeout => "E6606"
            case ErrorCode.PluginPluginPermissionDenied => "E6607"
            case ErrorCode.PluginPluginConflict => "E6608"
            case ErrorCode.PluginPluginSignatureInvalid => "E6609"
            case ErrorCode.PluginPluginUnsafeOperation => "E6610"
            case ErrorCode.PluginPluginInitFailed => "E6611"
            case ErrorCode.PluginPluginDepMissing => "E6612"
            case ErrorCode.PluginPluginConfigInvalid => "E6613"
            case ErrorCode.PluginPluginHookError => "E6614"
            case ErrorCode.PluginPluginResourceLeak => "E6615"
            case ErrorCode.PluginPluginCrashed => "E6616"
            case ErrorCode.PluginPluginDisabled => "E6617"
            case ErrorCode.PluginPluginTooOld => "E6618"
            case ErrorCode.PluginPluginTooNew => "E6619"
            case ErrorCode.PluginPluginNameConflict => "E6620"
            case ErrorCode.PluginPluginCycle => "E6621"
            case ErrorCode.PluginPluginSandboxViolation => "E6622"
            case ErrorCode.PluginPluginOutOfMemory => "E6623"
            case ErrorCode.PluginPluginDeadlock => "E6624"
            case ErrorCode.PluginPluginNetworkBlocked => "E6625"
            case ErrorCode.PluginPluginFileSystemBlocked => "E6626"
            case ErrorCode.PluginPluginEnvBlocked => "E6627"
            case ErrorCode.PluginPluginUnserialize => "E6628"
            case ErrorCode.PluginPluginHotReloadFailed => "E6629"
            case ErrorCode.PluginPluginUnloadFailed => "E6630"
            case ErrorCode.PluginPluginCapabilityMissing => "E6631"
            case ErrorCode.PluginPluginDeprecated => "E6632"
            case ErrorCode.PluginPluginManifestInvalid => "E6633"
            case ErrorCode.PluginPluginEntryMissing => "E6634"
            case ErrorCode.PluginPluginAbiMismatch => "E6635"
            case ErrorCode.PluginPluginLangMismatch => "E6636"
            case ErrorCode.PluginPluginBadExit => "E6637"
            case ErrorCode.PluginPluginStdoutParse => "E6638"
            case ErrorCode.PluginPluginLockContention => "E6639"
            case ErrorCode.TgtTargetTripleInvalid => "E6701"
            case ErrorCode.TgtTargetUnsupported => "E6702"
            case ErrorCode.TgtTargetFeatureMissing => "E6703"
            case ErrorCode.TgtTargetArchUnknown => "E6704"
            case ErrorCode.TgtTargetOsUnknown => "E6705"
            case ErrorCode.TgtTargetEnvUnknown => "E6706"
            case ErrorCode.TgtTargetVendorUnknown => "E6707"
            case ErrorCode.TgtTargetPointerWidth => "E6708"
            case ErrorCode.TgtTargetEndianUnknown => "E6709"
            case ErrorCode.TgtTargetFloatUnsupported => "E6710"
            case ErrorCode.TgtTargetAtomicMissing => "E6711"
            case ErrorCode.TgtTargetSimdAbsent => "E6712"
            case ErrorCode.TgtTargetTlsModel => "E6713"
            case ErrorCode.TgtTargetRelocation => "E6714"
            case ErrorCode.TgtTargetCodeModel => "E6715"
            case ErrorCode.TgtTargetCpuUnknown => "E6716"
            case ErrorCode.TgtTargetFpuUnknown => "E6717"
            case ErrorCode.TgtTargetAbiUnknown => "E6718"
            case ErrorCode.TgtTargetPanicStrategy => "E6719"
            case ErrorCode.TgtTargetAllocStrategy => "E6720"
            case ErrorCode.TgtTargetSyscallConv => "E6721"
            case ErrorCode.TgtTargetStackProbe => "E6722"
            case ErrorCode.TgtTargetExceptionModel => "E6723"
            case ErrorCode.TgtTargetDebugFormat => "E6724"
            case ErrorCode.TgtTargetObjFormat => "E6725"
            case ErrorCode.TgtTargetLinkerMissing => "E6726"
            case ErrorCode.TgtTargetRuntimeMissing => "E6727"
            case ErrorCode.TgtTargetLibcMissing => "E6728"
            case ErrorCode.TgtTargetNoStd => "E6729"
            case ErrorCode.TgtTargetNoAtomic => "E6730"
            case ErrorCode.TgtTargetUnsupportedFloat => "E6731"
            case ErrorCode.TgtTargetRegisterWidth => "E6732"
            case ErrorCode.TgtTargetProfiling => "E6733"
            case ErrorCode.TgtTargetSanitizerAbsent => "E6734"
            case ErrorCode.TgtTargetCoverage => "E6735"
            case ErrorCode.TgtTargetPositionIndependent => "E6736"
            case ErrorCode.TgtTargetThreadLocal => "E6737"
            case ErrorCode.TgtTargetUnwindUnsupported => "E6738"
            case ErrorCode.TgtTargetVendorLibMissing => "E6739"
            case ErrorCode.SimdSimdWidthUnsupported => "E6801"
            case ErrorCode.SimdSimdTypeMismatch => "E6802"
            case ErrorCode.SimdSimdLaneCount => "E6803"
            case ErrorCode.SimdSimdUnaligned => "E6804"
            case ErrorCode.SimdSimdMaskInvalid => "E6805"
            case ErrorCode.SimdSimdReductionFailed => "E6806"
            case ErrorCode.SimdSimdShuffleInvalid => "E6807"
            case ErrorCode.SimdSimdGatherScatter => "E6808"
            case ErrorCode.SimdSimdIntrinsicMissing => "E6809"
            case ErrorCode.SimdSimdOverflow => "E6810"
            case ErrorCode.SimdSimdDivByZero => "E6811"
            case ErrorCode.SimdSimdNanPropagate => "E6812"
            case ErrorCode.SimdSimdConstantInvalid => "E6813"
            case ErrorCode.SimdSimdCvtFailed => "E6814"
            case ErrorCode.SimdSimdPermuteFailed => "E6815"
            case ErrorCode.SimdSimdBlendInvalid => "E6816"
            case ErrorCode.SimdSimdExtractOob => "E6817"
            case ErrorCode.SimdSimdInsertOob => "E6818"
            case ErrorCode.SimdSimdCompareResult => "E6819"
            case ErrorCode.SimdSimdBitcast => "E6820"
            case ErrorCode.SimdSimdAlignment => "E6821"
            case ErrorCode.SimdSimdTargetAbsent => "E6822"
            case ErrorCode.SimdSimdLengthMismatch => "E6823"
            case ErrorCode.SimdSimdSignedUnsigned => "E6824"
            case ErrorCode.SimdSimdRounding => "E6825"
            case ErrorCode.SimdSimdSaturation => "E6826"
            case ErrorCode.SimdSimdFmaMissing => "E6827"
            case ErrorCode.SimdSimdConflict => "E6828"
            case ErrorCode.SimdSimdRegisterPressure => "E6829"
            case ErrorCode.SimdSimdLaneOrder => "E6830"
            case ErrorCode.SimdSimdPredicateInvalid => "E6831"
            case ErrorCode.SimdSimdRotated => "E6832"
            case ErrorCode.SimdSimdPopcount => "E6833"
            case ErrorCode.SimdSimdShiftOob => "E6834"
            case ErrorCode.SimdSimdSelectInvalid => "E6835"
            case ErrorCode.SimdSimdWidenFailed => "E6836"
            case ErrorCode.SimdSimdNarrowFailed => "E6837"
            case ErrorCode.SimdSimdInterleave => "E6838"
            case ErrorCode.SimdSimdDeinterleave => "E6839"
            case ErrorCode.EmbedEmbedNoStd => "E6901"
            case ErrorCode.EmbedEmbedNoAlloc => "E6902"
            case ErrorCode.EmbedEmbedFlashFull => "E6903"
            case ErrorCode.EmbedEmbedRamFull => "E6904"
            case ErrorCode.EmbedEmbedNoFloat => "E6905"
            case ErrorCode.EmbedEmbedNoException => "E6906"
            case ErrorCode.EmbedEmbedNoRtti => "E6907"
            case ErrorCode.EmbedEmbedHardFault => "E6908"
            case ErrorCode.EmbedEmbedWatchdog => "E6909"
            case ErrorCode.EmbedEmbedInterruptNested => "E6910"
            case ErrorCode.EmbedEmbedStackOverflow => "E6911"
            case ErrorCode.EmbedEmbedHeapCorrupt => "E6912"
            case ErrorCode.EmbedEmbedPeripheralBusy => "E6913"
            case ErrorCode.EmbedEmbedDmaFailed => "E6914"
            case ErrorCode.EmbedEmbedClockMisconfig => "E6915"
            case ErrorCode.EmbedEmbedPinConflict => "E6916"
            case ErrorCode.EmbedEmbedNoSyscall => "E6917"
            case ErrorCode.EmbedCgoSymbolClash => "E6918"
            case ErrorCode.EmbedCgoTypeMismatch => "E6919"
            case ErrorCode.EmbedCgoCallbackNull => "E6920"
            case ErrorCode.EmbedCgoPanicCross => "E6921"
            case ErrorCode.EmbedCgoThreadLocal => "E6922"
            case ErrorCode.EmbedCgoAllocMismatch => "E6923"
            case ErrorCode.EmbedEmbedInterruptPriority => "E6924"
            case ErrorCode.EmbedEmbedBootFailed => "E6925"
            case ErrorCode.EmbedEmbedLinkerScript => "E6926"
            case ErrorCode.EmbedEmbedVectorTable => "E6927"
            case ErrorCode.EmbedEmbedNoAtomic => "E6928"
            case ErrorCode.EmbedEmbedWatchpoint => "E6929"
            case ErrorCode.EmbedEmbedPowerFail => "E6930"
            case ErrorCode.EmbedEmbedStackCanary => "E6931"
            case ErrorCode.EmbedEmbedMpuViolation => "E6932"
            case ErrorCode.EmbedEmbedCacheCoherency => "E6933"
            case ErrorCode.EmbedCgoCcNotFound => "E6934"
            case ErrorCode.EmbedCgoBuildFailed => "E6935"
            case ErrorCode.EmbedEmbedNoStdio => "E6936"
            case ErrorCode.EmbedEmbedTickFailed => "E6937"
            case ErrorCode.EmbedEmbedCriticalSection => "E6938"
            case ErrorCode.EmbedEmbedNoFpu => "E6939"
            case ErrorCode.EmbedCgoCallbackLifetime => "E6940"
            case ErrorCode.TestTestCompileFailed => "E7001"
            case ErrorCode.TestTestBinaryMissing => "E7002"
            case ErrorCode.TestTestTimeout => "E7003"
            case ErrorCode.TestTestPanic => "E7004"
            case ErrorCode.TestTestAssertFailed => "E7005"
            case ErrorCode.TestTestFixtureFailed => "E7006"
            case ErrorCode.TestTestTeardownFailed => "E7007"
            case ErrorCode.TestTestFilterNoMatch => "E7008"
            case ErrorCode.TestTestDuplicateName => "E7009"
            case ErrorCode.TestTestDependencyOrder => "E7010"
            case ErrorCode.TestTestResourceLeak => "E7011"
            case ErrorCode.TestTestIgnored => "E7012"
            case ErrorCode.TestTestShouldPanic => "E7013"
            case ErrorCode.TestTestUnexpectedPanic => "E7014"
            case ErrorCode.TestTestFlaky => "E7015"
            case ErrorCode.TestTestHarnessCrash => "E7016"
            case ErrorCode.TestTestStdoutCapture => "E7017"
            case ErrorCode.TestTestEnvMissing => "E7018"
            case ErrorCode.TestTestDataMissing => "E7019"
            case ErrorCode.TestTestMockFailed => "E7020"
            case ErrorCode.TestTestConcurrency => "E7021"
            case ErrorCode.TestTestDeadlock => "E7022"
            case ErrorCode.TestTestLeakSanitizer => "E7023"
            case ErrorCode.TestTestCoverageFailed => "E7024"
            case ErrorCode.TestTestReportFailed => "E7025"
            case ErrorCode.TestTestParallelConflict => "E7026"
            case ErrorCode.TestTestBeforeAllFailed => "E7027"
            case ErrorCode.TestTestAfterAllFailed => "E7028"
            case ErrorCode.TestTestSkipCondition => "E7029"
            case ErrorCode.TestTestParamMismatch => "E7030"
            case ErrorCode.TestTestTimeoutConfig => "E7031"
            case ErrorCode.TestTestBinaryCrash => "E7032"
            case ErrorCode.TestTestSignal => "E7033"
            case ErrorCode.TestTestMemoryLimit => "E7034"
            case ErrorCode.TestTestIsolation => "E7035"
            case ErrorCode.TestTestRandomSeed => "E7036"
            case ErrorCode.TestTestImportFailed => "E7037"
            case ErrorCode.TestTestUnknownAttr => "E7038"
            case ErrorCode.TestTestDoubleRun => "E7039"
            case ErrorCode.TestTestSummaryLost => "E7040"
            case ErrorCode.TestTestHang => "E7041"
            case ErrorCode.DocDocBrokenLink => "E7101"
            case ErrorCode.DocDocMissingItem => "E7102"
            case ErrorCode.DocDocCodeBlockFailed => "E7103"
            case ErrorCode.DocDocTestFailed => "E7104"
            case ErrorCode.DocDocExamplePanic => "E7105"
            case ErrorCode.DocDocCompileFailed => "E7106"
            case ErrorCode.DocDocMalformedAttr => "E7107"
            case ErrorCode.DocDocCyclicModule => "E7108"
            case ErrorCode.DocDocPrivateLeak => "E7109"
            case ErrorCode.DocDocHtmlEscape => "E7110"
            case ErrorCode.DocDocMissingSummary => "E7111"
            case ErrorCode.DocDocBrokenIntraLink => "E7112"
            case ErrorCode.DocDocAliasConflict => "E7113"
            case ErrorCode.DocDocSearchIndex => "E7114"
            case ErrorCode.DocDocThemeFailed => "E7115"
            case ErrorCode.DocDocAssetMissing => "E7116"
            case ErrorCode.DocDocCommentTooLong => "E7117"
            case ErrorCode.DocDocNonAsciiPath => "E7118"
            case ErrorCode.DocDocVersionMismatch => "E7119"
            case ErrorCode.DocDocExampleOutdated => "E7120"
            case ErrorCode.DocDocInvalidMarkdown => "E7121"
            case ErrorCode.DocDocTableBroken => "E7122"
            case ErrorCode.DocDocCodeLangUnknown => "E7123"
            case ErrorCode.DocDocRedirectLoop => "E7124"
            case ErrorCode.DocDocCrossCrate => "E7125"
            case ErrorCode.DocDocFeatureGate => "E7126"
            case ErrorCode.DocDocJsonFailed => "E7127"
            case ErrorCode.DocDocTestCompileTimeout => "E7128"
            case ErrorCode.DocDocHiddenItemRef => "E7129"
            case ErrorCode.DocDocDuplicateAnchor => "E7130"
            case ErrorCode.DocDocMacroDoc => "E7131"
            case ErrorCode.DocDocTraitImplMissing => "E7132"
            case ErrorCode.DocDocGenericParam => "E7133"
            case ErrorCode.DocDocCfgFiltered => "E7134"
            case ErrorCode.DocDocPlatformSpecific => "E7135"
            case ErrorCode.DocDocIncludeFailed => "E7136"
            case ErrorCode.DocDocEduLinkBroken => "E7137"
            case ErrorCode.LintLintUnusedVariable => "E7201"
            case ErrorCode.LintLintUnusedImport => "E7202"
            case ErrorCode.LintLintUnusedFunction => "E7203"
            case ErrorCode.LintLintDeadCode => "E7204"
            case ErrorCode.LintLintDeprecatedUse => "E7205"
            case ErrorCode.LintLintNonSnakeCase => "E7206"
            case ErrorCode.LintLintNonCamelCase => "E7207"
            case ErrorCode.LintLintNonUpperCaseConst => "E7208"
            case ErrorCode.LintLintHardcodedPath => "E7209"
            case ErrorCode.LintLintMagicNumber => "E7210"
            case ErrorCode.LintLintTodoLeft => "E7211"
            case ErrorCode.LintLintPrintStatement => "E7212"
            case ErrorCode.LintLintUnsafeBlock => "E7213"
            case ErrorCode.LintLintCloneInLoop => "E7214"
            case ErrorCode.LintLintComplexity => "E7215"
            case ErrorCode.LintLintTooManyArgs => "E7216"
            case ErrorCode.LintLintDeepNesting => "E7217"
            case ErrorCode.LintLintLineTooLong => "E7218"
            case ErrorCode.LintLintDocMissing => "E7219"
            case ErrorCode.LintLintCopyInsteadRef => "E7220"
            case ErrorCode.LintLintWildcardImport => "E7221"
            case ErrorCode.LintLintUnreachablePattern => "E7222"
            case ErrorCode.LintLintNonExhaustiveLet => "E7223"
            case ErrorCode.LintLintRedundantClone => "E7224"
            case ErrorCode.LintLintShadowing => "E7225"
            case ErrorCode.LintLintMutableNotNeeded => "E7226"
            case ErrorCode.LintLintUnnecessaryMut => "E7227"
            case ErrorCode.LintLintInefficientToStr => "E7228"
            case ErrorCode.LintLintPanicInProd => "E7229"
            case ErrorCode.LintLintFloatEquality => "E7230"
            case ErrorCode.LintLintUnwrapUsed => "E7231"
            case ErrorCode.LintLintExpectUsed => "E7232"
            case ErrorCode.LintLintIndexUnchecked => "E7233"
            case ErrorCode.LintLintIteratorValue => "E7234"
            case ErrorCode.LintLintLargeEnumVariant => "E7235"
            case ErrorCode.LintLintDerefClone => "E7236"
            case ErrorCode.LintLintRedundantField => "E7237"
            case ErrorCode.LintLintNonIdiomatic => "E7238"
            case ErrorCode.LintLintStyleViolation => "E7239"
            case ErrorCode.LintLintUnsafeSuggest => "E7240"
            case ErrorCode.LintLintPossibleBug => "E7241"
            case ErrorCode.SecSecHardcodedSecret => "E7301"
            case ErrorCode.SecSecSqlInjection => "E7302"
            case ErrorCode.SecSecCommandInjection => "E7303"
            case ErrorCode.SecSecPathTraversal => "E7304"
            case ErrorCode.SecSecUnsafeDeserialize => "E7305"
            case ErrorCode.SecSecWeakCrypto => "E7306"
            case ErrorCode.SecSecInsecureRandom => "E7307"
            case ErrorCode.SecSecTlsVerificationOff => "E7308"
            case ErrorCode.SecSecCleartextTransport => "E7309"
            case ErrorCode.SecSecUnsafeEval => "E7310"
            case ErrorCode.SecSecBufferOverflowRisk => "E7311"
            case ErrorCode.SecSecFormatString => "E7312"
            case ErrorCode.SecSecIntegerOverflow => "E7313"
            case ErrorCode.SecSecRaceCondition => "E7314"
            case ErrorCode.SecSecUseAfterFreeRisk => "E7315"
            case ErrorCode.SecSecDoubleFreeRisk => "E7316"
            case ErrorCode.SecSecNullDerefRisk => "E7317"
            case ErrorCode.SecSecSensitiveLog => "E7318"
            case ErrorCode.SecSecInsecureTemp => "E7319"
            case ErrorCode.SecSecSymlinkAttack => "E7320"
            case ErrorCode.SecSecUnsafeCast => "E7321"
            case ErrorCode.SecSecMemoryDisclosure => "E7322"
            case ErrorCode.SecSecMissingAuthz => "E7323"
            case ErrorCode.SecSecMissingAuthn => "E7324"
            case ErrorCode.SecSecCsrfRisk => "E7325"
            case ErrorCode.SecSecXssRisk => "E7326"
            case ErrorCode.SecSecInsecureCookie => "E7327"
            case ErrorCode.SecSecOpenRedirect => "E7328"
            case ErrorCode.SecSecUnsafeReflection => "E7329"
            case ErrorCode.SecSecDependencyVuln => "E7330"
            case ErrorCode.SecSecUnsafePermission => "E7331"
            case ErrorCode.SecSecKeySizeSmall => "E7332"
            case ErrorCode.SecSecHashWeak => "E7333"
            case ErrorCode.SecSecCipherModeWeak => "E7334"
            case ErrorCode.SecSecNonceReuse => "E7335"
            case ErrorCode.SecSecCertExpired => "E7336"
            case ErrorCode.SecSecInsecureProto => "E7337"
            case ErrorCode.SecSecPrivilegeDrop => "E7338"
            case ErrorCode.SecSecInfoLeak => "E7339"
            case ErrorCode.ConfConfigFileNotFound => "E7401"
            case ErrorCode.ConfConfigParseFailed => "E7402"
            case ErrorCode.ConfConfigSchemaInvalid => "E7403"
            case ErrorCode.ConfConfigKeyUnknown => "E7404"
            case ErrorCode.ConfConfigTypeMismatch => "E7405"
            case ErrorCode.ConfConfigMissingRequired => "E7406"
            case ErrorCode.ConfConfigDeprecated => "E7407"
            case ErrorCode.ConfConfigConflict => "E7408"
            case ErrorCode.ConfConfigEnvOverride => "E7409"
            case ErrorCode.ConfConfigProfileUnknown => "E7410"
            case ErrorCode.ConfConfigIncludeFailed => "E7411"
            case ErrorCode.ConfConfigCycle => "E7412"
            case ErrorCode.ConfConfigPermission => "E7413"
            case ErrorCode.ConfConfigEncoding => "E7414"
            case ErrorCode.ConfConfigTooLarge => "E7415"
            case ErrorCode.ConfConfigValidationFailed => "E7416"
            case ErrorCode.ConfConfigDefaultInvalid => "E7417"
            case ErrorCode.ConfConfigRangeViolation => "E7418"
            case ErrorCode.ConfConfigEnumInvalid => "E7419"
            case ErrorCode.ConfConfigPathInvalid => "E7420"
            case ErrorCode.ConfConfigUrlInvalid => "E7421"
            case ErrorCode.ConfConfigTimeoutInvalid => "E7422"
            case ErrorCode.ConfConfigFeatureConflict => "E7423"
            case ErrorCode.ConfConfigTargetMismatch => "E7424"
            case ErrorCode.ConfConfigRuntimeMismatch => "E7425"
            case ErrorCode.ConfConfigHotReloadFailed => "E7426"
            case ErrorCode.ConfConfigSecretLeak => "E7427"
            case ErrorCode.ConfConfigFormatUnknown => "E7428"
            case ErrorCode.ConfConfigMergeConflict => "E7429"
            case ErrorCode.ConfConfigVersionMismatch => "E7430"
            case ErrorCode.ConfConfigUnsafeValue => "E7431"
            case ErrorCode.ConfConfigRedundant => "E7432"
            case ErrorCode.ConfConfigDocMissing => "E7433"
            case ErrorCode.ConfConfigTypeCoercion => "E7434"
            case ErrorCode.ConfConfigPlaceholder => "E7435"
            case ErrorCode.ConfConfigConditional => "E7436"
            case ErrorCode.ConfConfigLocked => "E7437"
            case ErrorCode.ConfConfigEnvMissing => "E7438"
            case ErrorCode.ConfConfigInvalidBool => "E7439"
            case ErrorCode.ConfConfigListEmpty => "E7440"
            case ErrorCode.TelemTelemDisabled => "E7501"
            case ErrorCode.TelemTelemInitFailed => "E7502"
            case ErrorCode.TelemTelemExportFailed => "E7503"
            case ErrorCode.TelemTelemQueueFull => "E7504"
            case ErrorCode.TelemTelemTimeout => "E7505"
            case ErrorCode.TelemTelemUnauthorized => "E7506"
            case ErrorCode.TelemTelemEndpointUnreachable => "E7507"
            case ErrorCode.TelemTelemSchemaInvalid => "E7508"
            case ErrorCode.TelemTelemDropSpans => "E7509"
            case ErrorCode.TelemTelemMissingContext => "E7510"
            case ErrorCode.TelemTelemCardinality => "E7511"
            case ErrorCode.TelemTelemPiiLeak => "E7512"
            case ErrorCode.TelemTelemDuplicate => "E7513"
            case ErrorCode.TelemTelemClockSkew => "E7514"
            case ErrorCode.TelemTelemBufferFlush => "E7515"
            case ErrorCode.TelemTelemOOM => "E7516"
            case ErrorCode.TelemTelemMisconfigured => "E7517"
            case ErrorCode.TelemTelemVersionMismatch => "E7518"
            case ErrorCode.TelemTelemSamplerInvalid => "E7519"
            case ErrorCode.TelemTelemAttrTooLong => "E7520"
            case ErrorCode.TelemTelemNameInvalid => "E7521"
            case ErrorCode.TelemTelemDropMetrics => "E7522"
            case ErrorCode.TelemTelemLogFailed => "E7523"
            case ErrorCode.TelemTelemCrashNoReport => "E7524"
            case ErrorCode.TelemTelemRateLimited => "E7525"
            case ErrorCode.TelemTelemSecretInAttr => "E7526"
            case ErrorCode.TelemTelemExportBlocked => "E7527"
            case ErrorCode.TelemTelemBackpressure => "E7528"
            case ErrorCode.TelemTelemSpanOrphan => "E7529"
            case ErrorCode.TelemTelemLateArrival => "E7530"
            case ErrorCode.TelemTelemStorageFull => "E7531"
            case ErrorCode.TelemTelemEncodingFailed => "E7532"
            case ErrorCode.TelemTelemBatchFailed => "E7533"
            case ErrorCode.TelemTelemNoCollector => "E7534"
            case ErrorCode.TelemTelemInconsistent => "E7535"
            case ErrorCode.TelemTelemDisabledFeature => "E7536"
            case ErrorCode.TelemTelemPrivacyPolicy => "E7537"
            case ErrorCode.TelemTelemAttrCountExceed => "E7538"
            case ErrorCode.XcompileXcompileToolchainMissing => "E7601"
            case ErrorCode.XcompileXcompileSysrootMissing => "E7602"
            case ErrorCode.XcompileXcompileLinkerMissing => "E7603"
            case ErrorCode.XcompileXcompileTargetLibMissing => "E7604"
            case ErrorCode.XcompileXcompileAbiMismatch => "E7605"
            case ErrorCode.XcompileXcompileSyscallDiff => "E7606"
            case ErrorCode.XcompileXcompileEndianDiff => "E7607"
            case ErrorCode.XcompileXcompilePointerWidth => "E7608"
            case ErrorCode.XcompileXcompileFpuDiff => "E7609"
            case ErrorCode.XcompileXcompileAtomicAbsent => "E7610"
            case ErrorCode.XcompileXcompileCrtMissing => "E7611"
            case ErrorCode.XcompileXcompileUnwindDiff => "E7612"
            case ErrorCode.XcompileXcompileEnvMismatch => "E7613"
            case ErrorCode.XcompileXcompileQemuMissing => "E7614"
            case ErrorCode.XcompileXcompileRunFailed => "E7615"
            case ErrorCode.XcompileXcompileHostDep => "E7616"
            case ErrorCode.XcompileXcompilePathSep => "E7617"
            case ErrorCode.XcompileXcompileDlopen => "E7618"
            case ErrorCode.XcompileXcompileTlsModel => "E7619"
            case ErrorCode.XcompileXcompileStackProbe => "E7620"
            case ErrorCode.XcompileXcompileCodeModel => "E7621"
            case ErrorCode.XcompileXcompileArchFeature => "E7622"
            case ErrorCode.XcompileXcompileLinkScript => "E7623"
            case ErrorCode.XcompileXcompileObjFormat => "E7624"
            case ErrorCode.XcompileXcompileDebugFormat => "E7625"
            case ErrorCode.XcompileXcompileVendorLib => "E7626"
            case ErrorCode.XcompileXcompileSyscallTable => "E7627"
            case ErrorCode.XcompileXcompileFloatAbi => "E7628"
            case ErrorCode.XcompileXcompileAlignDiff => "E7629"
            case ErrorCode.XcompileXcompileVaList => "E7630"
            case ErrorCode.XcompileXcompileTimeT => "E7631"
            case ErrorCode.XcompileXcompileWchar => "E7632"
            case ErrorCode.XcompileXcompileLongDouble => "E7633"
            case ErrorCode.XcompileXcompileUnwindLib => "E7634"
            case ErrorCode.XcompileXcompileSanitizer => "E7635"
            case ErrorCode.XcompileXcompileCoverage => "E7636"
            case ErrorCode.XcompileXcompileProfile => "E7637"
            case ErrorCode.XcompileXcompileEmulatorCrash => "E7638"
            case ErrorCode.XcompileXcompileTargetJson => "E7639"
            case ErrorCode.WasmWasmTargetUnsupported => "E7701"
            case ErrorCode.WasmWasmInvalidOpcode => "E7702"
            case ErrorCode.WasmWasmMemoryGrowFailed => "E7703"
            case ErrorCode.WasmWasmTableFull => "E7704"
            case ErrorCode.WasmWasmFuncIndexOob => "E7705"
            case ErrorCode.WasmWasmTypeMismatch => "E7706"
            case ErrorCode.WasmWasmImportMissing => "E7707"
            case ErrorCode.WasmWasmExportMissing => "E7708"
            case ErrorCode.WasmWasmStackOverflow => "E7709"
            case ErrorCode.WasmWasmUnreachable => "E7710"
            case ErrorCode.WasmWasmGasExceeded => "E7711"
            case ErrorCode.WasmWasmSyscallAbsent => "E7712"
            case ErrorCode.WasmWasmBindgenFailed => "E7713"
            case ErrorCode.WasmWasmAbiMismatch => "E7714"
            case ErrorCode.WasmWasmJsInterop => "E7715"
            case ErrorCode.WasmWasmNoThreads => "E7716"
            case ErrorCode.WasmWasmNoSimd => "E7717"
            case ErrorCode.WasmWasmNoException => "E7718"
            case ErrorCode.WasmWasmSharedMemory => "E7719"
            case ErrorCode.WasmWasmTailCall => "E7720"
            case ErrorCode.WasmWasmBulkMemory => "E7721"
            case ErrorCode.WasmWasmReferenceTypes => "E7722"
            case ErrorCode.WasmWasmMultiValue => "E7723"
            case ErrorCode.WasmWasmSignExtension => "E7724"
            case ErrorCode.WasmWasmSatFloat => "E7725"
            case ErrorCode.WasmWasmMutableGlobal => "E7726"
            case ErrorCode.WasmWasmExceptionEncoding => "E7727"
            case ErrorCode.WasmWasmImportTypeError => "E7728"
            case ErrorCode.WasmWasmStartFunc => "E7729"
            case ErrorCode.WasmWasmDataCount => "E7730"
            case ErrorCode.WasmWasmCustomSection => "E7731"
            case ErrorCode.WasmWasmNameSection => "E7732"
            case ErrorCode.WasmWasmLinkerFailed => "E7733"
            case ErrorCode.WasmWasmValidationFailed => "E7734"
            case ErrorCode.WasmWasmInstantiationFailed => "E7735"
            case ErrorCode.WasmWasmNoStd => "E7736"
            case ErrorCode.WasmWasmNoFilesystem => "E7737"
            case ErrorCode.WasmWasmNoNetwork => "E7738"
            case ErrorCode.WasmWasmSizeLimit => "E7739"
            case ErrorCode.GpuGpuTargetUnsupported => "E7801"
            case ErrorCode.GpuGpuKernelCompileFailed => "E7802"
            case ErrorCode.GpuGpuDeviceNotFound => "E7803"
            case ErrorCode.GpuGpuOutOfMemory => "E7804"
            case ErrorCode.GpuGpuIllegalAccess => "E7805"
            case ErrorCode.GpuGpuWarpDivergence => "E7806"
            case ErrorCode.GpuGpuSyncFailed => "E7807"
            case ErrorCode.GpuGpuTimeout => "E7808"
            case ErrorCode.GpuGpuInvalidDim => "E7809"
            case ErrorCode.GpuGpuSharedMemExceed => "E7810"
            case ErrorCode.GpuGpuNoDouble => "E7811"
            case ErrorCode.GpuGpuUnifiedMemory => "E7812"
            case ErrorCode.GpuGpuDriverMismatch => "E7813"
            case ErrorCode.GpuGpuContextLost => "E7814"
            case ErrorCode.GpuGpuStreamFailed => "E7815"
            case ErrorCode.GpuGpuEventFailed => "E7816"
            case ErrorCode.GpuGpuCopyFailed => "E7817"
            case ErrorCode.GpuGpuKernelArg => "E7818"
            case ErrorCode.GpuGpuOccupancyLow => "E7819"
            case ErrorCode.GpuGpuRegisterSpill => "E7820"
            case ErrorCode.GpuGpuBankConflict => "E7821"
            case ErrorCode.GpuGpuAtomicUnsupported => "E7822"
            case ErrorCode.GpuGpuCooperativeGroup => "E7823"
            case ErrorCode.GpuGpuTensorCore => "E7824"
            case ErrorCode.GpuGpuGraphFailed => "E7825"
            case ErrorCode.GpuGpuMpsUnavailable => "E7826"
            case ErrorCode.GpuGpuMultiDevice => "E7827"
            case ErrorCode.GpuGpuPeerAccess => "E7828"
            case ErrorCode.GpuGpuProfilerFailed => "E7829"
            case ErrorCode.GpuGpuDebugUnsupported => "E7830"
            case ErrorCode.GpuGpuPrintfFailed => "E7831"
            case ErrorCode.GpuGpuAssertFailed => "E7832"
            case ErrorCode.GpuGpuUnsupportedType => "E7833"
            case ErrorCode.GpuGpuLaunchFailed => "E7834"
            case ErrorCode.GpuGpuNoHostCode => "E7835"
            case ErrorCode.GpuGpuLinkFailed => "E7836"
            case ErrorCode.GpuGpuFatbinMissing => "E7837"
            case ErrorCode.GpuGpuArchMismatch => "E7838"
            case ErrorCode.GpuGpuResourceLeak => "E7839"

            // Lexer
            case ErrorCode.LexerUnterminatedString => "E0001"
            case ErrorCode.LexerUnterminatedBlockComment => "E0002"
            case ErrorCode.LexerInvalidEscapeSequence => "E0003"
            case ErrorCode.LexerInvalidNumberLiteral => "E0004"
            case ErrorCode.LexerUnexpectedCharacter => "E0005"
            case ErrorCode.LexerInvalidIdentifier => "E0006"
            case ErrorCode.LexerNumericOverflow => "E0007"
            case ErrorCode.LexerUnterminatedCharLiteral => "E0008"
            case ErrorCode.LexerEmptyCharLiteral => "E0009"
            case ErrorCode.LexerInvalidUtf8Sequence => "E0010"
            case ErrorCode.LexerInvalidNumericSuffix => "E0011"
            case ErrorCode.LexerNewlineInStringLiteral => "E0012"
            case ErrorCode.LexerInvalidIdentifierStart => "E0013"
            case ErrorCode.LexerInvalidRawStringDelimiter => "E0014"
            case ErrorCode.LexerNestedCommentTooDeep => "E0015"
            case ErrorCode.LexerInvalidUnicodeEscape => "E0016"
            case ErrorCode.LexerLeadingZero => "E0017"
            case ErrorCode.LexerCharLiteralTooLong => "E0018"
            case ErrorCode.LexerUnsupportedLineEnding => "E0019"
            case ErrorCode.LexerBOMEncodingConflict => "E0020"
            case ErrorCode.LexerDigitSeparatorMisplaced => "E0021"
            case ErrorCode.LexerUnterminatedRawString => "E0022"
            case ErrorCode.LexerInvalidStringPrefix => "E0023"
            case ErrorCode.LexerConflictingSourceEncoding => "E0024"
            case ErrorCode.LexerZeroWidthCharacter => "E0025"
            case ErrorCode.LexerFloatingPointFormat => "E0026"
            case ErrorCode.LexerRadixLiteralFormat => "E0027"
            case ErrorCode.LexerLiteralTooLong => "E0028"
            case ErrorCode.LexerTruncatedMultibyte => "E0029"
            // Parser
            case ErrorCode.ParserUnterminatedString => "E0101"
            case ErrorCode.ParserUnexpectedToken => "E0102"
            case ErrorCode.ParserMissingSemicolon => "E0103"
            case ErrorCode.ParserMismatchedBracket => "E0104"
            case ErrorCode.ParserInvalidExpression => "E0105"
            case ErrorCode.ParserMissingColon => "E0106"
            case ErrorCode.ParserDuplicateModifier => "E0107"
            case ErrorCode.ParserInvalidDeclaration => "E0108"
            case ErrorCode.ParserTrailingComma => "E0109"
            case ErrorCode.ParserUnexpectedEOF => "E0110"
            case ErrorCode.ParserMissingOperand => "E0111"
            case ErrorCode.ParserInvalidModifierOrder => "E0112"
            case ErrorCode.ParserDuplicateImport => "E0113"
            case ErrorCode.ParserUnexpectedExpressionStatement => "E0114"
            case ErrorCode.ParserIllegalTopLevelStatement => "E0115"
            case ErrorCode.ParserExpectedIdentifier => "E0116"
            case ErrorCode.ParserMissingTypeAnnotation => "E0117"
            case ErrorCode.ParserUnclosedTypeParams => "E0118"
            case ErrorCode.ParserDuplicateParameterName => "E0119"
            case ErrorCode.ParserMisplacedAnnotation => "E0120"
            case ErrorCode.ParserInvalidGenericConstraint => "E0121"
            case ErrorCode.ParserMissingReturnType => "E0122"
            case ErrorCode.ParserDanglingDocComment => "E0123"
            case ErrorCode.ParserInvalidAttributeTarget => "E0124"
            case ErrorCode.ParserConflictingMutability => "E0125"
            case ErrorCode.ParserInvalidPattern => "E0126"
            case ErrorCode.ParserInvalidMemberDecl => "E0127"
            case ErrorCode.ParserInvalidLambdaSyntax => "E0128"
            case ErrorCode.ParserInvalidStringInterpolation => "E0129"
            case ErrorCode.ParserMissingElseBranch => "E0130"
            case ErrorCode.ParserOperatorPrecedenceAmbiguous => "E0131"
            // Sema
            case ErrorCode.SemaUndefinedSymbol => "E1001"
            case ErrorCode.SemaRedeclaration => "E1002"
            case ErrorCode.SemaInvalidArgumentCount => "E1003"
            case ErrorCode.SemaImmutableAssignment => "E1004"
            case ErrorCode.SemaUseBeforeDeclaration => "E1005"
            case ErrorCode.SemaInvalidBreakContinue => "E1006"
            case ErrorCode.SemaMissingReturn => "E1007"
            case ErrorCode.SemaUnreachableCode => "E1008"
            case ErrorCode.SemaShadowedVariable => "E1009"
            case ErrorCode.SemaDeprecatedUsage => "E1010"
            case ErrorCode.SemaUninitializedConstant => "E1011"
            case ErrorCode.SemaDuplicateImportItem => "E1012"
            case ErrorCode.SemaIllegalRecursion => "E1013"
            case ErrorCode.SemaNonExhaustiveMatch => "E1014"
            case ErrorCode.SemaUnreachableMatchArm => "E1015"
            case ErrorCode.SemaTypeInferenceFailed => "E1016"
            case ErrorCode.SemaMutableOpOnImmutable => "E1017"
            case ErrorCode.SemaOperatorOverloadMismatch => "E1018"
            case ErrorCode.SemaInterfaceDefaultConflict => "E1019"
            case ErrorCode.SemaUnusedConstructorParam => "E1020"
            case ErrorCode.SemaUnreachableLoop => "E1021"
            case ErrorCode.SemaInvalidCastSafety => "E1022"
            case ErrorCode.SemaMissingMainFunction => "E1023"
            case ErrorCode.SemaConflictingTraitImpl => "E1024"
            case ErrorCode.SemaUnsafeEscape => "E1025"
            case ErrorCode.SemaTraitMethodMissing => "E1026"
            case ErrorCode.SemaClosureCaptureError => "E1027"
            case ErrorCode.SemaNoViableOverload => "E1028"
            case ErrorCode.SemaNamedArgumentMismatch => "E1029"
            case ErrorCode.SemaMutabilityPropagation => "E1030"
            case ErrorCode.SemaInvalidAsyncContext => "E1031"
            case ErrorCode.SemaCyclicInitialization => "E1032"
            // Type
            case ErrorCode.TypeMismatch => "E2001"
            case ErrorCode.TypeInferenceFailed => "E2002"
            case ErrorCode.TypeInvalidCast => "E2003"
            case ErrorCode.TypeAmbiguousOverload => "E2004"
            case ErrorCode.TypeMissingGenericArgument => "E2005"
            case ErrorCode.TypeConstraintViolation => "E2006"
            case ErrorCode.TypeRecursiveAlias => "E2007"
            case ErrorCode.TypeUnsizedInStack => "E2008"
            case ErrorCode.TypeImplicitConversionLossy => "E2009"
            case ErrorCode.TypeIncompatibleVariance => "E2010"
            case ErrorCode.TypeInvalidVariancePosition => "E2011"
            case ErrorCode.TypeWhereClauseViolation => "E2012"
            case ErrorCode.TypeClosureTypeMismatch => "E2013"
            case ErrorCode.TypeBorrowConflict => "E2014"
            case ErrorCode.TypeCyclicInference => "E2015"
            case ErrorCode.TypeCovariantReturnInvalid => "E2016"
            case ErrorCode.TypeEmptyEnum => "E2017"
            case ErrorCode.TypeUnsafeTraitUpcast => "E2018"
            case ErrorCode.TypeArgumentCountMismatch => "E2019"
            case ErrorCode.TypeCyclicInterfaceInheritance => "E2020"
            case ErrorCode.TypeIncompatibleReturn => "E2021"
            case ErrorCode.TypeUnresolvedAssociatedType => "E2022"
            case ErrorCode.TypeInvalidSelfType => "E2023"
            case ErrorCode.TypeHigherRankedBound => "E2024"
            case ErrorCode.TypePhantomTypeMismatch => "E2025"
            case ErrorCode.TypeConstEvalFailure => "E2026"
            case ErrorCode.TypeConstOverflow => "E2027"
            case ErrorCode.TypeNullableUnwrap => "E2028"
            case ErrorCode.TypeTupleElementMismatch => "E2029"
            case ErrorCode.TypeFunctionPointerMismatch => "E2030"
            case ErrorCode.TypeLiteralAmbiguity => "E2031"
            // Resolution
            case ErrorCode.ResolutionModuleNotFound => "E3001"
            case ErrorCode.ResolutionImportNotFound => "E3002"
            case ErrorCode.ResolutionAmbiguousImport => "E3003"
            case ErrorCode.ResolutionPrivateAccess => "E3004"
            case ErrorCode.ResolutionUnresolvedPath => "E3005"
            case ErrorCode.ResolutionCircularImport => "E3006"
            case ErrorCode.ResolutionTraitNotImplemented => "E3007"
            case ErrorCode.ResolutionInvalidSuperCall => "E3008"
            case ErrorCode.ResolutionNameClash => "E3009"
            case ErrorCode.ResolutionVersionMismatch => "E3010"
            case ErrorCode.ResolutionMacroExpansionFailed => "E3011"
            case ErrorCode.ResolutionCyclicTypeAlias => "E3012"
            case ErrorCode.ResolutionMissingExport => "E3013"
            case ErrorCode.ResolutionTransitiveVisibility => "E3014"
            case ErrorCode.ResolutionUncoveredCfgBranch => "E3015"
            case ErrorCode.ResolutionMacroImportNotFound => "E3016"
            case ErrorCode.ResolutionReexportConflict => "E3017"
            case ErrorCode.ResolutionPackageInitCycle => "E3018"
            case ErrorCode.ResolutionUndefinedCfgSymbol => "E3019"
            case ErrorCode.ResolutionVisibilityLeak => "E3020"
            case ErrorCode.ResolutionConflictingImportAlias => "E3021"
            case ErrorCode.ResolutionUnstableApi => "E3022"
            case ErrorCode.ResolutionMissingFeatureFlag => "E3023"
            case ErrorCode.ResolutionSymbolPrecedence => "E3024"
            case ErrorCode.ResolutionOrphanedImpl => "E3025"
            case ErrorCode.ResolutionGlobImportAmbiguous => "E3026"
            case ErrorCode.ResolutionMacroHygiene => "E3027"
            case ErrorCode.ResolutionVisibilityTierViolation => "E3028"
            case ErrorCode.ResolutionTraitMethodConflict => "E3029"
            case ErrorCode.ResolutionCfgExpressionError => "E3030"
            // Codegen
            case ErrorCode.CodegenUnsupportedConstruct => "E4001"
            case ErrorCode.CodegenStackOverflowRisk => "E4002"
            case ErrorCode.CodegenInvalidIntrinsic => "E4003"
            case ErrorCode.CodegenLinkageError => "E4004"
            case ErrorCode.CodegenABIIncompatible => "E4005"
            case ErrorCode.CodegenOptimizationFailed => "E4006"
            case ErrorCode.CodegenUninitializedUse => "E4007"
            case ErrorCode.CodegenLargeConstant => "E4008"
            case ErrorCode.CodegenTargetNotSupported => "E4009"
            case ErrorCode.CodegenEmissionInterrupted => "E4010"
            case ErrorCode.CodegenRegisterAllocationFailed => "E4011"
            case ErrorCode.CodegenUnsupportedTailCall => "E4012"
            case ErrorCode.CodegenInlineFailed => "E4013"
            case ErrorCode.CodegenConstFoldOverflow => "E4014"
            case ErrorCode.CodegenTargetFeatureUnsupported => "E4015"
            case ErrorCode.CodegenUnreachableBlock => "E4016"
            case ErrorCode.CodegenVtableOverflow => "E4017"
            case ErrorCode.CodegenLargeEhTable => "E4018"
            case ErrorCode.CodegenInvalidInlineAsm => "E4019"
            case ErrorCode.CodegenAlignmentUnsupported => "E4020"
            case ErrorCode.CodegenUnsupportedSimd => "E4021"
            case ErrorCode.CodegenDebugInfoFailed => "E4022"
            case ErrorCode.CodegenSectionTooLarge => "E4023"
            case ErrorCode.CodegenRelocUnsupported => "E4024"
            case ErrorCode.CodegenProfileInstrumentFailed => "E4025"
            case ErrorCode.CodegenMonomorphizationFailed => "E4026"
            case ErrorCode.CodegenLinkerFailed => "E4027"
            case ErrorCode.CodegenBuiltinUnsupported => "E4028"
            case ErrorCode.CodegenCallingConventionMismatch => "E4029"
            case ErrorCode.CodegenTlsUnsupported => "E4030"
            case ErrorCode.CodegenFfiAbiMismatch => "E4031"
            case ErrorCode.CodegenInvalidTargetTriple => "E4032"
            case ErrorCode.CodegenDebugFormatError => "E4033"
            // Runtime
            case ErrorCode.RuntimeNullDereference => "E5001"
            case ErrorCode.RuntimeIndexOutOfBounds => "E5002"
            case ErrorCode.RuntimeDivisionByZero => "E5003"
            case ErrorCode.RuntimeStackOverflow => "E5004"
            case ErrorCode.RuntimeIntegerOverflow => "E5005"
            case ErrorCode.RuntimeInvalidCast => "E5006"
            case ErrorCode.RuntimeResourceExhausted => "E5007"
            case ErrorCode.RuntimeDeadlockDetected => "E5008"
            case ErrorCode.RuntimeAssertionFailed => "E5009"
            case ErrorCode.RuntimeUnwindAborted => "E5010"
            case ErrorCode.RuntimeUseAfterMove => "E5011"
            case ErrorCode.RuntimeDataRace => "E5012"
            case ErrorCode.RuntimeBufferOverflow => "E5013"
            case ErrorCode.RuntimeInfiniteRecursion => "E5014"
            case ErrorCode.RuntimeFFICallFailed => "E5015"
            case ErrorCode.RuntimeDestructorThrow => "E5016"
            case ErrorCode.RuntimeDanglingWeakRef => "E5017"
            case ErrorCode.RuntimeNegativeIndex => "E5018"
            case ErrorCode.RuntimeInvalidSuspend => "E5019"
            case ErrorCode.RuntimeAlignmentFault => "E5020"
            case ErrorCode.RuntimeLeakedResource => "E5021"
            case ErrorCode.RuntimeContractViolation => "E5022"
            case ErrorCode.RuntimeTimeoutExceeded => "E5023"
            case ErrorCode.RuntimeStackCorruption => "E5024"
            case ErrorCode.RuntimeUnknownError => "E5025"
            case ErrorCode.RuntimeDoubleFree => "E5026"
            case ErrorCode.RuntimeUseAfterFree => "E5027"
            case ErrorCode.RuntimeChannelClosed => "E5028"
            case ErrorCode.RuntimeAtomicMisuse => "E5029"
            case ErrorCode.RuntimeThreadLimitExceeded => "E5030"
            case ErrorCode.RuntimeMemoryMapFailed => "E5031"
            // System
            case ErrorCode.SystemInternalError => "E9001"
            case ErrorCode.SystemIOError => "E9002"
            case ErrorCode.SystemOutOfMemory => "E9003"
            case ErrorCode.SystemTimeout => "E9004"
            case ErrorCode.SystemInvalidConfig => "E9005"
            case ErrorCode.SystemPluginLoadFailed => "E9006"
            case ErrorCode.SystemCacheCorrupted => "E9007"
            case ErrorCode.SystemNetworkError => "E9008"
            case ErrorCode.SystemPermissionDenied => "E9009"
            case ErrorCode.SystemUnknown => "E9010"
            case ErrorCode.SystemConcurrencyLimit => "E9011"
            case ErrorCode.SystemDiagnosticSerializeFailed => "E9012"
            case ErrorCode.SystemIncompatibleCompilerVersion => "E9013"
            case ErrorCode.SystemMissingEnvVar => "E9014"
            case ErrorCode.SystemInternalAssertion => "E9015"
            case ErrorCode.SystemTempDirUnwritable => "E9016"
            case ErrorCode.SystemOutputChannelBusy => "E9017"
            case ErrorCode.SystemPluginVersionMismatch => "E9018"
            case ErrorCode.SystemInterrupted => "E9019"
            case ErrorCode.SystemUnknownInternal => "E9020"
            case ErrorCode.SystemResourceLimit => "E9021"
            case ErrorCode.SystemFeatureUnsupported => "E9022"
            case ErrorCode.SystemFatalSignal => "E9023"
            case ErrorCode.SystemUnrecoverableState => "E9024"
            case ErrorCode.SystemShutdownRequested => "E9025"
            case ErrorCode.SystemIncrementalCacheInvalidated => "E9026"
            case ErrorCode.SystemRemoteBuildFailed => "E9027"
            case ErrorCode.SystemSandboxLimitExceeded => "E9028"
        }
    }

    /// 所属类别（Lexer/Parser/Sema/Type/Resolution/Codegen/Runtime/System）
    public func category(): ErrorCategory {
        return META.get(this.code()).getOrThrow().category
    }

    /// 严重级别（Fatal/Error/Warning）
    public func severity(): Severity {
        return META.get(this.code()).getOrThrow().severity
    }

    /// 消息模板（支持 {key} 参数化占位符，由 fromCode 填充）
    public func template(): String {
        return META.get(this.code()).getOrThrow().template
    }

    /// 默认修复建议（约 60% 的错误码提供一键修复；设计文档按类别给出覆盖率）
    public func defaultFix(): Option<FixSuggestion> {
        return META.get(this.code()).getOrThrow().fix
    }

    /// 人类可读描述（取消息模板，无参数时即为最终文案）
    public func description(): String {
        return this.template()
    }

    public operator func ==(other: ErrorCode): Bool {
        return this.code() == other.code()
    }
}

/// 用参数填充消息模板中的 {key} 占位符
func fillTemplate(tpl: String, params: Map<String, String>): String {
    var result = tpl
    for ((k, v) in params) {
        result = result.replace("{" + k + "}", v)
    }
    return result
}

/// 通过错误码直接构造一条结构化诊断（应用默认 severity / fix / 模板）
public func fromCode(code: ErrorCode, span: Span, params: Map<String, String>): DiagnosticMessage {
    let meta = META.get(code.code()).getOrThrow()
    let msg = fillTemplate(meta.template, params)
    return DiagnosticMessage(
        code: code,
        message: msg,
        span: span,
        severity: meta.severity.label(),
        fix: meta.fix,
        related: ArrayList<RelatedInfo>(),
        candidates: None,
        rootCause: ""
    )
}

/// fromCode 的无参数重载（模板无占位符时使用）
public func fromCode(code: ErrorCode, span: Span): DiagnosticMessage {
    return fromCode(code, span, HashMap<String, String>())
}

/// 富诊断构造：按角色映射填充 related notes（B 方案）。spans 为角色名 -> 真实 Span 的解析表。
/// 该重载不破坏既有两参数调用：未提供 spans 时相关位置退化为零位置备注。
public func fromCode(code: ErrorCode, span: Span, params: Map<String, String>,
    spans: Map<String, Span>): DiagnosticMessage {
    let meta = META.get(code.code()).getOrThrow()
    let msg = fillTemplate(meta.template, params)
    let related = meta.relatedNotes({role => spans.get(role)})
    return DiagnosticMessage(
        code: code,
        message: msg,
        span: span,
        severity: meta.severity.label(),
        fix: meta.fix,
        related: related,
        candidates: None,
        rootCause: ""
    )
}

/// 核心诊断消息结构
public struct DiagnosticMessage {
    /// 错误码
    public var code: ErrorCode
    /// 严重级别（fatal/error/warning）
    public var severity: String
    /// 诊断消息文本
    public var message: String
    /// 源码位置范围
    public var span: Span
    /// 修复建议（None 表示无建议）
    public var fix: Option<FixSuggestion>
    /// 关联位置信息列表
    public var related: List<RelatedInfo>
    /// 候选符号列表（None 表示无候选），元素为结构化 Candidate{name,kind}
    public var candidates: Option<List<Candidate>>
    /// 结构化根本原因（从 message 文本抽离，便于工具/IDE 机器消费）
    public var rootCause: String

    /// 构造函数：最小参数（默认 severity 为 "error"）
    public init(code!: ErrorCode, message!: String, span!: Span) {
        this.code = code
        this.severity = "error"
        this.message = message
        this.span = span
        this.fix = None
        this.related = ArrayList<RelatedInfo>()
        this.candidates = None
        this.rootCause = ""
    }

    public init(code!: ErrorCode, message!: String, span!: Span, severity!: String) {
        this.code = code
        this.severity = severity
        this.message = message
        this.span = span
        this.fix = None
        this.related = ArrayList<RelatedInfo>()
        this.candidates = None
        this.rootCause = ""
    }

    public init(code!: ErrorCode, message!: String, span!: Span, severity!: String, fix!: Option<FixSuggestion>) {
        this.code = code
        this.severity = severity
        this.message = message
        this.span = span
        this.fix = fix
        this.related = ArrayList<RelatedInfo>()
        this.candidates = None
        this.rootCause = ""
    }

    public init(code!: ErrorCode, message!: String, span!: Span, severity!: String, fix!: Option<FixSuggestion>,
        related!: List<RelatedInfo>) {
        this.code = code
        this.severity = severity
        this.message = message
        this.span = span
        this.fix = fix
        this.related = related
        this.candidates = None
        this.rootCause = ""
    }

    public init(code!: ErrorCode, message!: String, span!: Span, severity!: String, fix!: Option<FixSuggestion>,
        related!: List<RelatedInfo>, candidates!: Option<List<Candidate>>, rootCause!: String) {
        this.code = code
        this.severity = severity
        this.message = message
        this.span = span
        this.fix = fix
        this.related = related
        this.candidates = candidates
        this.rootCause = rootCause
    }
}

/// 获取错误码字符串
public func getCodeStr(code: ErrorCode): String {
    return code.code()
}

