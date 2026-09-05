package compiler_diagnostic

import compiler_diagnostic.output.JSONDiagnosticOutput
import compiler_diagnostic.output.TextOutput
import compiler_diagnostic.benchmark.PerfBenchmark
import compiler_diagnostic.benchmark.BenchmarkResult
import compiler_diagnostic.cli.*
import compiler_diagnostic.common.*
import compiler_diagnostic.diagnostics.*
import compiler_diagnostic.diagnostic_scheduler.DiagnosticScheduler
import compiler_diagnostic.diagnostic_scheduler.DiagnosticResult
import std.collection.*

/// 性能基线（由 `cjpm run` 真实测量后固化，用于回归检测；timeRatio <= 1.05 视为通过）
/// 实测：elapsedMs≈0.0（MonoTime 亚毫秒分辨率，操作过快显示为 0）、peakMemoryMB≈0.041
/// 这里取略高于实测的保守基线（含余量），确保波动时 timeRatio 仍 <= 1.05。
let PERF_BASELINE: BenchmarkResult = BenchmarkResult(0.001, 0.041)

main(args: Array<String>): Int64 {
    let sub = dispatchSubcommand(args)
    match (sub) {
        case Subcommand.Run(r) => runCli(r)
        case Subcommand.Diagnose(d) => diagnoseCli(d)
        case Subcommand.Default => defaultMain(args)
    }
}

/// ★ 默认路径（无子命令）★ —— 与 v1.1.x 字节级一致，确保 PERF_BASELINE 门禁不回归（A3）
func defaultMain(args: Array<String>): Int64 {
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

/// run 子命令：扫描源码 -> 导出 Trace
func runCli(r: RunArgs): Int64 {
    let res = DiagnosticScheduler.run(r.sourceFile, r.exportTrace)
    if (res.isErr()) {
        println("导出 Trace 失败: " + resultErr(res))
    }
    return match (res) {
        case Ok(_) => 0
        case Err(_) => 2
    }
}

/// diagnose 子命令：加载 Trace -> 匹配 -> 渲染
func diagnoseCli(d: DiagnoseArgs): Int64 {
    let res = DiagnosticScheduler.diagnose(d.tracePath)
    if (res.isErr()) {
        println("诊断失败: " + resultErrDiag(res))
        return 2
    }
    let result = match (res) {
        case Ok(r) => r
        case Err(_) => makeEmptyResult()
    }
    println(DiagnosticScheduler.renderText(result))
    return 0
}

// ===== 内部辅助 =====

private func resultErr(res: Result<Int64>): String {
    match (res) {
        case Ok(_) => ""
        case Err(e) => e
    }
}

private func resultErrDiag(res: Result<DiagnosticResult>): String {
    match (res) {
        case Ok(_) => ""
        case Err(e) => e
    }
}

private func makeEmptyResult(): DiagnosticResult {
    let span = Span(start: SourceLoc(line: 0, column: 0), end: SourceLoc(line: 0, column: 0))
    let msg = DiagnosticMessage(
        code: ErrorCode.SystemInternalError,
        message: "",
        span: span,
        severity: "warning",
        fix: None,
        related: ArrayList<RelatedInfo>(),
        candidates: None,
        rootCause: "")
    return DiagnosticResult(matched: false, patternId: None, message: msg, candidateCode: "")
}
