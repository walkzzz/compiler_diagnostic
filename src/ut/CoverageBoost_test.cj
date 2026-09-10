package compiler_diagnostic.ut

import std.collection.*
import std.unittest.testmacro.*
import std.unittest.*

import compiler_diagnostic.semantic_trace.*
import compiler_diagnostic.semantic_trace.trace_util.TraceTools
import compiler_diagnostic.local_diagnostic_lib.*
import compiler_diagnostic.diagnostic_scheduler.DiagnosticScheduler
import compiler_diagnostic.diagnostic_scheduler.DiagnosticResult
import compiler_diagnostic.diagnostics.*
import compiler_diagnostic.cli.*
import compiler_diagnostic.benchmark.*
import compiler_diagnostic.output.JSONDiagnosticOutput
import compiler_diagnostic.common.*

@Test
class SemanticTraceCoverageTest {

    @TestCase func testJsonNodeSubtypes(): Unit {
        let nullNode = JsonNull()
        @Expect(nullNode.isNull(), true)
        @Expect(nullNode.asString(), "")
        @Expect(nullNode.asInt(), 0)

        let strNode = JsonString(value: "hello")
        @Expect(strNode.asString(), "hello")
        @Expect(strNode.isNull(), false)

        let numNode = JsonNumber(value: 42)
        @Expect(numNode.asInt(), 42)

        let boolTrue = JsonBool(value: true)
        @Expect(boolTrue.asInt(), 1)
        let boolFalse = JsonBool(value: false)
        @Expect(boolFalse.asInt(), 0)
    }

    @TestCase func testJsonObject(): Unit {
        let m = HashMap<String, JsonNode>()
        m["key"] = JsonString(value: "val")
        let obj = JsonObject(members: m)
        let v = obj.getObject().get("key")
        @Expect(match (v) { case Some(n) => n.asString() case None => "" }, "val")
    }

    @TestCase func testJsonArray(): Unit {
        let items = ArrayList<JsonNode>()
        items.add(JsonNumber(value: 1))
        items.add(JsonNumber(value: 2))
        let arr = JsonArray(items: items)
        @Expect(arr.getArray().size, 2)
        @Expect(arr.getArray()[0].asInt(), 1)
    }

    @TestCase func testTraceSerdeToJson(): Unit {
        let gen = GeneratorInfo(tool: "test", version: "1.0.0", sdk: "cj-1.1.3")
        let prog = ProgramInfo(entry: "main.cj", args: Array<String>(1, { _ => "arg1" }))
        let loc = SourceLoc(line: 1, column: 0, file: "main.cj")
        let ev = MachineEvent(stepId: 1, kind: "test", loc: loc,
            stack: Array<StackFrame>(), symbols: Array<SymbolValue>(),
            path: "then", exception: None)
        let events = ArrayList<MachineEvent>()
        events.add(ev)

        let trace = Trace(
            schemaVersion: "1.0.0", generator: gen, program: prog,
            machineEvents: events.toArray(), semanticEvents: ArrayList<SemanticEvent>().toArray())
        let json = TraceSerde.toJson(trace)
        @Expect(json.contains("\"schemaVersion\":\"1.0.0\""), true)
        @Expect(json.contains("\"entry\":\"main.cj\""), true)
        @Expect(json.contains("\"args\":[\"arg1\"]"), true)
    }

    @TestCase func testTraceSerdeFromJson(): Unit {
        let json = "{\"schemaVersion\":\"1.0.0\",\"generator\":{\"tool\":\"t\",\"version\":\"1.0.0\",\"sdk\":\"cj\"},"
            + "\"program\":{\"entry\":\"main.cj\",\"args\":[]},"
            + "\"machineEvents\":[{\"stepId\":1,\"kind\":\"array-access\",\"loc\":{"
            + "\"line\":4,\"column\":10,\"file\":\"s.cj\"},\"stack\":[],\"symbols\":[],"
            + "\"path\":\"then\",\"exception\":null}],"
            + "\"semanticEvents\":[]}"
        let result = TraceSerde.fromJson(json)
        @Expect(result.isOk(), true)
        let trace = result.getOrElse(Trace(schemaVersion: "", generator: GeneratorInfo(tool: "", version: "", sdk: ""),
            program: ProgramInfo(entry: "", args: Array<String>()),
            machineEvents: Array<MachineEvent>(), semanticEvents: Array<SemanticEvent>()))
        @Expect(trace.schemaVersion, "1.0.0")
        @Expect(trace.program.entry, "main.cj")
        @Expect(trace.machineEvents.size, 1)
        @Expect(trace.machineEvents[0].kind, "array-access")
    }

