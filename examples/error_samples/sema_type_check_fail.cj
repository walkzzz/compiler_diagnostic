package error_samples

// 示例：类型检查失败（E1001 · SemaTypeCheckFail）
// 将 Int64 字面量赋给声明为 String 的绑定，类型不匹配，触发类型检查失败诊断。
// 对应 SemaDiagnostic.reportTypeCheckFail(span, expectedType, actualType, rootCause)。

func main(): Unit {
    let s: String = 42
    println(s)
}
