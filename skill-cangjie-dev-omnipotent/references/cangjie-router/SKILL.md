---
name: cangjie-router
description: >
  仓颉专家团 Rail 编排路由器 (v8.0 openJiuwen 改造)。
  通过 Rail pipeline 进行意图分类和专家路由，支持 Swarm Flow 多专家编排，
  支持运行时自适配（上下文管理/目标模式/LSP 反馈/自反思）。
  当用户请求涉及仓颉编程语言任何方面时，使用此技能进行 Rail 编排路由。
author: cangjie-expert-team
version: 8.0
---

# 仓颉专家团 Rail 编排路由器

> **v8.0 改造**: 吸收 openJiuwen 动态执行框架，从静态关键词路由升级为 Rail 编排路由

## 架构变更说明

### v7.0 (旧): 静态关键词路由
```
用户请求 → 关键词匹配 → 选专家 → 执行 → 返回
```

### v8.0 (新): Rail 编排路由
```
用户请求 → Rail pipeline → 意图分类 → 专家选择 → Swarm Flow 编排 → 运行时自适配 → 返回
```

## Rail Pipeline 路由算法

### Phase 1: pre_invoke — 意图分类

触发 `rail-intent-classification` (priority=10):

1. **提取用户核心任务**：剥离寒暄、上下文设置、元问题
2. **分类请求**：归入意图类别（见下方路由表）
3. **置信度检查**：若置信度 < 0.7，触发 `rail-delegate-router` 的 `on_delegate` hook 请求澄清

### Phase 2: on_round_start — 知识注入

触发 `rail-knowledge-injection` (priority=20):

1. 从 `CangjieSkills` 知识库检索与意图相关的上下文
2. 渐进披露：仅注入最小必要知识（max 4096 tokens）
3. 结构感知：按仓颉代码语义块组织注入内容

### Phase 3: 专家选择与加载

根据 `config/cluster-dynamic.json` 选择专家:

1. 查找匹配意图的专家列表
2. 若匹配专家数 ≥ 2（`swarm_trigger_threshold`）→ 触发 Swarm Flow（委托 `cangjie-orchestrator`）
3. 若匹配专家数 = 1 → 直接加载目标专家
4. 若匹配专家数 = 0 → 回退到 `cangjie-orientation`

### Phase 4: 执行与 Rail 监控

专家执行 Inner Loop，以下 Rail 在各 hook 点触发:

| Hook | Rail | 作用 |
|------|------|------|
| `pre_model_call` | `rail-budget-control` | 检查 token/轮次预算 |
| `post_model_call` | `rail-runtime-adapt` | 运行时策略调整 |
| `post_tool_call` | `rail-safety-audit` + `rail-cangjie-lsp` | 安全检查 + LSP 诊断注入 |
| `on_round_end` | `rail-quality-gate` + `rail-runtime-adapt` | 质量检查 + 自适配 |
| `on_delegate` | `rail-delegate-router` | 多专家委托编排 |
| `on_task_complete` | `rail-doc-generation` + `rail-release-verification` | 文档生成 + 发布验证 |

### Phase 5: post_invoke — 结果格式化

1. 收集所有 Rail 的执行结果
2. 格式化最终输出
3. 触发 `self_reflection` 提取可复用经验

## 意图路由表