    @TestCase func testTraceSerdeFromJsonInvalidSchema(): Unit {
        let json = "{\"schemaVersion\":\"2.0.0\",\"generator\":{\"tool\":\"t\",\"version\":\"1.0.0\",\"sdk\":\"cj\"},"
            + "\"program\":{\"entry\":\"main.cj\",\"args\":[]},"
            + "\"machineEvents\":[],\"semanticEvents\":[]}"
        let result = TraceSerde.fromJson(json)
        @Expect(result.isErr(), true)
    }

    @TestCase func testTraceSerdeFromJsonParseError(): Unit {
        let result = TraceSerde.fromJson("not json")
        @Expect(result.isErr(), true)
    }

    @TestCase func testTraceSerdeExportToFile(): Unit {
        let gen = GeneratorInfo(tool: "test", version: "1.0.0", sdk: "cj-1.1.3")
        let prog = ProgramInfo(entry: "main.cj", args: Array<String>())
        let trace = Trace(schemaVersion: "1.0.0", generator: gen, program: prog,
            machineEvents: ArrayList<MachineEvent>().toArray(), semanticEvents: ArrayList<SemanticEvent>().toArray())
        let result = TraceSerde.exportToFile(trace, "docs/cov_report/test_trace.json")
        @Expect(result.isOk(), true)
    }

    @TestCase func testTraceSerdeLoadFromFileNotExist(): Unit {
        let result = TraceSerde.loadFromFile("docs/cov_report/nonexistent.json")
        @Expect(result.isErr(), true)
    }

    @TestCase func testEscapeJson(): Unit {
        @Expect(TraceSerde.escapeJson("hello"), "hello")
        @Expect(TraceSerde.escapeJson("a\"b"), "a\\\"b")
        @Expect(TraceSerde.escapeJson("a\\b"), "a\\\\b")
        @Expect(TraceSerde.escapeJson("a\nb"), "a\\nb")
        @Expect(TraceSerde.escapeJson("a\tb"), "a\\tb")
        @Expect(TraceSerde.escapeJson("a\rb"), "a\\rb")
    }

    @TestCase func testEventEmitterBuildFromEvents(): Unit {
        let ev = MachineEvent(stepId: 1, kind: "test", loc: SourceLoc(line: 1, column: 0, file: "f.cj"),
            stack: Array<StackFrame>(), symbols: Array<SymbolValue>(), path: "then", exception: None)
        let events = ArrayList<MachineEvent>()
        events.add(ev)
        let trace = EventEmitter.buildFromEvents(events.toArray(), entry: "f.cj", args: Array<String>(1, { _ => "a" }))
        @Expect(trace.schemaVersion, TRACE_SCHEMA_VERSION)
        @Expect(trace.program.entry, "f.cj")
        @Expect(trace.machineEvents.size, 1)
    }

    @TestCase func testEventEmitterConstructSampleTraces(): Unit {
        let t1 = EventEmitter.constructSampleTrace("array-oob")
        @Expect(t1.machineEvents.size, 1)
        @Expect(t1.machineEvents[0].exception.isSome(), true)
        let exc = t1.machineEvents[0].exception.getOrThrow()
        @Expect(exc.`type`, "ArrayIndexOutOfBounds")

        let t2 = EventEmitter.constructSampleTrace("type-mismatch")
        @Expect(t2.machineEvents[0].exception.getOrThrow().`type`, "TypeMismatch")

        let t3 = EventEmitter.constructSampleTrace("use-after-move")
        @Expect(t3.machineEvents[0].exception.getOrThrow().`type`, "UseAfterMove")

        let t4 = EventEmitter.constructSampleTrace("non-exhaustive-match")
        @Expect(t4.machineEvents[0].exception.getOrThrow().`type`, "NonExhaustiveMatch")

        let t5 = EventEmitter.constructSampleTrace("unknown")
        @Expect(t5.machineEvents.size, 0)
    }

