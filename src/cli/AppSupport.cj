package compiler_diagnostic.cli
import std.collection.*
import compiler_diagnostic.diagnostics.*

/// 命令行参数解析
/// 支持模式：--diagnostic=text（默认） | --diagnostic=json | --diagnostic=lsp
public func parseArgs(args: Array<String>): String {
    for (arg in args) {
        if (arg == "--diagnostic=json") {
            return "json"
        }
        if (arg == "--diagnostic=lsp") {
            return "lsp"
        }
        if (arg == "--diagnostic=text") {
            return "text"
        }
    }
    return "text"
}

/// 生成示例诊断消息
public func generateSampleDiagnostics(): List<DiagnosticMessage> {
    let loc1 = SourceLoc(line: 10, column: 5, file: "test.cj")
    let loc2 = SourceLoc(line: 10, column: 20, file: "test.cj")
    let span1 = Span(start: loc1, end: loc2)

    let parserDiag = ParserDiagnostic()
    let semaDiag = SemaDiagnostic()

    let diag1 = parserDiag.reportUnterminatedString(span: span1)
    let diag2 = parserDiag.reportTypeMismatch(span: span1, expectedType: "Int", actualType: "String")
    let diag3 = parserDiag.reportUndefinedIdentifier(span: span1, identifier: "undefVar", candidates: ArrayList<Candidate>([Candidate(name: "var1", kind: "variable"), Candidate(name: "var2", kind: "variable")]))
    let diag4 = parserDiag.reportBracketMismatch(span: span1)
    let diag5 = parserDiag.reportExprSyntaxError(span: span1)
    let diag6 = semaDiag.reportTypeCheckFail(span: span1, expectedType: "Int", actualType: "String",
        rootCause: "类型转换失败")
    let diag7 = semaDiag.reportGenericInstantiateFail(span: span1, genericName: "List<T>",
        constraintViolation: "类型 T 不满足约束")
    let diag8 = semaDiag.reportOverloadAmbiguity(span: span1, funcName: "foo", candidates: ArrayList<Candidate>([Candidate(name: "foo(Int)", kind: "function"), Candidate(name: "foo(String)", kind: "function")]))
    let diag9 = semaDiag.reportVisibilityFail(span: span1, memberName: "privateField", accessPath: "公共访问私有成员")

    let result: List<DiagnosticMessage> = ArrayList<DiagnosticMessage>()
    result.add(diag1)
    result.add(diag2)
    result.add(diag3)
    result.add(diag4)
    result.add(diag5)
    result.add(diag6)
    result.add(diag7)
    result.add(diag8)
    result.add(diag9)

    // ===== 扩展样例：覆盖全部 8 大类（Lexer/Parser/Sema/Type/Resolution/Codegen/Runtime/System） =====
    // 使用 fromCode 工厂 + 参数化模板，展示结构化诊断数据模型对全流水线的统一描述能力。

    // Lexer 词法（E00xx）：参数化模板 {escape}
    let locLexer = SourceLoc(line: 3, column: 10, file: "lexer_sample.cj")
    let pLexer = HashMap<String, String>()
    pLexer["escape"] = "\\x"
    result.add(fromCode(ErrorCode.UnterminatedString, Span(start: locLexer, end: locLexer), pLexer))

    // Type 类型系统（E20xx）：参数化模板 {name}
    let locType = SourceLoc(line: 5, column: 2, file: "type_sample.cj")
    let pType = HashMap<String, String>()
    pType["name"] = "value"
    result.add(fromCode(ErrorCode.TypeInferenceFailed, Span(start: locType, end: locType), pType))

    // Resolution 名称解析（E30xx）：参数化模板 {name}
    let locRes = SourceLoc(line: 1, column: 1, file: "main_sample.cj")
    let pRes = HashMap<String, String>()
    pRes["name"] = "math"
    result.add(fromCode(ErrorCode.UnresolvedImport, Span(start: locRes, end: locRes), pRes))

    // Codegen 代码生成（E40xx）：参数化模板 {construct}
    let locCg = SourceLoc(line: 8, column: 15, file: "codegen_sample.cj")
    let pCg = HashMap<String, String>()
    pCg["construct"] = "goto"
    result.add(fromCode(ErrorCode.InternalCompilerError, Span(start: locCg, end: locCg), pCg))

    // Runtime 运行时（E50xx）：Fatal 级，无参模板
    let locRt = SourceLoc(line: 12, column: 4, file: "runtime_sample.cj")
    result.add(fromCode(ErrorCode.NullPointerDereference, Span(start: locRt, end: locRt)))

    // System 系统/内部（E90xx）：Fatal 级，无参模板
    let locSys = SourceLoc(line: 0, column: 0, file: "internal_sample.cj")
    result.add(fromCode(ErrorCode.FileNotFound, Span(start: locSys, end: locSys)))

    return result
}

