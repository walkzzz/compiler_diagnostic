package examples.demo

import compiler_diagnostic.diagnostics.SourceLoc
import compiler_diagnostic.diagnostics.Span
import compiler_diagnostic.diagnostics.ParserDiagnostic
import compiler_diagnostic.diagnostics.SemaDiagnostic
import compiler_diagnostic.output.JSONDiagnosticOutput
import compiler_diagnostic.output.TextOutput
import compiler_diagnostic.benchmark.PerfBenchmark

/// 编译器诊断质量提升 - 演示程序
/// 展示诊断消息的生成、输出、性能基准
main(): Int64 {
    println("=== 编译器诊断质量提升 - 演示 ===\n")
    
    // 1. 创建示例源码位置
    let loc1 = SourceLoc(line: 10, column: 5, file: "example.cj")
    let loc2 = SourceLoc(line: 10, column: 20, file: "example.cj")
    let span = Span(start: loc1, end: loc2)
    
    // 2. 生成各种诊断消息
    let parserDiag = ParserDiagnostic()
    let semaDiag = SemaDiagnostic()
    
    let diagnostics: List<compiler_diagnostic.diagnostics.DiagnosticMessage> = ArrayList<compiler_diagnostic.diagnostics.DiagnosticMessage>([
        parserDiag.reportUnterminatedString(span: span),
        parserDiag.reportTypeMismatch(span: span, expectedType: "Int", actualType: "String"),
        parserDiag.reportUndefinedIdentifier(span: span, identifier: "myVar", candidates: ArrayList<String>(["myVar1", "myVar2"])),
        semaDiag.reportTypeCheckFail(span: span, expectedType: "Int", actualType: "String", rootCause: "类型不兼容"),
        semaDiag.reportOverloadAmbiguity(span: span, funcName: "foo", candidates: ArrayList<String>(["foo(Int)", "foo(String)"])),
    ])
    
    // 3. 文本输出演示
    println("【文本输出】")
    let textOutput = TextOutput()
    println(textOutput.output(diagnostics))
    
    // 4. JSON 输出演示
    println("\n【JSON 输出】")
    let jsonOutput = JSONDiagnosticOutput()
    let jsonStr = jsonOutput.output(diagnostics)
    println(jsonStr)
    
    // 5. 性能基准测试
    println("\n【性能基准】")
    let benchmark = PerfBenchmark()
    let result = benchmark.runBenchmark()
    println("执行时间: " + str(result.elapsedMs) + "ms")
    println("峰值内存: " + str(result.peakMemoryMB) + "MB")
    println(result.summary())
    
    println("\n=== 演示完成 ===")
    return 0
}