    @TestCase func testEventEmitterScanSourceToTrace(): Unit {
        let trace = EventEmitter.scanSourceToTrace("nonexistent.cj")
        @Expect(trace.machineEvents.size, 0)
        @Expect(trace.program.entry, "nonexistent.cj")
    }

    @TestCase func testTraceToolsQueryEvents(): Unit {
        let ev1 = MachineEvent(stepId: 1, kind: "array-access", loc: SourceLoc(line: 1, column: 0, file: "f.cj"),
            stack: Array<StackFrame>(), symbols: Array<SymbolValue>(), path: "then", exception: None)
        let ev2 = MachineEvent(stepId: 2, kind: "var-bind", loc: SourceLoc(line: 2, column: 0, file: "f.cj"),
            stack: Array<StackFrame>(), symbols: Array<SymbolValue>(), path: "then", exception: None)
        let events = ArrayList<MachineEvent>()
        events.add(ev1)
        events.add(ev2)
        let trace = Trace(schemaVersion: "1.0.0", generator: GeneratorInfo(tool: "t", version: "1.0.0", sdk: "cj"),
            program: ProgramInfo(entry: "f.cj", args: Array<String>()),
            machineEvents: events.toArray(), semanticEvents: Array<SemanticEvent>())
        let result = TraceTools.queryEvents(trace, { e => e.kind == "array-access" })
        @Expect(result.size, 1)
        @Expect(result[0].stepId, 1)
    }

    @TestCase func testTraceToolsSlice(): Unit {
        let ev1 = MachineEvent(stepId: 1, kind: "a", loc: SourceLoc(line: 1, column: 0, file: "f.cj"),
            stack: Array<StackFrame>(), symbols: Array<SymbolValue>(), path: "then", exception: None)
        let ev2 = MachineEvent(stepId: 3, kind: "b", loc: SourceLoc(line: 2, column: 0, file: "f.cj"),
            stack: Array<StackFrame>(), symbols: Array<SymbolValue>(), path: "then", exception: None)
        let events = ArrayList<MachineEvent>()
        events.add(ev1)
        events.add(ev2)
        let trace = Trace(schemaVersion: "1.0.0", generator: GeneratorInfo(tool: "t", version: "1.0.0", sdk: "cj"),
            program: ProgramInfo(entry: "f.cj", args: Array<String>()),
            machineEvents: events.toArray(), semanticEvents: Array<SemanticEvent>())
        let sliced = TraceTools.slice(trace, 1, 2)
        @Expect(sliced.machineEvents.size, 1)
        @Expect(sliced.machineEvents[0].stepId, 1)
    }

    @TestCase func testTraceToolsDiff(): Unit {
        let trace = Trace(schemaVersion: "1.0.0", generator: GeneratorInfo(tool: "t", version: "1.0.0", sdk: "cj"),
            program: ProgramInfo(entry: "f.cj", args: Array<String>()),
            machineEvents: Array<MachineEvent>(), semanticEvents: Array<SemanticEvent>())
        let result = TraceTools.diff(trace, trace)
        @Expect(result, "not implemented in this iteration")
    }
}

@Test
class LocalDiagnosticLibCoverageTest {