| 意图 | 触发关键词 | 目标专家 | Swarm 模板 |
|------|----------|---------|-----------|
| 编译器开发 | 编译器、词法分析、IR、代码生成 | cangjie-compiler | feature-dev |
| 运行时开发 | 运行时、GC、线程、FFI | cangjie-runtime | feature-dev |
| 工具链 | cjpm、cjfmt、cjprof、cjlint | cangjie-tools | feature-dev |
| 标准库 | std.、集合、IO、文件 | cangjie-std | feature-dev |
| 扩展库 | stdx、HTTP、加密、日志 | cangjie-stdx | eco-lib-development |
| 应用框架 | cjoy、tea、IoC、REST | cangjie-framework | new-project |
| 数据库 | SQL、ORM、Redis、驱动 | cangjie-db | feature-dev |
| 网络 | HTTP、WebSocket、MQTT、RPC | cangjie-net | feature-dev |
| AI Agent | AI、Agent、MCP、LLM | cangjie-ai | feature-dev |
| 安全 | 安全、加密、SM4、TLS | cangjie-sec | feature-dev |
| UI | UI、动画、组件、布局 | cangjie-ui | feature-dev |
| 发布管理 | 发布、release、版本、构建 | cangjie-release | release-flow |
| CI/CD | CI/CD、GitHub Actions、构建矩阵 | cangjie-cicd | release-flow |
| 文档治理 | 文档、README、CHANGELOG | cangjie-doc | release-flow |
| 教育推广 | 教育、课程、教材、培训 | cangjie-edu | — |
| 社区运营 | 社区、论坛、活动、贡献 | cangjie-comm | — |
| 通用问答 | 仓颉、如何、是什么 | cangjie-orientation | — |
| 多领域 | 跨多个领域 | cangjie-orchestrator | 按需选择 |

## Swarm Flow 触发条件

当用户请求涉及多个领域时（如"开发一个仓颉 HTTP 框架并发布到中心仓"），自动触发 Swarm Flow:

```
1. rail-intent-classification 识别出多个意图: framework-dev + release-management
2. 匹配专家数 ≥ swarm_trigger_threshold (2)
3. 委托给 cangjie-orchestrator
4. orchestrator 选择 swarm_template: "eco-lib-development"
5. 按 pipeline 编排: framework → sec → tools → doc → cicd → release
6. 各阶段专家并行/串行执行，budget 控制
7. human review point: before_publish
```

## 运行时自适配

路由器在执行过程中持续收集运行时证据，动态调整:

| 证据 | 自适配动作 |
|------|-----------|
| 上下文超限 | 触发 `compact` 算子，渐进压缩 |
| LSP 报错 | 注入修复建议到下一轮 |
| 预算不足 80% | 标记 warning，准备 compact |
| 预算不足 95% | 触发 `stop`，返回部分结果 |
| 连续 3 轮无进展 | 触发 `blocked`，请求人工介入 |
| 任务完成 | 触发 `self_reflection`，提取经验 |

## 配置引用

| 配置文件 | 用途 |
|---------|------|
| `config/execution-substrate.md` | Inner/Outer Loop 执行底座定义 |
| `config/rails/rail-system.json` | Rail 系统定义（10 个 Rail） |
| `config/swarm/swarm-flow.json` | Swarm 算子 + 模板定义 |
| `config/runtime/runtime-adaptivity.json` | 运行时自适配 4 机制 |
| `config/cluster-dynamic.json` | 动态专家集群配置（20 个专家） |

## 回退行为

1. Rail pipeline 执行失败 → 退化为 v7.0 静态关键词路由
2. 无匹配专家 → `cangjie-orientation`
3. 非仓颉请求 → 直接回答，不加载任何技能

## 输出

- **单专家**: `skill: <name>` — 加载目标专家执行
- **Swarm Flow**: `swarm: <template>` — 委托给 `cangjie-orchestrator`
- **需要澄清**: 在路由前向用户提出澄清问题
- **回退**: `fallback: cangjie-orientation`


## 与 cangjie-orchestrator 的关系

cangjie-router 是**兼容层**，cangjie-orchestrator 是**执行层**：

```
用户请求 → cangjie-router (兼容层: Rail pipeline, 意图分类)
  ├── 单域任务 → 直接路由到专家
  ├── 多域任务 → 委托 cangjie-orchestrator (执行层: Swarm Flow)
  └── 失败回退 → v7.0 静态路由 → cangjie-orientation
```

- **cangjie-router** 负责：Rail pipeline 意图分类、置信度检查、专家选择
- **cangjie-orchestrator** 负责：Inner/Outer Loop 执行、Swarm Flow 编排、Context Engine、Self-Reflection
- **回退**：当 Rail pipeline 失败时，退化为 v7.0 静态关键词路由
