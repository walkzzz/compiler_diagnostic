# DESIGN

cangjie-dev-omnipotent 的需求规格与架构决策记录。

## 需求来源

用户要求：把 `cangjie-expert-team`（仓颉 21 领域专家交付编排）与
`code_quality_governance_swarm`（全生命周期交付+治理专家团）两个技能
**融合为一个仓颉开发全能 skill**。

## 决策记录（关键架构决策）

### 决策 1：双引擎融合模型——「专家产出 + 法庭门禁」

- 两个源技能的编排范式表面冲突：cangjie-expert-team 用 Rail pipeline +
  Swarm Flow（21 专家并行/流水线），governance_swarm 用法庭式五阶段生命周期循环。
- **候选方案对比**：
  - A. 简单拼接两技能目录 → ❌ 否决：100+ 文件、文件表失控、SKILL.md 超预算、范式互斥
  - B. 只取一方为主、另一方降级为附录 → ❌ 否决：丢失治理引擎门禁价值或丢失仓颉领域知识
  - C. 包裹模型：专家=交付引擎、法庭=阶段门禁 → ✅ 采纳：两引擎职责正交，天然可组合
- **采纳包裹模型**：仓颉 21 专家作为**交付引擎**（实质领域知识不可压缩），
  法庭式治理引擎作为**质量门禁**包裹在每个交付阶段之后。
  通用 product_manager/architect/developer 等交付角色由仓颉领域专家承接
  （映射见 governance/roles/tribunal-roles.md）。

### 决策 2：两套状态机合并为统一驾驶舱

- 交付侧保留 Rail 意图分类 → 专家路由 → Swarm Flow；
- 治理侧保留阶段循环（DELIVERING→GATE_REVIEWING→REMEDIATING→RECOMPOSING→PASSED）
  与 L0-L4 档位。
- 合并为 SKILL.md 的 W1 主流程：意图分类 → 阶段循环（交付+门禁交替）→
  总项目门禁 → 自学习。W2 单专家直答、W3 纯治理为轻量旁路。

### 决策 3：治理资产激进精简（11 规则 → 3 文件）

- 源 governance_swarm 的 11 个 rules 文件按职责聚类合并：
  - `governance-core.md` ← evidence + judgment + risk_level + termination + inspection
  - `lifecycle-rules.md` ← stage_loop + lifecycle_gate + project_gate + delivery
  - `human-and-learning-rules.md` ← human_in_loop + self_learning
- 14 个角色文件合并为单文件 `tribunal-roles.md`（治理角色 + 交付角色映射表）。
- bind.md 的 level_config/模型绑定/知识库配置合并为
  `governance/config/tribunal-config.yaml`。

### 决策 4：治理工具仓颉原生适配

- 源治理工具（code_lint/security_scan/complexity_scan 等）为 Python-only
  （pylint 等），在仓颉语境不可用。
- 建立工具映射（tribunal-config.yaml `tool_mapping`）：
  pylint→cjlint、sandbox→cj build+run、dependency_scan→cjpm deps、
  security_scan→cangjie-sec 专家、evidence_verifier→cj test。
- 一级证据定义改写为仓颉工具链硬校验结果（cj build/cj test/cjlint/LSP）。

### 决策 5：交付引擎基座整体保留

- 21 专家角色卡 + config/（Rail/Swarm/集群）+ wiki/ + docs/ 原样迁入，
  不重写（实质领域知识、语料库检索策略、挑战赛物料为不可替代资产）。
- 仅顶层 SKILL.md 重写为双引擎驾驶舱，README/DESIGN/CHANGELOG 同步更新。

### 决策 6：文件结构表完整内联于 SKILL.md

- validate.py 支持「文件结构详见 README.md」委托模式，但 quality-audit 的
  文件完整性维度（10 分）不认委托、要求逐文件列入 SKILL.md 表。
- 本 skill 资产约 55 个文件，全部列入 SKILL.md 文件表（约 60 行）可接受，
  总行数仍远低于 AP-009 的 500 行上限；README 同时保留树形视图便于浏览。

## 非目标

- 不重写 21 专家角色卡内部内容（保持源资产原样）
- 不内联 CangjieCorpus 语料库（187 MB，外置 + 优雅降级，沿用源 skill 决策）
- 不实现治理引擎的 Python 工具脚本（仓颉任务走 cj 工具链，无需 pylint）
- 不保留 governance_swarm 的 sub_skills/ 与 prompts/（其职责已由
  governance/workflow.md + tribunal-roles.md 覆盖）

## 已知局限

1. **治理工具依赖仓颉工具链在位**：cj build/cj test/cjlint 需本机安装
   Cangjie SDK；不可用时降级为纯模型评审并标注「无工具支撑」，一级证据缺失
   会使判决置信度下降。
2. **人在闭环依赖宿主 Agent 支持暂停确认**：Trae/WorkBuddy 等交互式平台可
   暂停等待用户确认；无人值守批处理模式下强制确认点会按超时策略处理
   （见 human-and-learning-rules.md 超时列）。
3. **自学习闭环的知识持久化是尽力而为**：`./knowledge/` 与全局库
   `~/.cangjie-gov/` 为运行时产物目录，skill 包内仅提供空结构；跨会话/跨
   项目积累依赖宿主文件系统持久性。
4. **档位打分由 LLM 主观裁量**：route_judge 六维打分为模型估算，非精确度量；
   用户显式指定档位时以用户为准。
5. **L2 深度文档分散**：references/ 下角色卡众多（21 专家 + 编排子文档），
   单次任务按需加载，不整体读入，避免 token 膨胀。

## 文件结构

见 README.md 完整文件树。governance/ 为本 skill 新增的治理引擎层：

```
governance/
├── workflow.md
├── rules/
│   ├── governance-core.md
│   ├── lifecycle-rules.md
│   └── human-and-learning-rules.md
├── roles/
│   └── tribunal-roles.md
└── config/
    └── tribunal-config.yaml
```