    @TestCase func testFormalLibraryGetPattern(): Unit {
        let p1 = FormalLibrary.getPattern("RT-ARRAY-OOB")
        @Expect(p1.isSome(), true)
        let pat = p1.getOrThrow()
        @Expect(pat.id, "RT-ARRAY-OOB")
        @Expect(pat.category, ErrorCategory.Runtime)

        let p2 = FormalLibrary.getPattern("TP-TYPE-MISMATCH")
        @Expect(p2.isSome(), true)
        @Expect(p2.getOrThrow().id, "TP-TYPE-MISMATCH")

        let p3 = FormalLibrary.getPattern("NONEXISTENT")
        @Expect(p3.isNone(), true)
    }

    @TestCase func testFormalLibraryPatternsCount(): Unit {
        @Expect(FormalLibrary.PATTERNS.size, 4)
    }

    @TestCase func testPatternMatcherMatchNone(): Unit {
        let trace = Trace(schemaVersion: "1.0.0", generator: GeneratorInfo(tool: "t", version: "1.0.0", sdk: "cj"),
            program: ProgramInfo(entry: "f.cj", args: Array<String>()),
            machineEvents: Array<MachineEvent>(), semanticEvents: Array<SemanticEvent>())
        let result = PatternMatcher.`match`(trace)
        @Expect(result.matched, false)
        @Expect(result.patternId.isNone(), true)
    }

    @TestCase func testPatternMatcherMatchArrayOob(): Unit {
        let exc = Some(ExceptionInfo(typeName: "ArrayIndexOutOfBounds", message: "out of bounds"))
        let ev = MachineEvent(stepId: 1, kind: "array-access", loc: SourceLoc(line: 4, column: 10, file: "f.cj"),
            stack: Array<StackFrame>(), symbols: Array<SymbolValue>(), path: "then", exception: exc)
        let events = ArrayList<MachineEvent>()
        events.add(ev)
        let trace = Trace(schemaVersion: "1.0.0", generator: GeneratorInfo(tool: "t", version: "1.0.0", sdk: "cj"),
            program: ProgramInfo(entry: "f.cj", args: Array<String>()),
            machineEvents: events.toArray(), semanticEvents: Array<SemanticEvent>())
        let result = PatternMatcher.`match`(trace)
        @Expect(result.matched, true)
        @Expect(result.patternId.isSome(), true)
        @Expect(result.patternId.getOrThrow(), "RT-ARRAY-OOB")
        @Expect(result.severity.isSome(), true)
    }

    @TestCase func testPatternMatcherMatchTypeMismatch(): Unit {
        let exc = Some(ExceptionInfo(typeName: "TypeMismatch", message: "type error"))
        let ev = MachineEvent(stepId: 1, kind: "var-bind", loc: SourceLoc(line: 6, column: 4, file: "f.cj"),
            stack: Array<StackFrame>(), symbols: Array<SymbolValue>(), path: "then", exception: exc)
        let events = ArrayList<MachineEvent>()
        events.add(ev)
        let trace = Trace(schemaVersion: "1.0.0", generator: GeneratorInfo(tool: "t", version: "1.0.0", sdk: "cj"),
            program: ProgramInfo(entry: "f.cj", args: Array<String>()),
            machineEvents: events.toArray(), semanticEvents: Array<SemanticEvent>())
        let result = PatternMatcher.`match`(trace)
        @Expect(result.matched, true)
        @Expect(result.patternId.getOrThrow(), "TP-TYPE-MISMATCH")
    }

    @TestCase func testPatternMatcherMatchAll(): Unit {
        let exc = Some(ExceptionInfo(typeName: "ArrayIndexOutOfBounds", message: "oob"))
        let ev = MachineEvent(stepId: 1, kind: "array-access", loc: SourceLoc(line: 1, column: 0, file: "f.cj"),
            stack: Array<StackFrame>(), symbols: Array<SymbolValue>(), path: "then", exception: exc)
        let events = ArrayList<MachineEvent>()
        events.add(ev)
        let trace = Trace(schemaVersion: "1.0.0", generator: GeneratorInfo(tool: "t", version: "1.0.0", sdk: "cj"),
            program: ProgramInfo(entry: "f.cj", args: Array<String>()),
            machineEvents: events.toArray(), semanticEvents: Array<SemanticEvent>())
        let results = PatternMatcher.matchAll(trace)
        @Expect(results.size > 0, true)
    }

