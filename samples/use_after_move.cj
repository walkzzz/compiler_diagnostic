// 所有权误用示例（用于 run 子命令静态扫描）
func main(): Int64 {
    let x = Resource()
    let y = move(x)   // move 后 x 不应再被使用：触发 UseAfterMove
    return y.useIt()
}
