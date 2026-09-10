# 生命周期与阶段循环规则

> 整合自 code_quality_governance_swarm 的 stage_loop_rules / lifecycle_gate_rules /
> project_gate_rules / delivery_rules。定义仓颉全能 skill 的「交付→治理」双引擎循环。

## 一、双引擎范式

- **交付引擎**：仓颉 21 领域专家（references/cangjie-*/SKILL.md 角色卡）按生命周期阶段产出交付物，取代通用 product_manager/architect/developer 等角色。
- **治理引擎**：法庭式评审（控辩对抗 + 两级监察 + 工具硬校验）在每个交付阶段后作为质量门禁。

## 二、生命周期阶段 → 仓颉专家映射

| 阶段 | 主导仓颉专家 | 交付物 | 门禁法庭 |
|------|-------------|--------|----------|
| 需求分析 | cangjie-orientation / cangjie-edu | PRD、需求清单、验收标准 | requirement_trial |
| 架构设计 | cangjie-framework / cangjie-compiler | 技术设计、模块划分、接口契约 | 设计评审 |
| 编码实现 | cangjie-std / cangjie-stdx / cangjie-db / cangjie-net / cangjie-ai / cangjie-ui | 源代码、单元测试、实现报告 | code_review_trial |
| 测试工程 | cangjie-tools（cjpm/cjtest/cjprof） | 测试计划、用例、测试报告 | 测试评审 |
| 部署发布 | cangjie-cicd / cangjie-release / cangjie-doc | 部署方案、CI/CD、发布产物 | deploy_trial |
| 缺陷复盘 | cangjie-orchestrator | 根因报告、规则优化清单 | retro_trial |

> 单领域小任务可只走「编码实现」一个阶段；多领域任务由 cangjie-orchestrator 触发 Swarm Flow 按 pipeline 编排多阶段。

## 三、阶段循环状态（每阶段独立维护）

| 变量 | 说明 | 初始值 |
|------|------|--------|
| stage_round | 当前轮次 | 1 |
| stage_max_round | 最大轮次（档位决定） | L0=1,L1=2,L2=3,L3=5,L4=7 |
| stage_status | DELIVERING/GATE_REVIEWING/REMEDIATING/RECOMPOSING/PASSED/ESCALATED | DELIVERING |
| stage_deliverables / stage_judgments / stage_cost | 交付物/历轮判决/累计成本 | [] / [] / 0 |

循环流程：
```
交付执行 → 门禁评审 → 法官判决
   ↑                      │
   │            ┌─────────┴─────────┐
   │        判决:整改            判决:通过
   │            ↓                   ↓
   │        整改执行             阶段通过
   │            ↓                   ↓
   │        审判庭重组 ──→ 门禁评审   自动推进下一阶段
   └──────────────────────┘
```

- 交付执行：主导专家（子代理，注入角色卡全文+上游产出）产出交付物 → 自动转门禁评审
- 门禁评审：触发对应治理法庭（前置准备→分级路由→核心庭审→法官判决）
- 整改执行：执行官逐条落实 P0/P1，输出整改完成报告
- 审判庭重组：stage_round+1，以全新实例重组法庭再审；轮次上下文仅作历史参考，新法庭不得继承上轮判决
- 阶段通过：无未闭环 P0 + P1 完成率 ≥80% → 自动推进下一阶段；末阶段 → 总项目质量门禁
- 升级处理：stage_round > max_round 时按策略 A(升档)/B(人工介入)/C(带风险通过)/D(终止) 处理

## 四、交付物质量标准（仓颉语境）

- 源代码：必须 `cj build` 通过、`cj test` 通过、符合仓颉编码规范
- 接口契约：含请求/响应格式与错误码
- 测试报告：覆盖全部验收标准，缺陷分级跟踪到闭环
- 部署方案：含回滚预案、监控配置、预发验证
- 交付物追溯链：PRD → 设计 → 代码 → 测试 → 发布 全链路可追溯

## 五、总项目质量门禁（PROJECT_GATE）

所有阶段 PASSED 后触发，五维度：
1. 跨阶段一致性（需求↔设计↔代码↔测试↔部署，覆盖率 100%/偏差 0）
2. 质量评分聚合（P0=0、P1完成率≥85%、P2完成率≥70%、阶段通过率 100%）
3. 交付物完整性（追溯链连通）
4. 成本与效率（总成本≤预算、无单阶段>50%）
5. 风险评估（残余风险有缓释、技术债已记录）

终审判决：通过 / 有条件通过 / 不通过（回退最相关阶段）。判决后进入人在闭环强制确认。

## 六、跨阶段回退与暂停恢复

- 回退：后续阶段发现前序严重缺陷 → 作为「新指控」注入目标阶段，stage_round 不重置、max_round 追加预算
- 暂停/恢复：用户随时暂停，从最近 checkpoint.json 恢复