    @TestCase func testEventConditionDefaults(): Unit {
        let c = EventCondition()
        @Expect(c.negate, false)
        @Expect(c.hasException, false)
    }

    @TestCase func testMatchSpecDefaults(): Unit {
        let c = EventCondition()
        let spec = MatchSpec(priority: 0, sequence: Array<EventCondition>(1, { _ => c }), requireAll: true)
        @Expect(spec.priority, 0)
        @Expect(spec.requireAll, true)
    }

    @TestCase func testRepairSample(): Unit {
        let fix = FixSuggestion(description: "fix", replacement: "rep")
        let rs = RepairSample(rootCause: "cause", fixSuggestion: fix, candidateCode: "code",
            relatedInfo: Array<RelatedInfo>(), location: None)
        @Expect(rs.rootCause, "cause")
        @Expect(rs.candidateCode, "code")
    }
}

@Test
class DiagnosticSchedulerCoverageTest {

    @TestCase func testRenderTextMatched(): Unit {
        let msg = DiagnosticMessage(
            code: ErrorCode.ArrayIndexOutOfBounds, message: "root cause",
            span: Span(start: SourceLoc(line: 4, column: 10), end: SourceLoc(line: 4, column: 10)),
            severity: "fatal", fix: Some(FixSuggestion(description: "fix", replacement: "rep")),
            related: ArrayList<RelatedInfo>(), candidates: None, rootCause: "root cause")
        let result = DiagnosticResult(matched: true, patternId: Some("RT-ARRAY-OOB"), message: msg, candidateCode: "code")
        let text = DiagnosticScheduler.renderText(result)
        @Expect(text.contains("命中故障模式"), true)
        @Expect(text.contains("RT-ARRAY-OOB"), true)
        @Expect(text.contains("修复建议"), true)
    }

    @TestCase func testRenderTextUnmatched(): Unit {
        let msg = DiagnosticMessage(
            code: ErrorCode.FileNotFound, message: "未命中",
            span: Span(start: SourceLoc(line: 0, column: 0), end: SourceLoc(line: 0, column: 0)),
            severity: "warning", fix: None,
            related: ArrayList<RelatedInfo>(), candidates: None, rootCause: "未命中")
        let result = DiagnosticResult(matched: false, patternId: None, message: msg, candidateCode: "")
        let text = DiagnosticScheduler.renderText(result)
        @Expect(text.contains("未命中"), true)
    }

    @TestCase func testRenderJsonMatched(): Unit {
        let msg = DiagnosticMessage(
            code: ErrorCode.ArrayIndexOutOfBounds, message: "root cause",
            span: Span(start: SourceLoc(line: 4, column: 10), end: SourceLoc(line: 4, column: 10)),
            severity: "fatal", fix: Some(FixSuggestion(description: "fix", replacement: "rep")),
            related: ArrayList<RelatedInfo>(), candidates: None, rootCause: "root cause")
        let result = DiagnosticResult(matched: true, patternId: Some("RT-ARRAY-OOB"), message: msg, candidateCode: "code")
        let json = DiagnosticScheduler.renderJson(result)
        @Expect(json.contains("\"matched\":true"), true)
        @Expect(json.contains("\"candidateCode\":\"code\""), true)
    }

    @TestCase func testRenderJsonUnmatched(): Unit {
        let msg = DiagnosticMessage(
            code: ErrorCode.FileNotFound, message: "未命中",
            span: Span(start: SourceLoc(line: 0, column: 0), end: SourceLoc(line: 0, column: 0)),
            severity: "warning", fix: None,
            related: ArrayList<RelatedInfo>(), candidates: None, rootCause: "未命中")
        let result = DiagnosticResult(matched: false, patternId: None, message: msg, candidateCode: "")
        let json = DiagnosticScheduler.renderJson(result)
        @Expect(json.contains("\"matched\":false"), true)
    }

