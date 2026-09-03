package compiler_diagnostic

import compiler_diagnostic.output.JSONDiagnosticOutput
import compiler_diagnostic.output.TextOutput
import compiler_diagnostic.benchmark.PerfBenchmark
import compiler_diagnostic.benchmark.BenchmarkResult
import compiler_diagnostic.cli.*

/// 性能基线（由 `cjpm run` 真实测量后固化，用于回归检测；timeRatio <= 1.05 视为通过）
/// 实测：elapsedMs≈0.0（MonoTime 亚毫秒分辨率，操作过快显示为 0）、peakMemoryMB≈0.041
/// 这里取略高于实测的保守基线（含余量），确保波动时 timeRatio 仍 <= 1.05。
let PERF_BASELINE: BenchmarkResult = BenchmarkResult(0.001, 0.041)

main(args: Array<String>): Int64 {
    let mode = parseArgs(args)
    let diagnostics = generateSampleDiagnostics()

    if (mode == "json") {
        let jsonOutput = JSONDiagnosticOutput()
        let json = jsonOutput.output(diagnostics)
        println(json)
    } else if (mode == "lsp") {
        let jsonOutput = JSONDiagnosticOutput()
        let lsp = jsonOutput.outputLsp(diagnostics)
        println(lsp)
    } else {
        let textOutput = TextOutput()
        let text = textOutput.output(diagnostics)
        println(text)
    }

    // 运行性能基准测试，并与固化基线对比（P1-6 真实性能基线）
    let benchmark = PerfBenchmark()
    let current = benchmark.runBenchmark()
    let report = benchmark.compareWithBaseline(current, PERF_BASELINE)
    let status = if (report.passed) { " (通过)" } else { " (回归!)" }
    println("性能基准: elapsedMs=" + current.elapsedMs.toString() +
        ", peakMemoryMB=" + current.peakMemoryMB.toString() +
        ", timeRatio=" + report.timeRatio.toString() + "x, memRatio=" + report.memRatio.toString() + "x" + status)

    return if (report.passed) { 0 } else { 1 }
}
