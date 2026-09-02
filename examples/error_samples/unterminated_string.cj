package error_samples

// 示例：未终止字符串
// 编译错误：字符串未终止

func main(): Unit {
    let s = "这是一个未终止的字符串
    println(s)
}
