package error_samples

// 示例：可见性检查失败（E1004 · SemaVisibilityFail）
// 在类外部访问其 private 成员，违反可见性规则，触发可见性检查失败诊断。
// 对应 SemaDiagnostic.reportVisibilityFail(span, memberName, accessPath)。

class Account {
    private var balance: Int64 = 0
}

func main(): Unit {
    let a = Account()
    // 类外部访问 private 成员 balance，触发 SemaVisibilityFail
    println(a.balance)
}
