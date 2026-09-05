// 模式匹配遗漏分支示例（用于 run 子命令静态扫描）
func main(): Int64 {
    let x = Color.Red
    match (x) {        // 缺少通配臂：触发 NonExhaustiveMatch
        case Color.Red => 1
        case Color.Green => 2
    }
}
