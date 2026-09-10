---
name: cangjie-orientation
description: >
  仓颉语言入门导航技能。当用户询问仓颉语言基础、"仓颉是什么？"、"如何开始？"、
  "X 在仓颉中怎么用？"时使用。这是所有仓颉 Agent 交互的入口点。
author: cangjie-expert-team
rail:
  capabilities: [faq, guide, example, getting-started, api-lookup]
  constraints: [read-only, no-code-modification]
  requires: []
  provides: [answer, example-code, doc-link]
  collaborates_with: [all]
---

# 仓颉语言入门导航

通过识别用户缺失的上下文，解决仓颉开发者的问题。

## 默认工作流

### 1. 分类用户情况和可能缺失的层级

### 2. 检查以下内容，选择路径前先检查新鲜度门控

### 3. 加载最小的相关参考文件

### 4. 如果是代码、API、包配置或诊断，先检查本地文件或运行最窄的发现命令

### 5. 给出实用答案：直接能力答案、仓颉等价、精确验证命令或链接

### 6. 如果最终答案给出精确 API、导入、错误码含义、目标规则或文档声明，
包含验证命令或 URL。即使答案很短也要这样做。

## 新鲜度门控

一些仓颉事实比模型记忆更新更快：新语法、实验特性、包可用性、包 API、
依赖版本、目标支持和命令标志。对于这些，不要把记忆变成最终答案。

使用以下模式：

1. 如果是稳定事实，给出能力级答案。
2. 说明精确 API、包名或工具行为可能已变更。
3. 选择当前源：本地项目文件、已安装的 `cjpm` 命令、官方文档、mooncakes 包文档或注册表。
4. 如果当前环境无法检查源，说明必须检查的内容，并提供下一个验证命令。

## 常见问题分类

| 用户问题关键词 | 对应 wiki 目录 | 入口文件 |
|----------------|----------------|----------|
| 语法、类型、错误处理、FFI、属性 | `language/` | `introduction.md` |
| Array、Map、String、Json、math | `stdlib/` | `overview.md` |
| cjpm 命令、IDE、包管理、VS Code | `toolchain/` | `moon-commands.md` |
| async、并发、socket、HTTP、WebSocket | `async/` | `overview.md` |
| crypto、time、uuid、path、json5 | `libs/` | `x-overview.md` |
| 教材、课程、Tour、示例 | `tutorials/` | `textbook.md` |
| awesome、社区、生态 | `ecosystem/` | `awesome-cangjie.md` |
| RFC、提案、演进 | `evolution/` | `proposals.md` |
| Agent 工作流、C 绑定、证明、重构 | `agent-guide/` | `overview.md` |
| 博客、Pearls | `blog/` | `blog-index.md` |

## 注意事项

- 对于标准库和依赖 API，默认使用 `cjpm ide doc`。它比记忆或过时文档更好地反映已安装的工具链和依赖。
- 对于生态系统包可用性，不要从熟悉的技术名称推断存在性。检查 mooncakes 或在临时项目中运行 `moon add <candidate>`。
- `llvm` 仅 nightly。稳定后端指导使用 `wasm`、`wasm-gc`、`js` 或 `native`。
- 不要通过从 Rust、Go、TypeScript 或 OCaml 翻译来回答精确 API 名称。先发现仓颉 API。
- 不要发送用户到"文档"而不提供具体 URL 或命令。

## 验证契约

将仓颉事实分为三个层级：

- **稳定能力事实**：语言/工具链形状，如无类继承模型、类型错误、常见稳定目标、`llvm` 仅 nightly。
- **验证精确事实**：精确 API 名称、签名、包名、导入、目标配置，由 `cjpm ide`、本地文件、生成接口、官方文档或 mooncakes 验证。
- **未验证猜测**：从其他语言、内存或命名约定推断的合理 API 名称或行为。

永远不要将未验证猜测作为事实呈现。如果精确事实未验证，说明必须检查的内容，并提供命令或 URL。

## 文件结构

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主技能入口 — 工作流和新鲜度门控 |
| `README.md` | 入门导航概述 |
| `CHANGELOG.md` | 版本变更记录 |
| `references/source-map.md` | 源文件到 wiki 的映射 |
| `references/gotchas.md` | 常见陷阱 |
