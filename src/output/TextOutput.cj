package compiler_diagnostic.output
import std.collection.*

import compiler_diagnostic.diagnostics.DiagnosticMessage
import compiler_diagnostic.diagnostics.Span
import compiler_diagnostic.diagnostics.RelatedInfo
import compiler_diagnostic.diagnostics.FixSuggestion
import compiler_diagnostic.diagnostics.Candidate
import compiler_diagnostic.diagnostics.getCodeStr

/// 文本诊断输出（人类可读）
public class TextOutput <: DiagnosticOutput {
    public override func output(diagnostics: List<DiagnosticMessage>): String {
        let sb = StringBuilder()
        for (diag in diagnostics) {
            sb.append(this.formatDiag(diag))
            sb.append("\n")
        }
        return sb.toString()
    }

    private func formatDiag(diag: DiagnosticMessage): String {
        let sb = StringBuilder()
        sb.append("[")
        sb.append(getCodeStr(diag.code))
        sb.append("] (")
        sb.append(diag.severity)
        sb.append(") ")
        sb.append(diag.message)
        sb.append("\n  位置: ")
        sb.append(diag.span.start.file)
        sb.append(":")
        sb.append(diag.span.start.line + 1)
        sb.append(":")
        sb.append(diag.span.start.column + 1)

        if (diag.fix.isSome()) {
            let fix = diag.fix.getOrThrow()
            sb.append("\n  修复建议: ")
            sb.append(fix.description)
        }

        if (diag.related.size > 0) {
            for (rel in diag.related) {
                sb.append("\n  关联位置: ")
                sb.append(rel.span.start.file)
                sb.append(":")
                sb.append(rel.span.start.line + 1)
                sb.append(":")
                sb.append(rel.span.start.column + 1)
                sb.append(" - ")
                sb.append(rel.message)
            }
        }

        if (diag.candidates.isSome()) {
            let cands = diag.candidates.getOrThrow()
            let arr: Array<Candidate> = cands.toArray()
            sb.append("\n  候选符号: ")
            let parts: ArrayList<String> = ArrayList<String>()
            for (c in arr) {
                parts.add(c.name + "(" + c.kind + ")")
            }
            sb.append(String.join(parts.toArray(), delimiter: ", "))
        }

        return sb.toString()
    }
}
