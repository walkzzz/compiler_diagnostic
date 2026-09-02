package compiler_diagnostic.benchmark

/// 性能测试结果
public struct BenchmarkResult {
    public var elapsedMs: Float64
    public var peakMemoryMB: Float64

    public init(elapsedMs: Float64, peakMemoryMB: Float64) {
        if (elapsedMs < 0.0) {
            throw Exception("elapsedMs must be non-negative, got: " + elapsedMs.toString())
        }
        if (peakMemoryMB < 0.0) {
            throw Exception("peakMemoryMB must be non-negative, got: " + peakMemoryMB.toString())
        }
        this.elapsedMs = elapsedMs
        this.peakMemoryMB = peakMemoryMB
    }

    /// 生成人类可读的基准结果摘要
    public func summary(): String {
        let sb = StringBuilder()
        sb.append("耗时=")
        sb.append(this.elapsedMs.toString())
        sb.append("ms, 峰值内存=")
        sb.append(this.peakMemoryMB.toString())
        sb.append("MB")
        return sb.toString()
    }
}

/// 性能对比报告
public struct BenchmarkReport {
    public var timeRatio: Float64
    public var memRatio: Float64
    public var passed: Bool

    public init(timeRatio: Float64, memRatio: Float64, passed: Bool) {
        this.timeRatio = timeRatio
        this.memRatio = memRatio
        this.passed = passed
    }

    public func summary(): String {
        let sb = StringBuilder()
        sb.append("性能测试通过：时间比=")
        sb.append(this.timeRatio.toString())
        sb.append("x, 内存比=")
        sb.append(this.memRatio.toString())
        sb.append("x")
        return sb.toString()
    }
}
