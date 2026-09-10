# 仓颉专家团执行底座 (Execution Substrate)

> **来源**: 吸收 openJiuwen 动态执行框架思想  
> **版本**: v8.0  
> **核心**: 用统一的 Inner/Outer Loop 底座，把"单专家、子代理、蜂群流"统一在一套执行语义下

---

## 1. 设计哲学

openJiuwen 的核心洞察：**不同粒度的执行（单智能体、子代理、蜂群流）可以共享同一套执行语义**，只要底座正确分层。

仓颉专家团吸收此思想，将原来的"静态路由 → 专家执行 → 返回"线性流程，改造为：

```
用户请求
    │
    ▼
┌─────────────────────────────────────────┐
│         Outer Loop (任务级)              │
│  ┌───────────────────────────────────┐  │
│  │       Inner Loop (轮次级)          │  │
│  │  ┌─────────┐    ┌─────────┐       │  │
│  │  │  Expert  │ ←→ │  Tools  │       │  │
│  │  │  (ReAct) │    │ (仓颉生态)│      │  │
│  │  └─────────┘    └─────────┘       │  │
│  │         ▲                         │  │
│  │     Rail Pipeline                 │  │
│  │  (pre_invoke → ... → post_invoke) │  │
│  └───────────────────────────────────┘  │
│                                         │
│  continue / resume / stop               │
│  (基于运行时证据动态决策)                 │
└─────────────────────────────────────────┘
    │
    ▼
  返回结果
```

## 2. Inner Loop — 专家-工具 ReAct 交互

Inner Loop 是单个专家在一轮中的执行循环：

```
InnerLoop(expert, task, context):
  round = 0
  while not goal_reached(task, context):
      round += 1
      
      // Rail: pre_invoke — 检查前置条件、注入上下文
      rail.fire("pre_invoke", expert, task, context)
      
      // Rail: on_round_start — 初始化本轮状态
      rail.fire("on_round_start", round, context)
      
      // 专家推理：选择下一个动作
      action = expert.think(task, context)
      
      // Rail: pre_model_call — 拦截/修改 LLM 调用参数
      rail.fire("pre_model_call", action)
      
      // 执行动作（调用仓颉工具链）
      result = execute(action, tools)
      
      // Rail: post_model_call — 处理模型输出
      rail.fire("post_model_call", result)
      
      // Rail: post_tool_call — 验证工具结果
      rail.fire("post_tool_call", action, result)
      
      // 更新上下文
      context.update(action, result)
      
      // Rail: on_goal_check — 检查是否达成目标
      if rail.fire("on_goal_check", task, context):
          break
      
      // Rail: on_round_end — 本轮收尾
      rail.fire("on_round_end", round, context)
      
      // 运行时自适配：检查是否需要调整策略
      adapt_runtime(context)
  
  // Rail: post_invoke — 后置处理、结果格式化
  rail.fire("post_invoke", expert, task, context)
  
  return context.result
```

### 仓颉工具层

Inner Loop 中的 Tools 不是通用工具，而是仓颉生态的具体工具：

| 工具类别 | 具体工具 | 对应专家 |
|---------|---------|---------|
| 编译 | `cjpm build`, `cjc`, `cjfmt` | CJ-COMP, CJ-TOOLS |
| 运行 | `cjpm run`, `cjprof` | CJ-RUNTIME |
| 测试 | `cjpm test`, `cjlint` | CJ-TOOLS |
| 文档 | `cjdoc`, `mdgen` | CJ-DOC, CJ-SKILL |
| 发布 | `release.sh`, `gh release` | CJ-RELEASE, CJ-CICD |
| 知识库 | `CangjieSkills.query()` | CJ-KNOWLEDGE |
| AI | `CangjieMagic.invoke()` | CJ-AI |

## 3. Outer Loop — 任务级控制

Outer Loop 管理任务的生命周期，决定 continue/resume/stop：

```
OuterLoop(task, swarm_config):
  state = "running"
  results = []
  
  while state == "running":
      // 执行一个 Inner Loop 阶段
      result = InnerLoop(selected_expert, task, context)
      results.append(result)
      
      // 基于运行时证据决策
      evidence = collect_evidence(results, context)
      
      match decide(evidence):
          "continue"  => state = "running"     // 继续执行
          "resume"    => state = "running"     // 恢复中断的任务
          "complete"  => state = "done"        // 任务完成
          "blocked"   => state = "blocked"     // 需要人工介入
          "stop"      => state = "stopped"     // 主动停止
  
  return results
```

### 决策依据（运行时证据）

| 证据类型 | 来源 | 影响 |
|---------|------|------|
| 目标达成度 | on_goal_check hook | continue → complete |
| 预算消耗 | budget operator | continue → stop |
| 错误率 | on_exception hook | continue → blocked |
| 上下文长度 | context_management | 触发压缩 |
| LSP 诊断 | lsp_driven_passive_feedback | 注入修复建议 |
| 历史经验 | self_reflection | 调整策略 |

## 4. 三种执行模式统一

执行底座的关键：单专家、子代理、蜂群流共享同一个 Inner/Outer Loop，只是参数不同。

### 4.1 单专家模式

```yaml
mode: single_expert
inner_loop:
  expert: cangjie-compiler
  max_rounds: 10
  tools: [cjpm, cjc, cjfmt]
outer_loop:
  decision: simple_goal_check
```

### 4.2 子代理模式

```yaml
mode: sub_agent
inner_loop:
  expert: cangjie-router  # 路由器作为代理
  max_rounds: 5
  delegate: true          # 委托给目标专家
  tools: [route, load_skill]
outer_loop:
  decision: delegate_result_check
```

### 4.3 蜂群流模式

```yaml
mode: swarm
inner_loop:
  expert: cangjie-orchestrator  # 编排专家
  max_rounds: 20
  swarm: true
  operators: [budget, parallel, pipeline, compact, human, return]
outer_loop:
  decision: swarm_completion_check
  budget_limit: 100000  # tokens
  parallel_max: 4       # 并行专家数
```

## 5. 与 Rail 系统的关系

执行底座本身不包含业务逻辑，所有横切关注点通过 Rail 注入：

```
执行底座 (本文件)
    │
    ├── Rail: 意图分类 Rail     → 决定选哪个专家
    ├── Rail: 安全审计 Rail     → 检查代码安全性
    ├── Rail: 知识注入 Rail     → 从 CangjieSkills 注入上下文
    ├── Rail: 质量检查 Rail     → 代码审查 + Lint
    ├── Rail: 文档生成 Rail     → 自动生成 SKILL.md
    ├── Rail: 预算控制 Rail     → token/时间预算
    └── Rail: 自适配 Rail       → 运行时策略调整
```

Rail 的定义见 `config/rails/rail-system.json`。

## 6. SOTA 目标

openJiuwen 凭此架构在 SWE-bench Verified (82.6%) 与 Terminal-Bench 2.1 (87.19%) 上取得 SOTA 级提升。

仓颉专家团吸收此架构后，目标：

| 基准 | 当前 | 目标 |
|------|------|------|
| 仓颉编译正确率 | ~85% | 95%+ |
| 仓颉代码生成通过率 | ~70% | 90%+ |
| 多专家协作成功率 | N/A | 85%+ |
| 运行时自适配命中率 | N/A | 80%+ |
