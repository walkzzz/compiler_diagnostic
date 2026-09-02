package compiler_diagnostic.output
import std.collection.*

import compiler_diagnostic.diagnostics.DiagnosticMessage

/// 诊断输出基类
public abstract class DiagnosticOutput {
    public func output(diagnostics: List<DiagnosticMessage>): String
}
