# Goal Mode 详细定义

> 参考: JiuwenSwarm 8 canonical modes (role.environment.state)
> 状态: v7.0 设计文档

## 8 种 Goal Mode

### normal (默认模式)

```yaml
mode: normal
trigger: 默认
strategy: 直接执行，快速返回
inner_loop: 1 轮 Think-Route-Execute-Observe
error_handling: 失败即返回，不重试
context_budget: 标准 (20480 tokens)
swarm_mode: Single
```

### plan (规划模式)

```yaml
mode: plan
trigger: "规划" "设计" "方案" "计划" "architecture"
strategy: 先规划再执行，产出计划文档
inner_loop:
  1. Think: 分析需求，识别约束
  2. Route: 路由到规划专家
  3. Execute: 产出设计方案
  4. Observe: 用户确认方案
  5. 如确认: 进入 code 模式执行
error_handling: 规划失败降级为 normal
context_budget: 偏大 (给规划更多空间)
swarm_mode: SubAgent (主专家规划 + 子专家提供约束)
output: 设计文档 + 执行计划
```

### code (编码模式)

```yaml
mode: code
trigger: "写" "实现" "开发" "编码" "code" "implement"
strategy: 编译验证循环，紧密反馈
inner_loop:
  1. Think: 理解编码任务
  2. Route: 路由到实现专家
  3. Execute: 编写代码
  4. Observe: cjpm check 编译验证
  5. 如编译失败: 查 API -> 修改 -> 重新编译
  6. 如编译成功: cjpm test 测试验证
error_handling: 编译失败查 API 重试，最多 3 轮
context_budget: 标准偏证据 (给编译错误更多空间)
swarm_mode: SubAgent 或 Swarm (取决于跨域数)
output: 可编译的代码 + 测试结果
```

### review (审查模式)

```yaml
mode: review
trigger: "审查" "review" "检查" "audit" "lint"
strategy: 只读分析，不修改代码
inner_loop:
  1. Think: 理解审查目标
  2. Route: 路由到审查专家
  3. Execute: 分析代码/配置
  4. Observe: 产出审查报告
error_handling: N/A (只读不修改)
context_budget: 偏大 (需要读取大量代码)
swarm_mode: SubAgent (主审查 + 子专家提供标准)
output: 审查报告 + 改进建议
constraints: [no-code-modification]
```

### debug (调试模式)

```yaml
mode: debug
trigger: "报错" "不工作" "失败" "error" "bug" "fix"
strategy: 复现 -> 定位 -> 修复 -> 验证
inner_loop:
  1. Think: 分析错误信息
  2. Route: 路由到相关域专家
  3. Execute: 复现问题
  4. Observe: 定位根因
  5. Execute: 修复
  6. Observe: 验证修复
  7. 如未修复: 切换专家或升级到 swarm
error_handling: 修复失败升级到 swarm 模式
context_budget: 偏证据 (优先保留错误信息)
swarm_mode: SubAgent -> Swarm (如单专家无法修复)
output: 修复后的代码 + 根因分析
```

### release (发布模式)

```yaml
mode: release
trigger: "发布" "release" "CI/CD" "deploy" "打包"
strategy: 检查清单驱动，逐步确认
inner_loop:
  1. Think: 理解发布需求
  2. Route: 路由到 cangjie-release 或 cangjie-cicd
  3. Execute: 执行检查清单
  4. Observe: 每步确认
  5. 如中断: 停止，保留已完成步骤
error_handling: 中断即停止，不自动重试
context_budget: 标准
swarm_mode: SubAgent (release 主 + cicd/doc 子)
output: 发布产物 + 发布说明
requires_confirmation: true  # 每个关键步骤需要用户确认
```

### explore (探索模式)

```yaml
mode: explore
trigger: "有什么" "了解" "介绍" "怎么用" "什么是"
strategy: 渐进披露，最小上下文
inner_loop:
  1. Think: 理解探索意图
  2. Route: 路由到 cangjie-orientation 或相关专家
  3. Execute: 加载最小信息
  4. Observe: 用户是否需要更多
  5. 如需要: 加载更多 (渐进披露)
error_handling: N/A
context_budget: 最小 (只加载必要信息)
swarm_mode: Single
output: 简明回答 + 进一步探索的选项
```

### swarm (蜂群模式)

```yaml
mode: swarm
trigger: 跨3+域 或 高复杂度 或 显式要求"用多个专家"
strategy: 多专家并行，结果聚合
inner_loop:
  1. Think: 分析任务，识别域
  2. Decompose: 分解为子任务
  3. Assign: 按 Rail 分配专家
  4. Parallel: 并行执行
  5. MessageBus: 专家间通信
  6. Aggregate: 结果聚合
  7. Verify: 验证最终结果
error_handling: 单专家失败降级继续
context_budget: 偏大 (多专家需要更多上下文)
swarm_mode: Swarm
output: 聚合结果 + 各专家产出
```

## 模式转换规则

```
模式转换图:

normal ──(检测到3+域)──> swarm
normal ──(检测到"写/实现")──> code
normal ──(检测到"报错")──> debug
normal ──(检测到"发布")──> release
normal ──(检测到"规划")──> plan
normal ──(检测到"审查")──> review
normal ──(检测到"了解")──> explore

code ──(编译失败2次)──> debug
code ──(检测到3+域)──> swarm
debug ──(单专家失败)──> swarm
plan ──(规划完成)──> code
SubAgent ──(检测到3+域)──> swarm
```

## 与 JiuwenSwarm 的映射

| JiuwenSwarm canonical mode | Cangjie goal_mode | swarm_mode |
|---------------------------|-------------------|------------|
| agent.work.normal | normal | Single |
| agent.work.plan | plan | Single |
| agent.code.normal | code | Single |
| agent.code.plan | plan -> code | SubAgent |
| team.work.normal | normal | Swarm |
| team.work.plan | plan | Swarm |
| team.code.normal | code | Swarm |
| team.code.plan | plan -> code | Swarm |
