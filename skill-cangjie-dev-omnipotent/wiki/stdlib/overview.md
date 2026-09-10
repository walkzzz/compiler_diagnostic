# 仓颉标准库

> [← 返回首页](../README.md) | [标准库](overview.md)

## 概述

仓颉标准库（std）包含丰富的内置库，覆盖数据结构、文件操作、网络通信、数学计算等领域。

## 模块列表

### 集合 (std.collection)

| 类 | 说明 |
|------|------|
| `ArrayList<T>` | 动态数组 |
| `LinkedList<T>` | 双向链表 |
| `HashMap<K, V>` | 哈希映射 |
| `HashSet<T>` | 哈希集合 |
| `TreeMap<K, V>` | 红黑树映射 |
| `TreeSet<T>` | 红黑树集合 |

### I/O (std.io)

| 类 | 说明 |
|------|------|
| `stdin` | 标准输入 |
| `stdout` | 标准输出 |
| `stderr` | 标准错误 |
| `File` | 文件操作 |

### 文件系统 (std.fs)

| 函数 | 说明 |
|------|------|
| `exists(path)` | 检查文件是否存在 |
| `read(path)` | 读取文件 |
| `write(path, content)` | 写入文件 |
| `list(dir)` | 列出目录 |

### 网络 (std.net)

| 类 | 说明 |
|------|------|
| `Socket` | 基础 Socket |
| `TCPSocket` | TCP Socket |
| `UDPSocket` | UDP Socket |

### 数学 (std.math)

| 函数 | 说明 |
|------|------|
| `sin(x)` | 正弦 |
| `cos(x)` | 余弦 |
| `sqrt(x)` | 平方根 |
| `pow(x, y)` | 幂运算 |

### 加密 (std.crypto)

| 类 | 说明 |
|------|------|
| `SHA256` | SHA-256 哈希 |
| `MD5` | MD5 哈希 |

## 使用示例

```cangjie
import std.collection.ArrayList
import std.fs.*

main() {
    // 使用集合
    let list = ArrayList<Int64>()
    list.add(1)
    list.add(2)
    
    // 使用文件系统
    if exists("test.txt") {
        let content = read("test.txt")
        println(content)
    }
}
```

## 相关文件

- [overview.md](overview.md) - 标准库概览
- [collection.md](collection.md) - 集合库
- [io.md](io.md) - I/O 库
- [fs.md](fs.md) - 文件系统
- [net.md](net.md) - 网络库
