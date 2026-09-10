---
name: cangjie-std
description: >
  仓颉标准库开发技能。当用户需要开发或使用标准库模块（std.collection、std.io、
  std.fs、std.net、std.math、std.crypto、std.sync、std.time 等）时使用。
  涵盖 cangjie_runtime/stdlib 仓库。
author: cangjie-expert-team
rail:
  capabilities: [std-api, collection, io, fs, math, crypto, convert, time]
  constraints: [no-internal-impl-exposure, stable-api-guarantee]
  requires: [cangjie-sdk-installed]
  provides: [api-doc, usage-example, migration-guide]
  collaborates_with: [cangjie-compiler, cangjie-stdx, cangjie-tools]
---

# 仓颉标准库开发技能

用于快速、可靠地执行标准库开发任务。

## 默认工作流

### 1. 明确目标和约束
- 确认预期行为、非目标、API 兼容性约束。

### 2. 定位模块边界
- 找到 `stdlib/` 目录结构。
- 确定模块的公共 API 边界。

### 3. 编码前发现 API
- 优先使用 `cjpm ide doc std.*` 查询现有 API。
- 使用 `cjpm ide outline` 进行语义导航。

### 4. 紧密循环验证
- 编辑后运行 `cjpm check`。
- 运行 `cjpm test` 验证模块行为。

### 5. 交付前完成
- 运行 `cjpm fmt`。
- 运行 `cjpm info` 验证 API 变更。

## 标准库架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      Cangjie 标准库 (std)                       │
└─────────────────────────────────────────────────────────────────┘

集合 (std.collection)
├── ArrayList<T>        动态数组
├── LinkedList<T>       双向链表
├── HashMap<K, V>       哈希映射
├── HashSet<T>          哈希集合
├── TreeMap<K, V>       红黑树映射
├── TreeSet<T>          红黑树集合
├── ArrayDeque<T>       双端队列
├── ArrayQueue<T>       队列
└── ArrayStack<T>       栈

并发集合 (std.collection.concurrent)
├── BlockingQueue<T>
├── ArrayBlockingQueue<T>
├── ConcurrentHashMap<K, V>
└── NonBlockingQueue<T>

I/O (std.io)
├── 标准输入输出
├── 文件读写
└── 格式化

文件系统 (std.fs)
├── 路径操作
├── 文件读写
├── 目录遍历
└── 文件元数据

网络 (std.net)
├── Socket
├── TCP/UDP
└── HTTP 客户端

数学 (std.math)
├── 三角函数
├── 指数对数
├── 随机数
└── 常量

加密 (std.crypto)
├── 对称加密
├── 摘要算法
└── 哈希

并发 (std.sync)
├── Mutex
├── Channel
└── WaitGroup

时间 (std.time)
├── DateTime
├── Duration
└── Instant
```

## 源代码目录

```
cangjie_runtime/stdlib/
├── collection/          # 集合
├── io/                  # I/O
├── fs/                  # 文件系统
├── net/                 # 网络
├── math/                # 数学
├── crypto/              # 加密
├── sync/                # 并发
├── time/                # 时间
├── reflect/             # 反射
├── regex/               # 正则表达式
└── ...
```

## 验证契约

- **稳定能力事实**：标准库模块结构、集合 API、I/O 接口。
- **验证精确事实**：精确 API 名称、签名，由 `cjpm ide doc` 和本地文件验证。
- **未验证猜测**：从其他标准库（Java、Python）推断的 API。

## 文件结构

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主技能入口 |
| `README.md` | 标准库开发概述 |
| `CHANGELOG.md` | 版本变更记录 |
| `references/collection-guide.md` | 集合库指南 |
| `references/io-guide.md` | I/O 库指南 |
| `references/fs-guide.md` | 文件系统指南 |
