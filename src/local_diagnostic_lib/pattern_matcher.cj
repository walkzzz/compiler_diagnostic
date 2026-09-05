package compiler_diagnostic.local_diagnostic_lib

import std.collection.*
import compiler_diagnostic.semantic_trace.Trace
import compiler_diagnostic.semantic_trace.MachineEvent
import compiler_diagnostic.diagnostics.Span
import compiler_diagnostic.diagnostics.Severity
import compiler_diagnostic.diagnostics.ErrorCategory
import compiler_diagnostic.diagnostics.FixSuggestion
import compiler_diagnostic.diagnostics.RelatedInfo

/// 单命中确定性结果（对齐需求 F-P1-2）
public struct MatchResult {
    public var matched: Bool
    public var patternId: Option<String>
    public var location: Option<Span>
    public var severity: Option<Severity>
    public var category: Option<ErrorCategory>
    public var rootCause: Option<String>
    public var fixSuggestion: Option<FixSuggestion>
    public var candidateCode: Option<String>
    public var relatedInfo: Array<RelatedInfo>
    public init(matched!: Bool, patternId!: Option<String>, location!: Option<Span>,
                severity!: Option<Severity>, category!: Option<ErrorCategory>,
                rootCause!: Option<String>, fixSuggestion!: Option<FixSuggestion>,
                candidateCode!: Option<String>, relatedInfo!: Array<RelatedInfo>) {
        this.matched = matched
        this.patternId = patternId
        this.location = location
        this.severity = severity
        this.category = category
        this.rootCause = rootCause
        this.fixSuggestion = fixSuggestion
        this.candidateCode = candidateCode
        this.relatedInfo = relatedInfo
    }
}

public struct MatchedFault {
    public var pattern: FaultPattern
    public var atEvent: MachineEvent

    // 具名实参构造（调用方写成 MatchedFault(pattern:..., atEvent:...)），形参须带 !。
    public init(pattern!: FaultPattern, atEvent!: MachineEvent) {
        this.pattern = pattern
        this.atEvent = atEvent
    }
}

/// 确定性模式匹配引擎（朴素线性扫描 + 子串/序列匹配）。
public class PatternMatcher {

    /// 取首个命中（OQ5：按 priority 降序 + 注册序确定性选取）
    public static func `match`(trace: Trace): MatchResult {
        let ordered = PatternMatcher.orderedPatterns()
        for (p in ordered) {
            let mr = PatternMatcher.tryMatch(p, trace)
            if (mr.matched) {
                return mr
            }
        }
        return PatternMatcher.unmatched()
    }

    /// 全部命中（供扩展 / 调试；本迭代调度器走 match）
    public static func matchAll(trace: Trace): Array<MatchedFault> {
        let ordered = PatternMatcher.orderedPatterns()
        let result = ArrayList<MatchedFault>()
        for (p in ordered) {
            let conds = p.matchSpec.sequence
            var firstEvent: Option<MachineEvent> = None
            var matchedAny = false
            for (c in conds) {
                let found = PatternMatcher.findEvent(c, trace)
                if (c.negate) {
                    if (found.isNone()) {
                        matchedAny = true
                    }
                } else {
                    if (found.isSome()) {
                        matchedAny = true
                        if (firstEvent.isNone()) {
                            firstEvent = found
                        }
                    }
                }
            }
            if (matchedAny) {
                match (firstEvent) {
                    case Some(ev) => result.add(MatchedFault(pattern: p, atEvent: ev))
                    case None => if (trace.machineEvents.size > 0) {
                        result.add(MatchedFault(pattern: p, atEvent: trace.machineEvents[0]))
                    }
                }
            }
        }
        return result.toArray()
    }

    // ===== 内部 =====

