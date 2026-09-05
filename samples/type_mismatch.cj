// 类型不匹配示例（用于 run 子命令静态扫描）
func main(): Int64 {
    let x: Int = "hello"   // 期望 Int 实际 String：触发 TypeMismatch
    return x
}
