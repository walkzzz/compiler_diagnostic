# 仓颉专家天团动态执行框架架构设计

> 版本: v7.0
> 架构基础: openJiuwen (arXiv:2608.27969) — Beyond Static Harnesses for Long-Horizon Coding Agents
> 日期: 2026-09-05

## 1. 设计动机

### 传统静态路由器的三个结构性缺陷

| 缺陷 | 表现 | 后果 |
|------|------|------|
| 无法处理跨域任务 | "写 HTTP 服务器并发布" 横跨 3 域，只能选 1 个专家 | 用户需要手动分步请求 |
| 无法从失败恢复 | 技能执行失败后无重路由 | 用户手动重试 |
| 无法依据反馈调整 | 编译错误、测试失败不能反向影响编排 | 重复犯错 |

### openJiuwen 的解法

用**动态执行框架**替代静态路由：

```
Inner/Outer Loop (执行底座)
  + Rail (能力编排)
  + Swarm Flow (统一单/子/群)
  + Context Engine (上下文管理)
  + Self-Reflection (自反思)
  = 依据运行时证据动态改写执行
```

## 2. 五大子系统

### 2.1 Inner Loop — 执行底座

**职责**: 单次任务的推理-行动循环

```
InnerLoop(task, context, goal_mode):
  while not is_complete(task):
    1. Think:      intent = classify(task, context, feedback)
    2. Route:      skill = select_skill(intent, rails, context)
    3. Execute:    result = execute(skill, task, context, goal_mode)
    4. Observe:    feedback = observe(result, expected)
    5. Update:     context = update_context(context, result, feedback)
    6. Check:      if feedback.is_failure() and can_reroute(intent, context):
                     task = reformulate(task, feedback)
  return result
```

**8 种 Goal Mode**: normal, plan, code, review, debug, release, explore, swarm

每种模式有独立的执行策略、容错策略和上下文预算分配。

### 2.2 Outer Loop — 元层监控

**职责**: 监控 Inner Loop，在必要时介入调整

```
OuterLoop(task):
  plan = initial_plan(task, goal_mode)
  history = []
  while not is_complete(plan):
    result = InnerLoop(plan.current_step, context, goal_mode)
    eval = evaluate(result, plan.expected, history)
    history.append((plan.current_step, result, eval))
    if eval.needs_adjustment:
      plan = adjust_plan(plan, eval, history)
    plan.advance()
  reflect(history)
  return aggregate(history)
```

**6 种调整策略**: 技能失败重路由、编译错误注入上下文、跨3域升级swarm、超预算压缩、重复错误切debug、部分完成降级

### 2.3 Rail — 能力编排

**职责**: 为每个专家定义能力边界，执行前门控

每个专家的 Rail 定义 5 个维度：
- capabilities: 能做什么
- constraints: 不能做什么
- requires: 执行前需要什么
- provides: 执行后提供什么
- collaborates_with: 可联动的专家

**门控算法**: 路由前检查 Rail，不通过则重选专家

**组合规则**: Swarm 模式下多个 Rail 合并，冲突检测

### 2.4 Swarm Flow — 统一执行模式

**职责**: 将单专家、子代理、蜂群流统一在一套执行语义下

| 模式 | 专家数 | 执行方式 | 适用场景 |
|------|--------|----------|----------|
| Single | 1 | 直接执行 | 单域任务 |
| Sub-agent | 1主+N子 | 分发-收集 | 2域任务 |
| Swarm | N并行 | 并行-消息总线 | 3+域任务 |

**消息总线**: 专家间通过 request_help / provide_context / report_progress / share_artifact 通信

**4 种分解策略**: 串行依赖、并行独立、主从分发、迭代精化

### 2.5 Context Engine — 上下文管理

**职责**: 追踪上下文、管理 Token 预算、渐进披露、超预算压缩

**预算**: 总 32768 tokens，可用 20480，按任务描述/技能定义/Rail/证据/对话分配

