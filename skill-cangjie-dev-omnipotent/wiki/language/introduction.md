# 仓颉语言基础

> [← 返回首页](../README.md) | [语言基础](introduction.md)

## 概述

仓颉（Cangjie）是华为推出的面向全场景应用的编程语言，定位为全场景智能编程语言。

## 语言特性

### 核心特性

- **高性能**：基于 LLVM 编译器基础设施，方舟编译器技术栈
- **现代化语法**：融合 Rust/Swift/Kotlin 等现代语言特性
- **AI 原生**：内置 LLM Agent 支持（CangjieMagic）
- **鸿蒙生态深度集成**：HarmonyOS 应用开发首选语言

### 语法特点

```cangjie
// 变量声明
let x: Int64 = 10          // 不可变
var y: Int64 = 20          // 可变

// 函数定义
func add(a: Int64, b: Int64): Int64 {
    return a + b
}

// 类定义
class Person {
    name: String
    age: Int64
    
    func greet(): String {
        return "Hello, " + name
    }
}

// 泛型
class Box<T> {
    value: T
}
```

## 类型系统

### 基本类型

| 类型 | 说明 |
|------|------|
| `Int64` | 64 位整数 |
| `Float64` | 64 位浮点数 |
| `Bool` | 布尔值 |
| `String` | 字符串 |
| `Char` | 字符 |

### 复合类型

| 类型 | 说明 |
|------|------|
| `Array<T>` | 数组 |
| `Tuple` | 元组 |
| `Enum` | 枚举 |
| `Union` | 联合类型 |

## 相关文件

- [introduction.md](introduction.md) - 语言入门
- [syntax.md](syntax.md) - 语法详解
- [types.md](types.md) - 类型系统
- [error-codes.md](error-codes.md) - 错误码参考