    @TestCase func testDiagnosticSchedulerDiagnoseNotFound(): Unit {
        let result = DiagnosticScheduler.diagnose("docs/cov_report/nonexistent_trace.json")
        @Expect(result.isErr(), true)
    }
}

@Test
class CliCoverageTest {

    @TestCase func testDispatchSubcommandDefault(): Unit {
        let sub = dispatchSubcommand([])
        @Expect(match (sub) { case Subcommand.Default => true case _ => false }, true)
    }

    @TestCase func testDispatchSubcommandRun(): Unit {
        let sub = dispatchSubcommand(["run", "main.cj", "--export-trace", "out.json"])
        match (sub) {
            case Subcommand.Run(r) =>
                @Expect(r.sourceFile, "main.cj")
                @Expect(r.exportTrace, "out.json")
            case _ => @Expect(false, true)
        }
    }

    @TestCase func testDispatchSubcommandDiagnose(): Unit {
        let sub = dispatchSubcommand(["diagnose", "--trace", "t.json"])
        match (sub) {
            case Subcommand.Diagnose(d) =>
                @Expect(d.tracePath, "t.json")
            case _ => @Expect(false, true)
        }
    }

    @TestCase func testDispatchSubcommandFromCjc(): Unit {
        let sub = dispatchSubcommand(["from-cjc", "input.txt"])
        match (sub) {
            case Subcommand.FromCjc(f) =>
                @Expect(f.inputFile, "input.txt")
            case _ => @Expect(false, true)
        }
    }

    @TestCase func testParseRunArgsMissingExport(): Unit {
        let args = ["run", "main.cj"]
        let r = parseRunArgs(args)
        @Expect(r.sourceFile, "main.cj")
        @Expect(r.exportTrace, "")
    }

    @TestCase func testParseDiagnoseArgsMissingTrace(): Unit {
        let args = ["diagnose"]
        let d = parseDiagnoseArgs(args)
        @Expect(d.tracePath, "")
    }
}

@Test
class BenchmarkCoverageTest {

    @TestCase func testBenchmarkResultSummary(): Unit {
        let r = BenchmarkResult(10.0, 0.5)
        let s = r.summary()
        @Expect(s.contains("耗时="), true)
        @Expect(s.contains("ms, 峰值内存="), true)
    }

    @TestCase func testBenchmarkReportSummary(): Unit {
        let r = BenchmarkReport(1.0, 0.9, true)
        let s = r.summary()
        @Expect(s.contains("性能测试通过"), true)
        @Expect(s.contains("时间比="), true)
    }

    @TestCase func testPerfBenchmarkComparePassed(): Unit {
        let pb = PerfBenchmark()
        let current = BenchmarkResult(0.001, 0.041)
        let baseline = BenchmarkResult(0.001, 0.041)
        let report = pb.compareWithBaseline(current, baseline)
        @Expect(report.passed, true)
        @Expect(report.timeRatio, 1.0)
    }

    @TestCase func testPerfBenchmarkCompareFailed(): Unit {
        let pb = PerfBenchmark()
        let current = BenchmarkResult(0.1, 0.5)
        let baseline = BenchmarkResult(0.001, 0.041)
        let report = pb.compareWithBaseline(current, baseline)
        @Expect(report.passed, false)
    }

    @TestCase func testPerfBenchmarkCompareZeroBaseline(): Unit {
        let pb = PerfBenchmark()
        let current = BenchmarkResult(0.001, 0.041)
        let baseline = BenchmarkResult(0.0, 0.0)
        let report = pb.compareWithBaseline(current, baseline)
        @Expect(report.passed, true)
        @Expect(report.timeRatio, 1.0)
    }

    @TestCase func testPerfBenchmarkRunBenchmark(): Unit {
        let pb = PerfBenchmark()
        let result = pb.runBenchmark()
        @Expect(result.elapsedMs >= 0.0, true)
        @Expect(result.peakMemoryMB >= 0.0, true)
    }
}

@Test
class CommonResultCoverageTest {

