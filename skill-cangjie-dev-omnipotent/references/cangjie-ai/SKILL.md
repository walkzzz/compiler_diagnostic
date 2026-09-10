---
name: cangjie-ai
description: >
  仓颉 AI Agent 开发技能。当用户需要开发或使用 CangjieMagic、MCP 协议、
  AI Agent、MagicExplorer 时使用。涵盖 CangjieMagic、MagicExplorer、
  CangjieSkills 仓库。
author: cangjie-expert-team
rail:
  capabilities: [agent, mcp, llm, planner, cangjie-magic, magic-explorer]
  constraints: [no-model-weight-modification, no-external-api-without-permission]
  requires: [cangjie-sdk-installed, cangjie-std, cangjie-net]
  provides: [agent-dsl, mcp-server, tool-registration]
  collaborates_with: [cangjie-framework, cangjie-net, cangjie-tools]
---

# 仓颉 AI Agent 开发技能

用于快速、可靠地执行 AI Agent 开发任务。

## 默认工作流

### 1. 明确目标和约束
- 确认预期行为、非目标、AI 模型兼容性约束。

### 2. 定位 Agent 边界
- 找到 CangjieMagic 相关目录。
- 确定 Agent 的公共 API 边界。

### 3. 编码前发现 API
- 优先使用 `cjpm ide doc CangjieMagic` 查询现有 API。
- 使用 `cjpm ide outline` 进行语义导航。

### 4. 紧密循环验证
- 编辑后运行 `cjpm check`。
- 运行 `cjpm test` 验证 Agent 行为。

### 5. 交付前完成
- 运行 `cjpm fmt`。
- 运行 `cjpm info` 验证 API 变更。

## AI Agent 架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      Cangjie AI Agent 生态                      │
└─────────────────────────────────────────────────────────────────┘

CangjieMagic (LLM Agent DSL)
├── 声明式 DSL
│   ├── Agent 定义
│   ├── 工具注册
│   └── 行为配置
├── MCP 协议
│   ├── 工具调用
│   ├── 资源管理
│   └── 提示模板
├── 任务智能规划
│   ├── 任务分解
│   ├── 步骤规划
│   └── 执行调度
└── LLM 调用
    ├── 模型适配
    ├── 提示构建
    └── 响应解析

MagicExplorer (浏览器 Agent)
├── 自然语言浏览
├── 网页内容提取
├── 表单自动填写
└── 浏览器自动化

CangjieSkills (知识库)
├── 6000+ Markdown 知识库
├── 渐进披露查询
├── 面向任务的检索
└── SQLite 存储

Dapr 集成
├── 边车通信
├── 微服务集成
└── 状态管理
```

## MCP 协议

```
┌─────────────────────────────────────────────────────────────────┐
│                    MCP (Model Context Protocol)                 │
└─────────────────────────────────────────────────────────────────┘

核心概念
├── 工具 (Tools)
│   └── Agent 可调用的函数
├── 资源 (Resources)
│   └── Agent 可访问的数据
└── 提示 (Prompts)
    └── Agent 可用的提示模板

传输方式
├── HTTP
├── WebSocket
└── SSE

消息格式
├── JSON-RPC 2.0
└── 结构化参数
```

## 源代码目录

```
CangjieMagic/
├── src/
│   ├── dsl/              # DSL 解析器
│   ├── mcp/              # MCP 协议
│   ├── planner/          # 任务规划器
│   ├── llm/              # LLM 适配器
│   └── tools/            # 工具注册
└── tests/

MagicExplorer/
├── src/
│   ├── browser/          # 浏览器引擎
│   ├── nlp/              # NLP 解析
│   ├── extractor/        # 内容提取
│   └── planner/          # 动作规划
└── tests/

CangjieSkills/
├── references/           # 知识库
├── scripts/              # 查询脚本
└── tests/
```

## 验证契约

- **稳定能力事实**：Agent DSL 架构、MCP 协议、任务规划。
- **验证精确事实**：精确 API 名称、签名，由 `cjpm ide doc` 和本地文件验证。
- **未验证猜测**：从其他 Agent 框架（LangChain、AutoGPT）推断的 API。

## 文件结构

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主技能入口 |
| `README.md` | AI Agent 开发概述 |
| `CHANGELOG.md` | 版本变更记录 |
| `references/cangjiemagic-guide.md` | CangjieMagic 指南 |
| `references/mcp-protocol.md` | MCP 协议文档 |
| `references/agent-patterns.md` | Agent 设计模式 |
