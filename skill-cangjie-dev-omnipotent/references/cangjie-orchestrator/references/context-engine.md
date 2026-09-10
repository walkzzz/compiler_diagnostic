# Context Engine 设计

> 参考: openJiuwen context_engine (window management, token counting, compression)
> 状态: v7.0 设计文档

## 1. 上下文预算

### 总预算分配

```
Total: 32768 tokens (典型 LLM 上下文窗口)

  System Prompt Reserve:    4096 tokens  (系统指令, 不可压缩)
  Output Reserve:           8192 tokens  (输出空间, 不可压缩)
  ─────────────────────────────────────
  Available:               20480 tokens  (可分配上下文)

  Available 细分:
    任务描述:        1024 tokens
    技能定义:        2048 tokens  (SKILL.md)
    Rail 定义:       1024 tokens
    已加载证据:      8192 tokens  (编译错误, API 查询结果等)
    对话历史:        8192 tokens
    ─────────────────────────────
    余量:           20480 - 20480 = 0  (满载)
```

### 动态调整

当任务复杂度不同时，预算分配可动态调整：

| 场景 | 任务描述 | 技能定义 | 证据 | 对话 |
|------|----------|----------|------|------|
| 简单问答 | 512 | 1024 | 2048 | 4096 |
| 编码任务 | 1024 | 2048 | 8192 | 4096 |
| Swarm 任务 | 2048 | 4096 | 8192 | 2048 |
| Debug 任务 | 1024 | 2048 | 12288 | 2048 |

## 2. 渐进披露

### 披露层级

```
Layer 0 (必须加载, ~4KB):
  - 任务描述
  - 技能 SKILL.md 主体
  - Rail 定义

Layer 1 (budget > 8KB, ~4KB):
  - 技能 references/ 中的相关文档
  - 常见 API 签名

Layer 2 (budget > 12KB, ~4KB):
  - 知识库相关条目
  - 示例代码

Layer 3 (budget > 16KB, ~4KB):
  - 详细 API 文档
  - 完整代码示例
  - 相关 issue/PR 历史
```

### 披露算法

```
progressive_disclosure(task, skill, budget):
  context = {}

  # Layer 0: 必须
  context.task = load_task_description(task)
  context.skill = load_skill_body(skill)
  context.rail = load_rail(skill)

  remaining = budget - size(context)

  # Layer 1: 相关文档
  if remaining > 4096:
    refs = select_relevant_refs(skill, task)
    context.refs = load_refs(refs, max_tokens=4096)
    remaining -= size(context.refs)

  # Layer 2: 知识库
  if remaining > 4096:
    kb = query_knowledge_base(task, top_k=5)
    context.kb = load_kb_entries(kb, max_tokens=4096)
    remaining -= size(context.kb)

  # Layer 3: 详细文档
  if remaining > 4096:
    docs = query_api_docs(task, top_k=3)
    context.docs = load_docs(docs, max_tokens=remaining)

  return context
```

### 相关性排序

选择 references 文档时按相关性排序：

```
relevance_score(doc, task):
  score = 0
  # 关键词匹配
  for keyword in task.keywords:
    if keyword in doc: score += 1
  # 意图匹配
  if task.intent == doc.intent: score += 3
  # Rail 能力匹配
  if task.required_caps ∩ doc.covered_caps: score += 2
  return score
```

## 3. 上下文压缩

### 触发条件

- 上下文使用超过预算的 90%
- 新证据需要加载但预算不足
- 对话历史过长导致性能下降

### 压缩策略

#### 策略 1: 摘要压缩

```
summarize_compression(history):
  # 保留关键信息，压缩中间步骤
  preserved = []
  for entry in history:
    if entry.type in [ERROR, RESULT, DECISION]:
      preserved.append(entry)  # 保留
    elif entry.type == REASONING:
      preserved.append(summarize(entry))  # 压缩为摘要
    else:
      skip(entry)  # 丢弃
  return preserved
```

保留优先级：错误信息 > 最终结果 > 关键决策 > 推理步骤 > 探索输出

#### 策略 2: 时间窗口

```
window_compression(history, window=5):
  # 只保留最近 N 轮交互
  return history[-window:]
```

#### 策略 3: 证据优先

```
evidence_compression(history, budget):
  # 优先保留有证据价值的条目
  evidence = [e for e in history if e.has_evidence]
  other = [e for e in history if not e.has_evidence]

  result = evidence[:budget//2]  # 证据占一半预算
  result += other[:budget - len(result)]  # 其余填其他
  return result
```

#### 策略 4: Rail 过滤

```
rail_filter_compression(history, current_task):
  # 只保留与当前任务相关的条目
  relevant_domains = current_task.domains
  return [e for e in history if e.domain in relevant_domains]
```

### 压缩策略选择

```
select_compression(history, budget, task):
  if task.mode == "debug":
    return evidence_compression  # Debug 优先保留证据
  if task.mode == "swarm":
    return rail_filter_compression  # Swarm 按域过滤
  if len(history) > 20:
    return window_compression  # 长对话用时间窗口
  return summarize_compression  # 默认摘要
```

## 4. 上下文生命周期

```
ContextLifecycle:
  1. Initialize:  创建空上下文，设置预算
  2. Load:        渐进披露加载必要内容
  3. Execute:     执行过程中追加证据和结果
  4. Compress:    超预算时压缩
  5. Persist:     任务完成后持久化关键上下文到反思日志
  6. Restore:     新任务时可恢复历史上下文
```

## 5. 跨专家上下文共享

Swarm 模式下，专家间通过消息总线共享上下文：

```
share_context(source_expert, target_expert, context_slice):
  # 源专家将部分上下文发送给目标专家
  msg = Message(
    type="provide_context",
    source=source_expert,
    target=target_expert,
    content=context_slice
  )
  message_bus.send(msg)

  # 目标专家接收后合并到自己的上下文
  target_context.merge(context_slice)
```

共享策略：
- 只共享接口定义、类型签名，不共享实现细节
- 只共享与目标专家 Rail 相关的上下文
- 共享前先压缩到 1024 tokens 以内
