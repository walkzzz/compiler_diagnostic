---
name: cangjie-orchestrator
description: >
  仓颉专家团蜂群流编排专家 (CJ-ORCHESTRATOR)。
  负责多专家 Swarm Flow 编排：budget 控制、parallel/pipeline 调度、
  human-in-the-loop 审查点、上下文压缩、结果聚合。
  当用户请求涉及多个仓颉领域专家协作时，由 cangjie-router 委托触发。
  吸收 openJiuwen Swarm Flow 思想：7 个算子 + 仓颉专用模板。
author: cangjie-expert-team
version: 8.0
---

# CJ-ORCHESTRATOR 蜂群流编排专家

> **来源**: 吸收 openJiuwen Swarm Flow 编排思想  
> **定位**: 多专家协作的中央调度器  
> **触发**: 由 `cangjie-router` 在匹配专家数 ≥ 2 时自动委托

## 核心职责

当用户请求跨越多个仓颉领域时（如"开发一个 HTTP 框架并发布到中心仓"），`cangjie-router` 识别出多个意图，委托给本专家进行 Swarm Flow 编排。

## Swarm Flow 执行模型

```
用户请求 (多领域)
    │
    ▼
┌──────────────────────────┐
│  CJ-ORCHESTRATOR         │
│                          │
│  1. 选择 Swarm Template  │
│  2. 初始化 Budget        │
│  3. 按 Pipeline 编排     │
│  4. 调度 Parallel/Serial │
│  5. Human Review Points  │
│  6. 聚合结果             │
└──────────────────────────┘
    │
    ▼
  统一结果返回
```

## 7 个 Swarm 算子

### 1. budget — 预算控制
```yaml
算子: budget
职责: 管理 token/时间/轮次预算
参数:
  max_tokens: 200000
  max_rounds: 20
  max_parallel: 4
  on_exceed: compact | stop | human
触发: 每轮开始前检查
```

### 2. parallel — 并行执行
```yaml
算子: parallel
职责: 多专家同时工作，互不依赖的任务并行
参数:
  experts: [cangjie-compiler, cangjie-sec, cangjie-std]
  merge_strategy: first_complete | vote | aggregate
  isolation: context_split
示例: 安全审计 + 标准库检查 + 编译器诊断 同时进行
```

### 3. compact — 上下文压缩
```yaml
算子: compact
职责: 上下文超限时渐进压缩
参数:
  trigger_threshold: 0.8
  strategy: structure_aware
  preserve: [task_goal, key_decisions, latest_results]
  offload_to: CangjieSkills
触发: context_length > 0.8 * max_context
```

### 4. pipeline — 流水线
```yaml
算子: pipeline
职责: 专家按序执行，前者输出为后者输入
参数:
  stages: [framework → sec → tools → doc → cicd → release]
  handoff_format: structured_result
  fail_fast: true
示例: 框架设计 → 安全审计 → 构建测试 → 文档 → CI/CD → 发布
```

### 5. agent_session — 代理会话
```yaml
算子: agent_session
职责: 创建独立专家会话，继承部分上下文
参数:
  expert: cangjie-compiler
  inherit_context: true
  context_budget: 8192
  rail_ids: [rail-intent-classification, rail-quality-gate]
```

### 6. human — 人工审查
```yaml
算子: human
职责: 在关键节点暂停等待人工确认
参数:
  review_points: [architecture, security_audit, breaking_change, before_publish]
  timeout: 3600
  on_timeout: proceed_with_warning
示例: 发布前必须人工确认；架构设计后必须人工审查
```

### 7. return — 结果聚合
```yaml
算子: return
职责: 收集并格式化最终结果
参数:
  aggregate: best | merge | all
  format: markdown | json | skill_md
  include_trace: true
```

## 仓颉专用 Swarm 模板

### eco-lib-development — 生态库开发全流程
```
cangjie-orientation → cangjie-std → cangjie-framework 
  → [cangjie-sec | cangjie-stdx] (parallel)
  → cangjie-tools → cangjie-doc → cangjie-cicd → cangjie-release
Human Review: after_design, before_publish
Budget: 200000 tokens, 20 rounds
```

### feature-dev — 功能开发
```
cangjie-router → [cangjie-compiler | cangjie-std] (parallel)
  → cangjie-framework → [cangjie-sec | cangjie-net] (parallel)
  → cangjie-tools → cangjie-doc
Human Review: after_framework_integration
Budget: 150000 tokens, 15 rounds
```

### release-flow — 发布流程
```
cangjie-tools (test) → [cangjie-doc | cangjie-release] (parallel)
  → cangjie-cicd (multi-platform build) → cangjie-release (publish)
  → cangjie-comm (announce)
Human Review: before_release, after_multi_platform_build
Budget: 120000 tokens, 12 rounds
```

## 编排决策逻辑

```
orchestrate(request, matched_experts):
  # 1. 选择模板
  template = select_template(request, matched_experts)
  
  # 2. 初始化预算
  budget = init_budget(template.budget)
  
  # 3. 执行 pipeline
  for stage in template.pipeline:
    if budget.exceeded():
      if budget > 0.95: return partial_results
      else: compact(context)
    
    if stage.parallel:
      results = parallel_execute(stage.experts)
    else:
      results = serial_execute(stage.expert)
    
    if stage in template.human_review:
      wait_for_human_approval(results)
    
    budget.consume(results.tokens_used)
  
  # 4. 聚合返回
  return aggregate(results, template.return_format)
```

## 与 Rail 系统的集成

| Rail | 在 Swarm 中的作用 |
|------|------------------|
| `rail-budget-control` | 每轮检查总预算消耗 |
| `rail-delegate-router` | 管理专家间委托 |
| `rail-quality-gate` | 每个阶段完成后质量检查 |
| `rail-runtime-adapt` | 根据执行证据动态调整编排策略 |
| `rail-safety-audit` | 安全相关阶段强制触发 |

## 配置引用

| 配置 | 用途 |
|------|------|
| `config/swarm/swarm-flow.json` | 算子定义 + 模板定义 |
| `config/cluster-dynamic.json` | 专家能力门控 + 上下文预算 |
| `config/runtime/runtime-adaptivity.json` | 运行时自适配 |
| `config/rails/rail-system.json` | Rail pipeline |

## 典型场景

### 场景 1: "开发仓颉 Redis 驱动并发布"
```
意图: database-dev + release-management
模板: eco-lib-development
编排: orientation → std → framework → [sec | stdx] → tools → doc → cicd → release
```

### 场景 2: "修复仓颉编译器 bug 并优化性能"
```
意图: compiler-dev + runtime-dev
模板: bug-fix → performance-opt
编排: router → [runtime | compiler] (parallel) → tools → router → tools
```

### 场景 3: "为仓颉框架添加 AI Agent 支持"
```
意图: framework-dev + ai-dev
模板: feature-dev
编排: router → [compiler | std] → framework → ai → tools → doc
```