    private static func orderedPatterns(): Array<FaultPattern> {
        let arr = ArrayList<FaultPattern>()
        for (p in FormalLibrary.PATTERNS) {
            arr.add(p)
        }
        let n = arr.size
        var i = 0
        while (i < n) {
            var j = 0
            while (j < n - 1 - i) {
                let a = arr[j]
                let b = arr[j + 1]
                if (a.matchSpec.priority > b.matchSpec.priority) {
                    let tmp = arr[j]
                    arr[j] = arr[j + 1]
                    arr[j + 1] = tmp
                }
                j = j + 1
            }
            i = i + 1
        }
        return arr.toArray()
    }

    private static func tryMatch(p: FaultPattern, trace: Trace): MatchResult {
        let conds = p.matchSpec.sequence
        var allOk = true
        var firstEvent: Option<MachineEvent> = None
        for (c in conds) {
            let found = PatternMatcher.findEvent(c, trace)
            if (c.negate) {
                if (found.isSome()) {
                    allOk = false
                }
            } else {
                if (found.isNone()) {
                    allOk = false
                } else if (firstEvent.isNone()) {
                    firstEvent = found
                }
            }
        }
        if (p.matchSpec.requireAll) {
            if (!allOk) {
                return PatternMatcher.unmatched()
            }
        } else {
            var anyOk = false
            for (c in conds) {
                let found = PatternMatcher.findEvent(c, trace)
                if (c.negate) {
                    if (found.isNone()) {
                        anyOk = true
                    }
                } else {
                    if (found.isSome()) {
                        anyOk = true
                    }
                }
            }
            if (!anyOk) {
                return PatternMatcher.unmatched()
            }
        }
        let loc = match (firstEvent) {
            case Some(e) => Some(Span(start: e.loc, end: e.loc))
            // None 是泛型构造子，此处无法从另一臂反推，须显式给出类型实参。
            case None => None<Span>
        }
        return MatchResult(
            matched: true,
            patternId: Some(p.id),
            location: loc,
            severity: Some(p.severity),
            category: Some(p.category),
            rootCause: Some(p.repair.rootCause),
            fixSuggestion: Some(p.repair.fixSuggestion),
            candidateCode: Some(p.repair.candidateCode),
            relatedInfo: p.repair.relatedInfo)
    }

    private static func unmatched(): MatchResult {
        return MatchResult(
            matched: false,
            patternId: None,
            location: None,
            severity: None,
            category: None,
            rootCause: None,
            fixSuggestion: None,
            candidateCode: None,
            relatedInfo: Array<RelatedInfo>())
    }

    private static func findEvent(c: EventCondition, trace: Trace): Option<MachineEvent> {
        for (e in trace.machineEvents) {
            if (PatternMatcher.eventSatisfies(e, c)) {
                return Some(e)
            }
        }
        return None
    }

    private static func eventSatisfies(e: MachineEvent, c: EventCondition): Bool {
        if (c.kind.isSome()) {
            let want = optStr(c.kind)
            if (e.kind != want) {
                return false
            }
        }
        if (c.hasException) {
            if (e.exception.isNone()) {
                return false
            }
        }
        if (c.exceptionType.isSome()) {
            let ok = match (e.exception) {
                case Some(exc) => exc.`type` == optStr(c.exceptionType)
                case None => false
            }
            if (!ok) {
                return false
            }
        }
        if (c.path.isSome()) {
            let want = optStr(c.path)
            if (e.path != want) {
                return false
            }
        }
        if (c.symbolName.isSome()) {
            let want = optStr(c.symbolName)
            var foundName = false
            for (s in e.symbols) {
                if (s.name == want) {
                    foundName = true
                }
            }
            if (!foundName) {
                return false
            }
        }
        if (c.symbolType.isSome()) {
            let want = optStr(c.symbolType)
            var foundType = false
            for (s in e.symbols) {
                if (s.`type` == want) {
                    foundType = true
                }
            }
            if (!foundType) {
                return false
            }
        }
        return true
    }

    private static func optStr(o: Option<String>): String {
        match (o) {
            case Some(v) => v
            case None => ""
        }
    }
}