**渐进披露**: 4 层，从必须加载到按预算加载

**4 种压缩策略**: 摘要压缩、时间窗口、证据优先、Rail 过滤

### 2.6 Self-Reflection — 自反思

**职责**: 任务后评估、路由权重更新、经验记录与回放

**6 种反思时机**: 任务完成、技能切换、错误恢复、模式升级、重路由、上下文压缩

**权重更新**: 成功组合 +LEARNING_RATE，失败组合 -LEARNING_RATE

**经验提炼**: 从多次反思中提取通用经验，供新任务参考

## 3. 子系统交互

```
用户请求
  │
  ▼
cangjie-router (兼容层)
  │  Rail pipeline 意图分类
  ├── 单域 → 直接路由到专家
  └── 多域 → 委托 cangjie-orchestrator
                │
                ▼
         Outer Loop
           │
           ▼
         Inner Loop
           ├── Think (Goal Mode 选择)
           ├── Route (Rail 门控)
           ├── Execute (Swarm Flow: Single/Sub/Swarm)
           ├── Observe (反馈收集)
           └── Update (Context Engine 更新)
           │
           ▼
         Monitor → Evaluate → Adjust
           │
           ▼
         Aggregate (结果聚合)
           │
           ▼
         Self-Reflection (经验记录, 权重更新)
           │
           ▼
         返回结果
```

## 4. 与 openJiuwen 的架构对应

| openJiuwen 概念 | Cangjie 对应 | 说明 |
|-------------------|-------------|------|
| Inner/Outer Loop | Inner/Outer Loop | 执行底座，推理-行动循环 |
| Rail | Rail | 能力编排，行为约束 |
| Swarm Flow | Swarm Flow | 统一单/子/群执行 |
| Context Management | Context Engine | 上下文预算和渐进披露 |
| Goal Mode | Goal Mode (8种) | 目标模式影响执行策略 |
| LSP 被动反馈 | Observe 步骤 | 运行时证据收集 |
| Self-Reflection | Self-Reflection | 自反思和权重更新 |
| ActionSpec | Rail YAML | 行为契约定义 |
| MessageQueue | MessageBus | 专家间通信 |
| Pregel graph | Outer Loop | 图执行引擎 |
| ReActAgent | Inner Loop | 推理-行动循环 |
| rsi | Self-Reflection | 运行时自检 |
| agent_evolving | weight_updates | 根据反馈优化路由 |
| JiuwenSwarm 8 modes | 8 Goal Modes | canonical mode 映射 |

## 5. 文件结构

```
skills/
  cangjie-orchestrator/          # 动态编排器 (执行层)
    SKILL.md                     # 五大子系统定义
    references/
      rail-specification.md      # Rail 系统完整规范
      swarm-flow.md              # Swarm Flow 协议
      context-engine.md          # Context Engine 设计
      self-reflection.md         # Self-Reflection 机制
      goal-modes.md              # Goal Mode 详细定义
  cangjie-router/                # 兼容层路由器
    SKILL.md                     # Rail pipeline + 意图分类
  cangjie-compiler/              # 17 个专家技能 (各有 Rail 定义)
  cangjie-runtime/
  cangjie-tools/
  ... (共 17 个专家)

docs/
  dynamic-harness-architecture.md  # 本文档
  仓颉开发专家天团.md               # 团队主文档 (v7.0)
```

## 6. 设计原则

1. **结构化可组合性** — 所有组件可组合，Rail 可合并，Swarm 可嵌套
2. **运行时自适配** — 依据执行反馈动态改写，不是静态写死
3. **渐进披露** — 只加载必要上下文，按需展开
4. **证据驱动** — 编译错误、测试结果等运行时证据驱动调整
5. **失败容忍** — 重路由、降级、升级，不轻易放弃
6. **经验积累** — 每次执行后反思，持续优化路由权重
