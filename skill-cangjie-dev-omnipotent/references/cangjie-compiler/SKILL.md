---
name: cangjie-compiler
description: >
  仓颉编译器开发技能。当用户需要开发编译器、词法分析、语法分析、语义分析、
  中间表示（CHIR）、代码生成、IR优化、或理解编译器架构时使用。
  涵盖 cangjie_compiler 和 llvm-project 仓库。
author: cangjie-expert-team
rail:
  capabilities: [compile-cangjie, analyze-ast, optimize-ir, codegen, type-check]
  constraints: [no-runtime-modification, no-stdlib-api-break]
  requires: [cangjie-sdk-installed, source-code-available]
  provides: [compiled-binary, ast-analysis, type-errors]
  collaborates_with: [cangjie-runtime, cangjie-tools, cangjie-std]
---

# 仓颉编译器开发技能

用于快速、可靠地执行编译器开发任务。

## 默认工作流

### 1. 明确目标和约束
- 确认预期行为、非目标、兼容性约束（目标后端、公共 API 稳定性、性能限制）。

### 2. 定位模块/包边界
- 找到 `cjpm.toml` 和相关源文件。
- 确定编译器前端、中端、后端的边界。

### 3. 编码前发现 API
- 优先使用 `cjpm ide doc` 查询现有函数/类型/方法。
- 使用 `cjpm ide outline`、`cjpm ide peek-def`、`cjpm ide find-references` 进行语义导航。

### 4. 可靠重构
- 使用 `cjpm ide rename` 进行语义重命名。
- 如果多个符号共享名称，添加 `--loc filename:line:col`。
- 如需保持向后兼容性，使用 `#alias(old_api, deprecated)`。

### 5. 最小化和包本地编辑
- 将更改保持在正确的包内。
- 使用 `///|` 顶层分隔符。
- 将代码拆分为内聚文件。

### 6. 紧密循环验证
- 编辑后运行 `cjpm check`。
- 添加 `--warn-list +unnecessary_annotation` 启用警告 73。
- 运行 `cjpm test [dirname|filename] --filter 'glob'`。

### 7. 交付前完成
- 运行 `cjpm fmt`。
- 运行 `cjpm info` 验证公共 API 是否变更。
- 报告更改的文件、验证命令和任何剩余风险。

## 快速任务手册

### Bug 修复（无 API 变更意图）

1. 复现或识别失败行为。
2. 用 `cjpm ide outline` 定位符号。
3. 在当前包中实现最小修复。
4. 验证：
   - `cjpm check`
   - `cjpm test [dirname|filename] --filter 'glob'`
   - `cjpm fmt`
   - `cjpm info`（确认 `pkg.generated.mbti` 未变更）

### 重构（行为保持）

1. 先确认行为/API 不变量。
2. 优先使用语义重命名/导航工具：
   - `cjpm ide rename`
   - `cjpm ide find-references`
   - `cjpm ide peek-def`
3. 保持编辑包本地和文件组织聚焦。
4. 验证：
   - `cjpm check`
   - `cjpm test [dirname|filename]`
   - `cjpm fmt`
   - `cjpm info`（API 应保持不变，除非请求变更）

### 新特性或公共 API

1. 引入新名称前，用 `cjpm ide doc` 发现现有惯用法。
2. 在带有 `///|` 分隔符的内聚文件中添加实现。
3. 为公共 API 添加/扩展黑盒测试和文档字符串示例。
4. 验证：
   - `cjpm check`
   - `cjpm test [dirname|filename]`（需要时用 `--update` 更新快照）
   - `cjpm fmt`
   - `cjpm info`（审查并保持预期的 `pkg.generated.mbti` 变更）

## 编译器架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      编译器架构                                 │
└─────────────────────────────────────────────────────────────────┘

前端 (Frontend)
├── Lexer (词法分析)
│   └── 将源码分解为 Token
├── Parser (语法分析)
│   └── 构建 AST 抽象语法树
├── Semantic (语义分析)
│   ├── 类型检查
│   ├── 类型推断
│   └── 作用域分析
├── Macro (宏展开)
│   └── 处理宏定义和调用
├── Condition Compile (条件编译)
│   └── 基于预定义条件编译
└── Package Management (包管理)
    └── 模块管理、依赖处理

中端 (Middleend)
├── CHIR (Cangjie High Level IR)
│   ├── 从 AST 转换
│   ├── 优化
│   └── 增量编译支持
└── CodeGen (代码生成)
    └── CHIR → LLVM IR

后端 (Backend)
├── LLVM IR
├── opt (优化器)
│   └── 常量折叠、循环优化
├── llc (代码生成)
│   └── LLVM IR → 机器码
├── ld (链接器)
│   └── 链接目标文件
└── cjdb (调试器)
    └── 符号反修饰、堆栈跟踪
```

## 源代码目录

```
cangjie_compiler/src/
├── AST                    # 抽象语法树
├── Basic                  # 基础组件
├── CHIR                   # 中间表示与优化
├── CodeGen                # CHIR → LLVM IR
├── ConditionalCompilation # 条件编译
├── Driver                 # 编译器驱动
├── Frontend               # 编译器实例
├── FrontendTool           # 外部工具接口
├── IncrementalCompilation # 增量编译
├── Lex                    # 词法分析
├── Macro                  # 宏展开
├── main.cpp               # 入口点
├── Mangle                 # 符号修饰
├── Modules                # 模块管理
├── Option                 # 编译选项
├── Parse                  # 语法分析
├── Sema                   # 语义分析
└── Utils                  # 工具函数
```

## 验证契约

将仓颉编译器事实分为三个层级：

- **稳定能力事实**：语言/编译器架构覆盖在此技能中，如无类继承模型、类型安全、CHIR IR。
- **验证精确事实**：精确 API 名称、签名、包名、导入、目标配置，由 `cjpm ide`、本地文件、生成接口验证。
- **未验证猜测**：从其他语言、内存或命名约定推断的 API 名称或行为。

永远不要将未验证猜测作为事实呈现。如果精确事实未验证，说明必须检查的内容，并提供命令或 URL。

## 常见任务

### 查找某个语法特性的实现

1. 确定特性所属模块（Lex/Parse/Sema/CHIR）
2. 读取对应目录源文件
3. 用 `Grep` 搜索关键词

### 添加新语言特性

1. 在 Lexer 中添加 Token
2. 在 Parser 中添加语法规则
3. 在 Sema 中添加类型检查
4. 在 CHIR 中添加 IR 节点
5. 在 CodeGen 中添加代码生成
6. 添加测试用例

### 诊断编译错误

1. 运行 `cjpm check --explain` 查看错误码
2. 在 `cangjie_compiler/src/` 中搜索错误码
3. 检查相关源文件

## 文件结构

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主技能入口 — 工作流和编译器架构 |
| `README.md` | 编译器开发概述 |
| `CHANGELOG.md` | 版本变更记录 |
| `references/compiler-architecture.md` | 编译器架构详解 |
| `references/language-features.md` | 语言特性实现指南 |
| `references/error-codes.md` | 错误码参考 |
