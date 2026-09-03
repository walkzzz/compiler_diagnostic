package error_samples

// 示例：函数重载歧义（E1003 · SemaOverloadAmbiguity）
// 调用处传入的实参可同时匹配多个重载签名，编译器无法唯一解析，触发重载歧义诊断。
// 对应 SemaDiagnostic.reportOverloadAmbiguity(span, funcName, candidates)。

func size(x: String): Int64 {
    return x.size
}

func size(x: Array<Int64>): Int64 {
    return x.size
}

func main(): Unit {
    // 字面量无法唯一匹配 String / Array<Int64> 重载，触发 SemaOverloadAmbiguity
    println(size(42))
}
