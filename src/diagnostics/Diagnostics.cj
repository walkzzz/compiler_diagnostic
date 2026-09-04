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
    public func codePrefix(): String {
        match (this) {
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

    public init(code!: String, category!: ErrorCategory, severity!: Severity, template!: String, fix!: Option<FixSuggestion>) {
        this.code = code
        this.category = category
        this.severity = severity
        this.template = template
        this.fix = fix
    }
}

/// 全部错误码元数据表（key 为错误码字符串）
let META: Map<String, ErrorMeta> = buildMeta()

func buildMeta(): Map<String, ErrorMeta> {
    let m = HashMap<String, ErrorMeta>()
    // ---------------- Lexer 词法分析（E00xx） ----------------
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
    // ---------------- Sema 语义分析（E10xx） ----------------
    m["E1001"] = ErrorMeta(code: "E1001", category: ErrorCategory.Sema, severity: Severity.Error,
        template: "使用了未定义的符号：{name}", fix: Some(FixSuggestion(description: "检查拼写或补充定义")))
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
    // ---------------- Type 类型系统（E20xx） ----------------
    m["E2001"] = ErrorMeta(code: "E2001", category: ErrorCategory.Type, severity: Severity.Error,
        template: "类型不匹配：期望 {expected}，实际 {actual}", fix: Some(FixSuggestion(description: "强制转换或修正变量类型")))
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
    // ---------------- Resolution 名称解析（E30xx） ----------------
    m["E3001"] = ErrorMeta(code: "E3001", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "模块未找到：{name}", fix: Some(FixSuggestion(description: "检查模块路径或依赖配置")))
    m["E3002"] = ErrorMeta(code: "E3002", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "导入项不存在：{name}", fix: Some(FixSuggestion(description: "修正导入名称")))
    m["E3003"] = ErrorMeta(code: "E3003", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "导入名称冲突：{name}", fix: Some(FixSuggestion(description: "使用全限定名或别名")))
    m["E3004"] = ErrorMeta(code: "E3004", category: ErrorCategory.Resolution, severity: Severity.Error,
        template: "访问私有成员：{name}", fix: Some(FixSuggestion(description: "调整可见性或提供访问接口")))
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
    // ---------------- Codegen 代码生成（E40xx） ----------------
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
    // ---------------- Runtime 运行时（E50xx） ----------------
    m["E5001"] = ErrorMeta(code: "E5001", category: ErrorCategory.Runtime, severity: Severity.Fatal,
        template: "空指针解引用", fix: Some(FixSuggestion(description: "增加空值检查")))
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
    return m
}

/// 错误码枚举（扩展后：8 大类、共 80 个规范错误码（每类 10 个）+ 8 个向后兼容别名）
///
/// 命名规范：首字母 E + 类别号（1 位）+ 子类号（1 位）+ 序号（2 位）。
/// 旧版 9 个变体名（ParserUnterminatedString 等）保留为别名，映射至新码，旧代码无需修改即可编译。
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
    // ===== 向后兼容别名（旧版 9 个变体名，映射至新码） =====
    | ParserTypeMismatch
    | ParserExprSyntaxError
    | ParserUndefinedIdentifier
    | ParserBracketMismatch
    | SemaTypeCheckFail
    | SemaGenericInstantiateFail
    | SemaOverloadAmbiguity
    | SemaVisibilityFail

    /// 错误码字符串（如 "E2001"）
    public func code(): String {
        match (this) {
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
            // 向后兼容别名
            case ErrorCode.ParserTypeMismatch => "E2001"
            case ErrorCode.ParserExprSyntaxError => "E0105"
            case ErrorCode.ParserUndefinedIdentifier => "E1001"
            case ErrorCode.ParserBracketMismatch => "E0104"
            case ErrorCode.SemaTypeCheckFail => "E2001"
            case ErrorCode.SemaGenericInstantiateFail => "E2006"
            case ErrorCode.SemaOverloadAmbiguity => "E2004"
            case ErrorCode.SemaVisibilityFail => "E3004"
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