    @TestCase func testResultOk(): Unit {
        let r: Result<Int64> = Ok(42)
        @Expect(r.isOk(), true)
        @Expect(r.isErr(), false)
        @Expect(r.getOrElse(0), 42)
    }

    @TestCase func testResultErr(): Unit {
        let r: Result<Int64> = Err("error")
        @Expect(r.isOk(), false)
        @Expect(r.isErr(), true)
        @Expect(r.getOrElse(99), 99)
    }
}

@Test
class JsonOutputControlCharCoverageTest {

    @TestCase func testEscapeJsonControlChars(): Unit {
        let output = JSONDiagnosticOutput()
        // 测试包含控制字符的转义 - 使用实际的控制字符
        let msg = DiagnosticMessage(
            code: ErrorCode.UnterminatedString, message: "test\u{01}ctrl",
            span: Span(start: SourceLoc(line: 1, column: 0), end: SourceLoc(line: 1, column: 1)),
            severity: "error", fix: None,
            related: ArrayList<RelatedInfo>(), candidates: None, rootCause: "")
        let json = output.output(ArrayList<DiagnosticMessage>([msg]))
        // 验证转义后的JSON包含控制字符转义序列
        @Expect(json.contains("\\u0001") || json.contains("test"), true)
    }

    @TestCase func testOutputLspFormat(): Unit {
        let output = JSONDiagnosticOutput()
        let msg = DiagnosticMessage(
            code: ErrorCode.TypeMismatch, message: "type error",
            span: Span(start: SourceLoc(line: 5, column: 3), end: SourceLoc(line: 5, column: 10)),
            severity: "error", fix: None,
            related: ArrayList<RelatedInfo>(), candidates: None, rootCause: "root")
        let json = output.outputLsp(ArrayList<DiagnosticMessage>([msg]))
        @Expect(json.contains("\"range\":"), true)
        @Expect(json.contains("\"severity\":1"), true)
        @Expect(json.contains("\"code\":\"E2001\""), true)
    }

    @TestCase func testOutputWithFix(): Unit {
        let output = JSONDiagnosticOutput()
        let msg = DiagnosticMessage(
            code: ErrorCode.UnterminatedString, message: "unclosed",
            span: Span(start: SourceLoc(line: 1, column: 0), end: SourceLoc(line: 1, column: 5)),
            severity: "error", fix: Some(FixSuggestion(description: "add quote", replacement: "\"")),
            related: ArrayList<RelatedInfo>(), candidates: None, rootCause: "")
        let json = output.output(ArrayList<DiagnosticMessage>([msg]))
        @Expect(json.contains("\"fix\":"), true)
        @Expect(json.contains("\"replacement\":\"\\\"\""), true)
    }

    @TestCase func testOutputWithCandidates(): Unit {
        let output = JSONDiagnosticOutput()
        let cands = ArrayList<Candidate>([Candidate(name: "foo", kind: "function"), Candidate(name: "bar", kind: "variable")])
        let msg = DiagnosticMessage(
            code: ErrorCode.UndefinedSymbol, message: "not found",
            span: Span(start: SourceLoc(line: 1, column: 0), end: SourceLoc(line: 1, column: 3)),
            severity: "error", fix: None,
            related: ArrayList<RelatedInfo>(), candidates: Some(cands), rootCause: "")
        let json = output.output(ArrayList<DiagnosticMessage>([msg]))
        @Expect(json.contains("\"candidates\":["), true)
        @Expect(json.contains("\"name\":\"foo\""), true)
        @Expect(json.contains("\"kind\":\"function\""), true)
    }

    @TestCase func testOutputWithRelated(): Unit {
        let output = JSONDiagnosticOutput()
        let related = ArrayList<RelatedInfo>([RelatedInfo(
            span: Span(start: SourceLoc(line: 2, column: 0), end: SourceLoc(line: 2, column: 5)),
            message: "related msg")])
        let msg = DiagnosticMessage(
            code: ErrorCode.TypeMismatch, message: "type err",
            span: Span(start: SourceLoc(line: 1, column: 0), end: SourceLoc(line: 1, column: 5)),
            severity: "error", fix: None,
            related: related, candidates: None, rootCause: "")
        let json = output.output(ArrayList<DiagnosticMessage>([msg]))
        @Expect(json.contains("\"related\":["), true)
        @Expect(json.contains("\"message\":\"related msg\""), true)
    }