// ===== v1.2 子命令分发（run / diagnose） =====

/// 子命令分发结果
public enum Subcommand {
    | Default
    | Run(RunArgs)
    | Diagnose(DiagnoseArgs)
    | FromCjc(FromCjcArgs)
}

/// run 子命令参数
public struct RunArgs {
    public var sourceFile: String
    public var exportTrace: String
    public init(sourceFile!: String, exportTrace!: String) {
        this.sourceFile = sourceFile
        this.exportTrace = exportTrace
    }
}

/// diagnose 子命令参数
public struct DiagnoseArgs {
    public var tracePath: String
    public init(tracePath!: String) {
        this.tracePath = tracePath
    }
}

/// from-cjc 子命令参数：读取 cjc 文本诊断输出文件，产出结构化 ErrorCode JSON
public struct FromCjcArgs {
    public var inputFile: String
    public init(inputFile!: String) {
        this.inputFile = inputFile
    }
}

/// 顶部分发：args[0]=="run"/"diagnose"/"from-cjc" 走子命令，否则 Default（保留旧行为）
public func dispatchSubcommand(args: Array<String>): Subcommand {
    if (args.size > 0) {
        if (args[0] == "run") {
            return Subcommand.Run(parseRunArgs(args))
        } else if (args[0] == "diagnose") {
            return Subcommand.Diagnose(parseDiagnoseArgs(args))
        } else if (args[0] == "from-cjc") {
            return Subcommand.FromCjc(parseFromCjcArgs(args))
        }
    }
    return Subcommand.Default
}

/// 解析 run 子命令剩余参数：位置源文件 + --export-trace <path>
public func parseRunArgs(args: Array<String>): RunArgs {
    var sourceFile = ""
    var exportTrace = ""
    var i = 1
    while (i < args.size) {
        if (args[i] == "--export-trace") {
            if (i + 1 < args.size) {
                exportTrace = args[i + 1]
                i = i + 2
            } else {
                i = i + 1
            }
        } else {
            if (sourceFile == "") {
                sourceFile = args[i]
            }
            i = i + 1
        }
    }
    return RunArgs(sourceFile: sourceFile, exportTrace: exportTrace)
}

/// 解析 diagnose 子命令：--trace <path>
public func parseDiagnoseArgs(args: Array<String>): DiagnoseArgs {
    var tracePath = ""
    var i = 1
    while (i < args.size) {
        if (args[i] == "--trace") {
            if (i + 1 < args.size) {
                tracePath = args[i + 1]
                i = i + 2
            } else {
                i = i + 1
            }
        } else {
            i = i + 1
        }
    }
    return DiagnoseArgs(tracePath: tracePath)
}

/// 解析 from-cjc 子命令：位置参数为 cjc 输出文件路径
public func parseFromCjcArgs(args: Array<String>): FromCjcArgs {
    var inputFile = ""
    var i = 1
    while (i < args.size) {
        if (inputFile == "") {
            inputFile = args[i]
        }
        i = i + 1
    }
    return FromCjcArgs(inputFile: inputFile)
}
