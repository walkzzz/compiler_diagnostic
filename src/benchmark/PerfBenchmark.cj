package compiler_diagnostic.benchmark
import std.collection.*
import std.time.*

import compiler_diagnostic.diagnostics.DiagnosticMessage
import compiler_diagnostic.diagnostics.DiagnosticBuilder
import compiler_diagnostic.diagnostics.Span
import compiler_diagnostic.diagnostics.SourceLoc
import compiler_diagnostic.diagnostics.ErrorCode
import compiler_diagnostic.output.JSONDiagnosticOutput
import compiler_diagnostic.output.TextOutput

/// 性能基准测试框架 - 提供真实的性能测量
public class PerfBenchmark {
    /// 执行性能基准测试
    /// 测量诊断消息生成、JSON序列化、文本格式化的性能
    public func runBenchmark(): BenchmarkResult {
        let start = MonoTime.now()
        let diagnostics = this.generateSampleDiagnostics()
        let genMs = Float64((MonoTime.now() - start).toMilliseconds())

        let jsonStart = MonoTime.now()
        let jsonOutput = JSONDiagnosticOutput()
        let jsonStr = jsonOutput.output(diagnostics)
        let jsonMs = Float64((MonoTime.now() - jsonStart).toMilliseconds())

        let textStart = MonoTime.now()
        let textOutput = TextOutput()
        let textStr = textOutput.output(diagnostics)
        let textMs = Float64((MonoTime.now() - textStart).toMilliseconds())

        let peakMemoryMB = this.estimateMemoryUsage(diagnostics, jsonStr, textStr)

        return BenchmarkResult(genMs + jsonMs + textMs, peakMemoryMB)
    }

    /// 生成示例诊断消息用于性能测试
    private func generateSampleDiagnostics(): List<DiagnosticMessage> {
        let result: List<DiagnosticMessage> = ArrayList<DiagnosticMessage>()
        let builder = DiagnosticBuilder(
            code: ErrorCode.ExpectedToken,
            message: "测试消息",
            span: Span(
                start: SourceLoc(line: 1, column: 0),
                end: SourceLoc(line: 1, column: 10)
            )
        )
        var i = 0
        while (i < 100) {
            result.add(builder.build())
            i = i + 1
        }
        return result
    }

    /// 估算内存使用量（MB）
    private func estimateMemoryUsage(
        diagnostics: List<DiagnosticMessage>,
        jsonOutput: String,
        textOutput: String
    ): Float64 {
        // 简单估算：诊断数量 * 每条消息大小 + 输出字符串大小
        let diagSize = 256.0  // 估算每条诊断消息约 256 字节
        let outputSize = Float64(jsonOutput.size + textOutput.size)
        return (Float64(diagnostics.size) * diagSize + outputSize) / (1024.0 * 1024.0)
    }

    /// 对比当前性能与基线性能
    public func compareWithBaseline(
        current: BenchmarkResult,
        baseline: BenchmarkResult
    ): BenchmarkReport {
        // 防止基线为 0 导致除零
        let timeRatio = if (baseline.elapsedMs > 0.0) {
            current.elapsedMs / baseline.elapsedMs
        } else {
            1.0
        }
        let memRatio = if (baseline.peakMemoryMB > 0.0) {
            current.peakMemoryMB / baseline.peakMemoryMB
        } else {
            1.0
        }
        let passed = timeRatio <= 1.05 && memRatio <= 1.05
        return BenchmarkReport(timeRatio, memRatio, passed)
    }
}
