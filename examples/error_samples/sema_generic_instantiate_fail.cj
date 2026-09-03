package error_samples

// 示例：泛型实例化失败（E1002 · SemaGenericInstantiateFail）
// 对带有类型约束的泛型实参传入不满足约束的类型，触发泛型实例化失败诊断。
// 对应 SemaDiagnostic.reportGenericInstantiateFail(span, genericName, constraintViolation)。

interface Show {
    func show(): String
}

class Box<T> where T <: Show {
    var value: T
    init(value!: T) {
        this.value = value
    }
}

func main(): Unit {
    // Int64 未实现 Show 约束，触发 SemaGenericInstantiateFail
    let b = Box<Int64>(value: 1)
    println(b.value)
}
