# Self-Reflection 机制

> 参考: openJiuwen rsi (runtime self-inspection) + agent_evolving (prompt optimization)
> 状态: v7.0 设计文档

## 1. 反思时机

| 时机 | 触发条件 | 记录内容 |
|------|----------|----------|
| 任务完成 | task.is_complete | 整体执行评估、成功/失败、耗时 |
| 技能切换 | skill != previous_skill | 切换原因、切换前后对比 |
| 错误恢复 | error_recovered | 错误描述、修复方法、恢复步骤 |
| 模式升级 | mode_changed (e.g. Single->Swarm) | 升级原因、升级后效果 |
| 重路由 | rerouted | 原路由目标、新路由目标、原因 |
| 上下文压缩 | context_compressed | 压缩前大小、压缩后大小、策略 |

## 2. 反思记录格式

```yaml
reflection:
  id: "ref-2026-09-05-001"
  timestamp: "2026-09-05T10:30:00Z"

  task:
    description: "用仓颉写 HTTP 服务器并发布"
    goal_mode: "swarm"
    domains: [framework, net, cicd]
    complexity: HIGH

  execution:
    experts_used: [cangjie-framework, cangjie-net, cangjie-cicd]
    swarm_mode: Swarm
    steps: 7
    duration_seconds: 120

  result:
    success: true
    artifacts:
      - "src/server.cj"
      - ".github/workflows/build.yml"
    errors_encountered: 1
    reroutes: 1

  decisions:
    - id: "dec-1"
      type: "mode_upgrade"
      from: "SubAgent"
      to: "Swarm"
      reason: "任务横跨 3 个域"
      timestamp: "2026-09-05T10:01:00Z"

    - id: "dec-2"
      type: "reroute"
      from: "cangjie-framework"
      to: "cangjie-net"
      reason: "framework 专家缺少 HTTP API 知识"
      timestamp: "2026-09-05T10:05:00Z"

  lessons:
    - "framework+net 组合时，先让 net 提供 API 骨架，再让 framework 集成"
    - "cicd 专家需要项目结构信息，应在 framework 完成后触发"

  weight_updates:
    "framework->net": +0.1
    "net->cicd": +0.05
    "framework->cicd": +0.05
```

## 3. 反思评估指标

### 执行质量评分

```
quality_score(reflection):
  score = 0

  # 成功基础分
  if reflection.success: score += 50

  # 效率分 (步数越少越好)
  if reflection.steps <= 3: score += 20
  elif reflection.steps <= 7: score += 10
  else: score += 5

  # 准确性分 (重路由越少越好)
  if reflection.reroutes == 0: score += 20
  elif reflection.reroutes == 1: score += 10
  else: score += 0

  # 健壮性分 (错误恢复)
  if reflection.errors_encountered == 0: score += 10
  elif reflection.error_recovered: score += 5

  return score  # 0-100
```

### 质量等级

| 分数 | 等级 | 说明 |
|------|------|------|
| 90-100 | S | 完美执行，无需调整 |
| 70-89 | A | 良好执行，小幅优化 |
| 50-69 | B | 合格执行，有改进空间 |
| 30-49 | C | 勉强完成，需要调整 |
| 0-29 | D | 失败或严重低效 |

## 4. 路由权重更新

### 权重矩阵

```
WeightMatrix[expert_a][expert_b] = affinity_score

初始值: 所有专家对 affinity = 0.5 (中性)
范围: [0.0, 1.0]
学习率: LEARNING_RATE = 0.05
```

### 更新算法

```
update_weights(reflection):
  if reflection.success:
    # 成功组合: 增加亲和度
    for expert_a, expert_b in pairs(reflection.experts_used):
      WeightMatrix[a][b] += LEARNING_RATE
      WeightMatrix[a][b] = min(1.0, WeightMatrix[a][b])

  else:
    # 失败组合: 降低亲和度
    for expert_a, expert_b in pairs(reflection.experts_used):
      WeightMatrix[a][b] -= LEARNING_RATE
      WeightMatrix[a][b] = max(0.0, WeightMatrix[a][b])

  # 应用反思中显式指定的权重更新
  for pair, delta in reflection.weight_updates:
    WeightMatrix[pair] += delta
    WeightMatrix[pair] = clamp(0.0, 1.0, WeightMatrix[pair])
```

### 权重影响路由

```
select_skill_with_weights(intent, candidates):
  # 基础匹配分
  scores = {skill: base_match(intent, skill) for skill in candidates}

  # 加上亲和度加成
  for skill in candidates:
    for prev_skill in context.previous_skills:
      scores[skill] += WeightMatrix[prev_skill][skill] * 0.3

  # 选最高分
  return max(scores, key=scores.get)
```

## 5. 经验持久化

### 经验库结构

```
experience_store/
  reflections/
    2026-09-05/
      ref-001.yaml  # 每次反思一个文件
      ref-002.yaml
  weights/
    weight-matrix.yaml  # 当前权重矩阵快照
  lessons/
    compiled-lessons.md  # 从多次反思中提炼的通用经验
```

### 经验回放

新任务开始时，编排器可以查询历史经验：

```
recall_relevant_experience(task):
  # 找到类似任务的历史反思
  similar = find_similar_tasks(task, threshold=0.7)

  # 提取可复用的经验
  lessons = []
  for ref in similar:
    if ref.success:
      lessons.extend(ref.lessons)

  # 注入到上下文
  if lessons:
    context.experience = deduplicate(lessons)

  return context
```

## 6. 经验提炼

定期从大量反思记录中提炼通用经验：

```
compile_lessons(reflections):
  # 按模式分组
  groups = group_by(reflections, key=lambda r: (r.task.pattern, r.task.domains))

  compiled = []
  for pattern, refs in groups:
    success_refs = [r for r in refs if r.success]
    if len(success_refs) >= 3:  # 至少3次成功才提炼
      # 提取共同经验
      common = find_common_lessons(success_refs)
      compiled.append({
        pattern: pattern,
        best_practice: common,
        success_rate: len(success_refs) / len(refs)
      })

  return compiled
```

提炼后的经验写入 `lessons/compiled-lessons.md`，供编排器在新任务时参考。

## 7. 与 openJiuwen 的对应

| openJiuwen 概念 | Cangjie 对应 | 说明 |
|-------------------|-------------|------|
| rsi (runtime self-inspection) | Self-Reflection | 运行时自检和反思 |
| agent_evolving (prompt optimization) | weight_updates | 根据反馈优化路由 |
| memory (long-term) | experience_store | 经验持久化 |
| context_engine (compression) | 经验回放时的上下文注入 | 从历史中提取相关经验 |
