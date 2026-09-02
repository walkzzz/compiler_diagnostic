package compiler_diagnostic

import compiler_diagnostic.output.JSONDiagnosticOutput
import compiler_diagnostic.output.TextOutput
import compiler_diagnostic.benchmark.PerfBenchmark
import compiler_diagnostic.cli.*

main(args: Array<String>): Int64 {
    let mode = parseArgs(args)
    let diagnostics = generateSampleDiagnostics()

    if (mode == "json") {
        let jsonOutput = JSONDiagnosticOutput()
        let json = jsonOutput.output(diagnostics)
        println(json)
    } else {
        let textOutput = TextOutput()
        let text = textOutput.output(diagnostics)
        println(text)
    }

    // 运行性能基准测试
    let benchmark = PerfBenchmark()
    let result = benchmark.runBenchmark()
    println("性能基准: elapsedMs=" + result.elapsedMs.toString() + ", peakMemoryMB=" + result.peakMemoryMB.toString())

    return 0
}
