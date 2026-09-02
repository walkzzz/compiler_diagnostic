package compiler_diagnostic.ut
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.benchmark.*


@Test
class BenchmarkReportTest {
    @TestCase func testBenchmarkResultInit(): Unit {
        let result = BenchmarkResult(50.0, 25.0)
        @Expect(result.elapsedMs, 50.0)
        @Expect(result.peakMemoryMB, 25.0)
    }

    @TestCase func testBenchmarkReportSummary(): Unit {
        let report = BenchmarkReport(1.0, 1.0, true)
        let summary = report.summary()
        @Expect(summary.contains("时间比="), true)
        @Expect(summary.contains("内存比="), true)
        @Expect(summary.contains("x"), true)
    }

    @TestCase func testCompareWithBaseline(): Unit {
        let perf = PerfBenchmark()
        let current = BenchmarkResult(100.0, 50.0)
        let baseline = BenchmarkResult(100.0, 50.0)
        let report = perf.compareWithBaseline(current, baseline)
        @Expect(report.timeRatio, 1.0)
        @Expect(report.memRatio, 1.0)
        @Expect(report.passed, true)
    }

    @TestCase func testCompareWithBaselineWorse(): Unit {
        let perf = PerfBenchmark()
        let current = BenchmarkResult(110.0, 55.0)
        let baseline = BenchmarkResult(100.0, 50.0)
        let report = perf.compareWithBaseline(current, baseline)
        @Expect(report.passed, false)
    }

    @TestCase func testCompareWithBaselineBetter(): Unit {
        let perf = PerfBenchmark()
        let current = BenchmarkResult(90.0, 45.0)
        let baseline = BenchmarkResult(100.0, 50.0)
        let report = perf.compareWithBaseline(current, baseline)
        @Expect(report.passed, true)
    }
}
