package compiler_diagnostic.output
import std.collection.*

import compiler_diagnostic.diagnostics.DiagnosticMessage
import compiler_diagnostic.diagnostics.Span
import compiler_diagnostic.diagnostics.RelatedInfo
import compiler_diagnostic.diagnostics.FixSuggestion
import compiler_diagnostic.diagnostics.getCodeStr

/// JSON 诊断输出（LSP 兼容）
public class JSONDiagnosticOutput <: DiagnosticOutput {
    public override func output(diagnostics: List<DiagnosticMessage>): String {
        let sb = StringBuilder()
        sb.append("{\"diagnostics\":[")
        var firstDiag = true
        for (diag in diagnostics) {
            if (!firstDiag) {
                sb.append(",")
            }
            firstDiag = false
            sb.append(this.toJsonDiagnostic(diag))
        }
        sb.append("]}")
        return sb.toString()
    }

    private func toJsonDiagnostic(diag: DiagnosticMessage): String {
        let sb = StringBuilder()
        sb.append("{")
        sb.append("\"code\":\"")
        sb.append(getCodeStr(diag.code))
        sb.append("\",\"severity\":\"")
        sb.append(diag.severity)
        sb.append("\",\"message\":\"")
        sb.append(this.escapeJson(diag.message))
        sb.append("\",\"span\":")
        sb.append(this.toJsonSpan(diag.span))

        if (diag.fix.isSome()) {
            sb.append(",\"fix\":")
            sb.append(this.toJsonFix(diag.fix.getOrThrow()))
        }

        if (diag.related.size > 0) {
            sb.append(",\"related\":[")
            var firstRel = true
            for (r in diag.related) {
                if (!firstRel) {
                    sb.append(",")
                }
                firstRel = false
                sb.append(this.toJsonRelated(r))
            }
            sb.append("]")
        }

        if (diag.candidates.isSome()) {
            sb.append(",\"candidates\":[")
            let cands = diag.candidates.getOrThrow()
            let arr: Array<String> = cands.toArray()
            var firstCand = true
            for (s in arr) {
                if (!firstCand) {
                    sb.append(",")
                }
                firstCand = false
                sb.append("\"")
                sb.append(this.escapeJson(s))
                sb.append("\"")
            }
            sb.append("]")
        }

        sb.append("}")
        return sb.toString()
    }

    private func toJsonSpan(span: Span): String {
        let sb = StringBuilder()
        sb.append("{\"start\":{\"line\":")
        sb.append(span.start.line)
        sb.append(",\"column\":")
        sb.append(span.start.column)
        sb.append("},\"end\":{\"line\":")
        sb.append(span.end.line)
        sb.append(",\"column\":")
        sb.append(span.end.column)
        sb.append("}}")
        return sb.toString()
    }

    private func toJsonFix(fix: FixSuggestion): String {
        let sb = StringBuilder()
        sb.append("{\"description\":\"")
        sb.append(this.escapeJson(fix.description))
        sb.append("\",\"replacement\":\"")
        sb.append(this.escapeJson(fix.replacement))
        sb.append("\"")
        if (fix.span.isSome()) {
            sb.append(",\"span\":")
            sb.append(this.toJsonSpan(fix.span.getOrThrow()))
        }
        sb.append("}")
        return sb.toString()
    }

    private func toJsonRelated(related: RelatedInfo): String {
        let sb = StringBuilder()
        sb.append("{\"span\":")
        sb.append(this.toJsonSpan(related.span))
        sb.append(",\"message\":\"")
        sb.append(this.escapeJson(related.message))
        sb.append("\"}")
        return sb.toString()
    }

    private func escapeJson(s: String): String {
        var result = s
        result = result.replace("\\", "\\\\")
        result = result.replace("\"", "\\\"")
        result = result.replace("\n", "\\n")
        result = result.replace("\r", "\\r")
        result = result.replace("\t", "\\t")
        // 处理其他控制字符 (U+0000-U+001F)
        let sb = StringBuilder()
        for (r in result.toRuneArray()) {
            let cp = UInt32(r)
            if (cp < 32u32) {
                sb.append("\\u")
                sb.append(this.hexDigit(cp / 16u32))
                sb.append(this.hexDigit(cp % 16u32))
            } else {
                sb.append(r.toString())
            }
        }
        return sb.toString()
    }

    /// 将 0-15 的数值转换为大写十六进制字符
    private func hexDigit(n: UInt32): String {
        match (n) {
            case 0u32 => "0"
            case 1u32 => "1"
            case 2u32 => "2"
            case 3u32 => "3"
            case 4u32 => "4"
            case 5u32 => "5"
            case 6u32 => "6"
            case 7u32 => "7"
            case 8u32 => "8"
            case 9u32 => "9"
            case 10u32 => "A"
            case 11u32 => "B"
            case 12u32 => "C"
            case 13u32 => "D"
            case 14u32 => "E"
            case _ => "F"
        }
    }

    public func validate(diagnostics: List<DiagnosticMessage>): Bool {
        for (diag in diagnostics) {
            if (diag.message.isEmpty() || diag.span.start.line < 0) {
                return false
            }
        }
        return true
    }
}
