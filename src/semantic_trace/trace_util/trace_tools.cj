package compiler_diagnostic.semantic_trace.trace_util

import std.collection.*
import compiler_diagnostic.semantic_trace.Trace
import compiler_diagnostic.semantic_trace.MachineEvent

/// Trace 查询 / 切片 / Trace-Diff（P2 预留）。
/// - queryEvents：本迭代即给出最小可用实现。
/// - slice / diff：P2 占位。
public class TraceTools {

    /// 查询：按谓词筛选事件（本迭代可用）
    public static func queryEvents(trace: Trace, predicate: (MachineEvent) -> Bool): Array<MachineEvent> {
        let result = ArrayList<MachineEvent>()
        for (e in trace.machineEvents) {
            if (predicate(e)) {
                result.add(e)
            }
        }
        return result.toArray()
    }

    /// 切片：截取 [fromStep, toStep] 子轨迹（P2 占位：复制首尾区间事件）
    public static func slice(trace: Trace, fromStep: Int64, toStep: Int64): Trace {
        let kept = ArrayList<MachineEvent>()
        for (e in trace.machineEvents) {
            if (e.stepId >= fromStep && e.stepId <= toStep) {
                kept.add(e)
            }
        }
        return Trace(
            schemaVersion: trace.schemaVersion,
            generator: trace.generator,
            program: trace.program,
            machineEvents: kept.toArray(),
            semanticEvents: trace.semanticEvents)
    }

    /// Trace-Diff：两次执行对比（P2 占位）
    /// 形参以 `_` 命名：本迭代为占位实现（P2 才真正比对两个 Trace），
    /// 具名形参会触发 cjc 的 "unused variable" warning，故显式标记为有意不使用。
    public static func diff(_: Trace, _: Trace): String {
        return "not implemented in this iteration"
    }
}
