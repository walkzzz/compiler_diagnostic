package compiler_diagnostic.samples

// 数组越界示例（用于 run 子命令静态扫描 -> Trace -> 本地诊断）
// 真实可编译：运行时会触发 ArrayIndexOutOfBounds（本迭代仅做静态扫描，不实际执行）。
func demoArrayOob(): Int64 {
    let arr = [1, 2, 3]
    let idx = 5
    let v = arr[idx]   // 下标越界：触发 ArrayIndexOutOfBounds
    return v
}