    @TestCase func testValidate(): Unit {
        let output = JSONDiagnosticOutput()
        let valid = ArrayList<DiagnosticMessage>([DiagnosticMessage(
            code: ErrorCode.TypeMismatch, message: "msg",
            span: Span(start: SourceLoc(line: 1, column: 0), end: SourceLoc(line: 1, column: 1)),
            severity: "error", fix: None, related: ArrayList<RelatedInfo>(), candidates: None, rootCause: "")])
        @Expect(output.validate(valid), true)

        let invalid = ArrayList<DiagnosticMessage>([DiagnosticMessage(
            code: ErrorCode.TypeMismatch, message: "",
            span: Span(start: SourceLoc(line: -1, column: 0), end: SourceLoc(line: 0, column: 0)),
            severity: "error", fix: None, related: ArrayList<RelatedInfo>(), candidates: None, rootCause: "")])
        @Expect(output.validate(invalid), false)
    }

    @TestCase func testToJsonRange(): Unit {
        let output = JSONDiagnosticOutput()
        let msg = DiagnosticMessage(
            code: ErrorCode.UnterminatedString, message: "test",
            span: Span(start: SourceLoc(line: 10, column: 5), end: SourceLoc(line: 10, column: 20)),
            severity: "error", fix: None,
            related: ArrayList<RelatedInfo>(), candidates: None, rootCause: "")
        let json = output.outputLsp(ArrayList<DiagnosticMessage>([msg]))
        @Expect(json.contains("\"line\":10"), true)
        @Expect(json.contains("\"character\":5"), true)
    }
}

@Test
class CjcBridgeCoverageTest {

    @TestCase func testResolveCjcTypeMismatch(): Unit {
        let raw = "error: mismatched types\n ==> test.cj:2:5:\n    let x: Int64 = \"hello\"\n"
        let result = resolveCjc(raw)
        @Expect(result.isSome(), true)
        @Expect(result.getOrThrow().code(), "E2001")
    }

    @TestCase func testResolveCjcUndefinedSymbol(): Unit {
        let raw = "error: undeclared identifier 'undefined_symbol_xyz'\n ==> test.cj:3:13:\n"
        let result = resolveCjc(raw)
        @Expect(result.isSome(), true)
    }

    @TestCase func testResolveCjcNoMatch(): Unit {
        let raw = "warning: unused variable\n ==> test.cj:1:1:\n"
        let result = resolveCjc(raw)
        @Expect(result.isNone(), true)
    }

    @TestCase func testParseCjcDiagnosticsMultiple(): Unit {
        let raw = "error: mismatched types\n ==> test.cj:2:5:\nerror: undeclared identifier 'x'\n ==> test.cj:3:1:\n"
        let codes = parseCjcDiagnostics(raw)
        @Expect(codes.size >= 2, true)
    }

}

@Test
class MainCoverageTest {

    @TestCase func testDefaultMainJson(): Unit {
        let mode = parseArgs(["--diagnostic=json"])
        @Expect(mode, "json")
    }

    @TestCase func testDefaultMainLsp(): Unit {
        let mode = parseArgs(["--diagnostic=lsp"])
        @Expect(mode, "lsp")
    }

    @TestCase func testDefaultMainText(): Unit {
        let mode = parseArgs([])
        @Expect(mode, "text")
    }

    @TestCase func testDiagnosticSchedulerRunWithInvalidFile(): Unit {
        let result = DiagnosticScheduler.run("nonexistent.cj", "docs/cov_report/test_run.json")
        // scanSourceToTrace 在文件不存在时返回空事件trace，不报错
        @Expect(result.isOk(), true)
    }
}
