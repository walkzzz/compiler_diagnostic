# Swarm Flow 协议

> 参考: openJiuwen 结构化可组合性 + JiuwenSwarm 8 canonical modes
> 状态: v7.0 设计文档

## 1. 三种执行模式

### Single (单专家模式)

```
Single(task, skill):
  result = skill.execute(task)
  return result
```

适用：单域任务，如 "ArrayList 怎么用"

### Sub-agent (子代理模式)

```
SubAgent(task, primary_skill, sub_skills):
  plan = primary_skill.decompose(task)
  sub_results = []
  for sub_task in plan:
    sub_skill = select_sub_skill(sub_task, sub_skills)
    sub_result = sub_skill.execute(sub_task)
    sub_results.append(sub_result)
  final = primary_skill.aggregate(sub_results)
  return final
```

适用：2 域任务，如 "编译报错找不到 ArrayList" (compiler 主 + std 子)

### Swarm (蜂群模式)

```
Swarm(task, experts, message_bus):
  sub_tasks = decompose(task, experts)
  assignments = assign_by_rail(sub_tasks, experts)

  # 并行执行
  futures = [parallel_execute(expert, sub_task)
             for expert, sub_task in assignments]

  # 消息总线通信
  while any(f.running for f in futures):
    msg = message_bus.poll()
    if msg.type == "request_help":
      response = route_to_expert(msg.target, msg.question)
      message_bus.send(msg.source, response)
    if msg.type == "provide_context":
      update_context(msg.target, msg.context)

  results = [f.result for f in futures]
  final = weighted_merge(results, routing_weights)
  return final
```

适用：3+ 域任务，如 "用仓颉写 HTTP 服务器并发布" (framework + net + cicd)

## 2. 模式选择策略

```
select_mode(task):
  domains = detect_domains(task)
  complexity = estimate_complexity(task)
  dependencies = analyze_dependencies(task)

  # 单域 -> Single
  if len(domains) <= 1:
    return Single

  # 两域 + 低复杂度 + 无并行需求 -> Sub-agent
  if len(domains) == 2 and complexity < HIGH:
    return SubAgent

  # 两域 + 高复杂度 或 3+域 -> Swarm
  if len(domains) >= 3 or (len(domains) == 2 and complexity >= HIGH):
    return Swarm

  # 默认
  return Single
```

### 复杂度评估

```
estimate_complexity(task):
  score = 0
  score += len(task.sub_tasks) * 1          # 子任务数
  score += len(task.files_to_modify) * 2     # 涉及文件数
  score += task.estimated_steps * 1          # 预估步骤数
  if task.requires_compilation: score += 5   # 需要编译
  if task.requires_testing: score += 3       # 需要测试
  if task.cross_platform: score += 5         # 跨平台

  if score < 10: return LOW
  if score < 20: return MEDIUM
  return HIGH
```

## 3. 消息总线

专家间通信协议：

### 消息类型

| 类型 | 方向 | 说明 |
|------|------|------|
| request_help | expert -> expert | 请求另一个专家提供帮助 |
| provide_context | expert -> expert | 主动提供上下文给另一个专家 |
| report_progress | expert -> orchestrator | 向编排器报告进度 |
| report_blocker | expert -> orchestrator | 报告阻塞问题 |
| share_artifact | expert -> expert | 分享产出物 (代码, 配置) |

### 消息格式

```yaml
message:
  id: uuid
  type: request_help
  source: cangjie-framework
  target: cangjie-net
  content: "需要 HTTP handler 接口定义"
  context:
    task_id: "http-server-001"
    priority: high
  timestamp: "2026-09-05T10:00:00Z"
```

## 4. 任务分解

### 分解策略选择

```
decompose(task, experts):
  deps = analyze_dependencies(task)

  if deps.is_serial():
    return serial_decompose(task, deps)      # 串行依赖

  if deps.is_parallel():
    return parallel_decompose(task, deps)    # 并行独立

  if deps.is_master_slave():
    return master_slave_decompose(task, deps) # 主从分发

  if deps.is_iterative():
    return iterative_decompose(task, deps)    # 迭代精化
```

### 串行分解

```
serial_decompose(task, deps):
  # 按拓扑排序
  order = topological_sort(deps)
  sub_tasks = []
  for step in order:
    sub_task = extract_sub_task(task, step)
    sub_tasks.append(sub_task)
  return sub_tasks  # 按顺序执行
```

示例：编译 -> 测试 -> 打包 -> 发布

### 并行分解

```
parallel_decompose(task, deps):
  # 无依赖关系的子任务同时执行
  groups = group_by_independence(deps)
  sub_tasks = []
  for group in groups:
    for step in group:
      sub_tasks.append(extract_sub_task(task, step))
  return sub_tasks  # 同组并行，组间串行
```

示例：同时查 std API + stdx API + net API

### 主从分解

```
master_slave_decompose(task, deps):
  master_task = extract_master_task(task)
  slave_tasks = []
  for domain in task.domains[1:]:
    slave_task = extract_slave_task(task, domain)
    slave_tasks.append(slave_task)
  return [master_task] + slave_tasks
```

示例：framework 设计主任务 -> std + net + sec 实现子任务

## 5. 结果聚合

### 聚合策略

| 策略 | 适用场景 | 说明 |
|------|----------|------|
| 顺序合并 | 串行任务 | 后一步依赖前一步输出 |
| 并集合并 | 并行任务 | 取所有结果的并集 |
| 加权合并 | Swarm | 按路由权重加权选择最佳结果 |
| 冲突解决 | 有冲突 | 优先级高的专家胜出 |

### 冲突解决

```
resolve_conflict(results):
  # 多个专家对同一问题给出不同答案
  # 按优先级排序
  ranked = sort_by_priority(results, routing_weights)
  # 取最高优先级
  return ranked[0]
  # 记录冲突到反思日志
  reflect("conflict resolved: " + str(results))
```

## 6. JiuwenSwarm 模式映射

参考 JiuwenSwarm 的 8 种 canonical mode (role.environment.state)：

| JiuwenSwarm Mode | Cangjie 对应 | 说明 |
|-------------------|-------------|------|
| agent.work.normal | Single + normal | 单专家直接执行 |
| agent.work.plan | Single + plan | 单专家规划模式 |
| agent.code.normal | Single + code | 单专家编码模式 |
| agent.code.plan | SubAgent + plan | 主专家规划+子专家编码 |
| team.work.normal | Swarm + normal | 多专家并行 |
| team.work.plan | Swarm + plan | 多专家规划 |
| team.code.normal | Swarm + code | 多专家编码 |
| team.code.plan | Swarm + code + plan | 多专家规划+编码 |
