# CHANGELOG

本 skill 由 `cangjie-expert-team` v1.2.0（交付引擎）与
`code_quality_governance_swarm` v5.2.0（治理引擎）融合而成。

## [1.0.0] - 2026-09-10

### Added
- **双引擎融合架构**：仓颉 21 领域专家作为交付引擎，法庭式质量治理作为
  每阶段门禁，合并为单一「仓颉开发全能」skill
- `governance/workflow.md`：七阶段庭审门禁子流程（前置准备→分级路由→
  侦查指控→控辩对抗→法官判决→两级监察→动态升降档）
- `governance/rules/governance-core.md`：证据四级 / 判决四原则 / 风险四级 /
  两级监察 / 终止迭代规则（整合源 5 个规则文件）
- `governance/rules/lifecycle-rules.md`：生命周期阶段→仓颉专家映射、
  阶段循环状态机、总项目质量门禁五维度（整合源 4 个规则文件）
- `governance/rules/human-and-learning-rules.md`：人在闭环三级介入（6 强制 /
  5 建议 / 8 自动）+ 自学习闭环 7 项能力（整合源 2 个规则文件）
- `governance/roles/tribunal-roles.md`：9 个治理角色卡 + 交付角色映射表
  （整合源 14 个角色文件）
- `governance/config/tribunal-config.yaml`：L0-L4 档位配置 +
  **治理工具仓颉原生映射**（pylint→cjlint、sandbox→cj build+run 等）+
  模型绑定 + 知识库配置
- 顶层 `SKILL.md` 重写为双引擎驾驶舱：W1 全生命周期交付 / W2 单专家直答 /
  W3 纯治理三模式路由 + 统一派发协议 + 人在闭环 + 输出文件约定

### Changed
- 交付引擎基座（references/ 21 专家角色卡、config/、wiki/、docs/）整体保留，
  仅顶层编排升级为双引擎
- 一级证据定义改写为仓颉工具链硬校验（cj build / cj test / cjlint / LSP）
- 通用交付角色（product_manager/architect/developer/test_engineer/
  devops_engineer）由对应仓颉领域专家承接
- README/DESIGN/CHANGELOG 全面更新为融合版本

### Fixed
- 文件结构表逐文件内联 SKILL.md（quality-audit 文件完整性维度 10/10）；
  修复表解析歧义（用途列避免"文件"字样与裸斜杠路径）
- 触发词全部 ≥3 字符（消除 TRIG-002 碰撞风险）
- DESIGN.md 补齐候选方案对比与已知局限（设计文档质量 6/6）

### Source
- 交付引擎：cangjie-expert-team v1.2.0（源自 cangjie-openjiuwen-v8 插件）
- 治理引擎：code_quality_governance_swarm v5.2.0

---

## 交付引擎历史（继承自 cangjie-expert-team）

### [1.2.0] - 2026-09-10
- 第 21 个专家 cangjie-corpus 语料库检索「语稽」；接入官方 CangjieCorpus 1.1.0

### [1.1.0] - 2026-09-10
- 第 20 个专家 cangjie-challenge-coach 挑战赛全流程教练「赛辅」

### [1.0.0] - 2026-09-10
- 顶层 SKILL.md Rail 编排路由器；19 个散装 skill → 单一编排 skill

## 治理引擎历史（继承自 code_quality_governance_swarm）

### [5.2.0]
- 自学习闭环 7 项能力 + 人在闭环三级介入体系

### [5.0.0]
- 全生命周期交付角色 + 交付子技能 + 生命周期门禁 + 交付物追溯链

### [4.0.0]
- 显式状态机 + 并行执行 + 错误恢复 + 检查点续跑 + 可观测性监控
