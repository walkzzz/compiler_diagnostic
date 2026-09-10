# cangjie-dev-omnipotent

**仓颉开发全能专家团**——「交付 + 治理」双引擎融合技能。
由 `cangjie-expert-team` v1.2.0（21 领域专家交付引擎）与
`code_quality_governance_swarm` v5.2.0（法庭式质量治理引擎）融合而成。

## 这是什么

单一入口的仓颉开发全能 skill：

- **交付引擎**：顶层 `SKILL.md` 做 Rail 意图路由，把仓颉需求路由到 21 个
  领域专家角色卡（`references/<expert>/SKILL.md`），多领域任务委托
  cangjie-orchestrator 触发 Swarm Flow 协作，CangjieCorpus 语料库做事实仲裁。
- **治理引擎**：每个交付阶段后触发法庭式质量门禁（`governance/`）——
  控辩对抗 + 两级监察 + 仓颉工具硬校验（cj build / cj test / cjlint），
  L0-L4 五级智能分级路由，阶段循环 + 审判庭重组，人在闭环三级介入，
  自学习闭环跨项目积累。

一句话：**专家负责产出，法庭负责把关，主理人只做编排**。

## 适用场景

- 仓颉项目端到端交付：需求分析 → 架构设计 → 编码实现 → 测试工程 → 部署发布
- 仓颉任何领域开发：编译器、运行时、cjpm 工具链、std/stdx、cjoy 框架、
  数据库驱动、网络、AI Agent、安全、UI
- 要求可追溯、可举证、可审计的代码/需求/方案评审（纯治理模式）
- 仓颉生态创新挑战赛全流程（选题 → 自查 → 上架 → 路演）
- 官方文档与 API 查证（CangjieCorpus 语料检索）
- 多领域仓颉任务需专家协作且每阶段过质量门禁

## 不适用

- 非仓颉语言任务（直接回答，不加载专家）
- 无质量门禁需求的单点问答（走 W2 单专家直答即可）

## 安装

将本目录整体放入任意支持 skill 机制的平台的 skills 目录：

```
~/.agents/skills/cangjie-dev-omnipotent/     # 通用
~/.trae-cn/skills/cangjie-dev-omnipotent/    # Trae
~/.workbuddy/skills/cangjie-dev-omnipotent/  # WorkBuddy
```

零外部依赖，全部资产自包含分发。

> **可选增强（非依赖）**：语料检索专家（cangjie-corpus）需要本机存在官方
> CangjieCorpus 1.1.0 语料库，默认路径 `~\.agents\corpus\CangjieCorpus-1.1.0\`
> （约 187 MB，在 skill 目录之外）。获取方式见
> `references/cangjie-corpus/SKILL.md`「获取与刷新语料」一节。缺失时优雅降级
> 到内置 `wiki/`、`docs/`。

## 触发方式

frontmatter triggers 自动匹配 + 自然语言意图识别：

| 触发词/说法 | 进入 |
|------------|------|
| "仓颉开发" / "启动仓颉专家团" / 提出仓颉编码需求 | W1 全生命周期交付 |
| "仓颉评审" / "审这段仓颉代码" / "严格模式评审" | W3 纯治理（定档 L0-L4） |
| 单点领域问题（std API、cjpm 用法） | W2 单专家直答 |
| "仓颉挑战赛" / "参赛" / "上架中心仓" | W1 挂载 challenge-coach |

## 使用

对 Agent 说：

- "用仓颉全能专家团帮我开发一个 HTTP 框架并发布"（W1 全生命周期）
- "审一下这段仓颉代码，严格模式"（W3 纯治理，L3 档）
- "仓颉 std.collection 的 HashMap 怎么用？"（W2 单专家直答）
- "启动仓颉挑战赛教练"（W1 挂载 challenge-coach）

## 文件结构

```
cangjie-dev-omnipotent/
├── SKILL.md                          # L1 驾驶舱：双引擎融合路由 + 阶段循环
├── README.md                         # 本文件
├── DESIGN.md                         # 融合架构决策记录
├── CHANGELOG.md                      # 版本变更记录
├── config/                           # 交付引擎配置（Rail/Swarm/集群）
│   ├── cluster-dynamic.json          #   21 专家动态集群
│   ├── execution-substrate.md        #   Inner/Outer Loop 执行底座
│   ├── rails/rail-system.json        #   10 个 Rail 定义
│   ├── swarm/swarm-flow.json         #   Swarm 算子与模板
│   └── runtime/runtime-adaptivity.json # 运行时自适配 4 机制
├── governance/                       # 治理引擎（法庭式质量门禁）
│   ├── workflow.md                   #   七阶段庭审门禁子流程
│   ├── rules/
│   │   ├── governance-core.md        #   证据/判决/风险/终止规则
│   │   ├── lifecycle-rules.md        #   生命周期阶段循环 + 项目门禁
│   │   └── human-and-learning-rules.md # 人在闭环 + 自学习闭环
│   ├── roles/
│   │   └── tribunal-roles.md         #   9 治理角色卡 + 交付角色映射
│   └── config/
│       └── tribunal-config.yaml      #   L0-L4 档位 + 仓颉工具映射 + 模型绑定
├── references/                       # 21 个仓颉领域专家角色卡
│   ├── cangjie-router/SKILL.md       #   路由器（回退参考）
│   ├── cangjie-orchestrator/SKILL.md #   蜂群编排专家
│   │   └── references/               #   swarm-flow/context-engine/goal-modes/rail-specification/self-reflection
│   ├── cangjie-compiler/SKILL.md     #   编译器大师
│   ├── cangjie-runtime/SKILL.md      #   运行时专家
│   ├── cangjie-tools/SKILL.md        #   工具链架构师
│   ├── cangjie-std/SKILL.md          #   标准库权威
│   ├── cangjie-stdx/SKILL.md         #   扩展库专家
│   ├── cangjie-framework/SKILL.md    #   框架架构师
│   ├── cangjie-db/SKILL.md           #   数据库专家
│   ├── cangjie-net/SKILL.md          #   网络协议专家
│   ├── cangjie-ai/SKILL.md           #   AI 原生架构师
│   ├── cangjie-sec/SKILL.md          #   安全专家
│   ├── cangjie-ui/SKILL.md           #   UI 架构师
│   ├── cangjie-edu/SKILL.md          #   教育推广大使
│   ├── cangjie-comm/SKILL.md         #   社区运营官
│   ├── cangjie-doc/SKILL.md          #   文档治理专家
│   ├── cangjie-release/SKILL.md      #   发布管理专家
│   ├── cangjie-cicd/SKILL.md         #   多平台发布工程专家
│   │   └── references/               #   build-matrix/sdk-urls/workflow-templates
│   ├── cangjie-orientation/SKILL.md  #   入门导航（兜底）
│   ├── cangjie-challenge-coach/SKILL.md # 挑战赛教练「赛辅」
│   │   └── references/               #   checklist/资料包/PR提交模版/README模版/toolchain-gotchas
│   └── cangjie-corpus/SKILL.md       #   语料库检索「语稽」
├── wiki/                             # 内置知识（语料缺失时回退）
│   ├── language/introduction.md
│   ├── stdlib/overview.md
│   └── toolchain/moon-commands.md
└── docs/                             # 设计与生态文档
    ├── 仓颉开发专家天团.md
    ├── 仓颉编程语言生态知识库.md
    ├── AtomGit Cangjie（仓颉）全部分类汇总.md
    └── dynamic-harness-architecture.md
```

## 来源与版本

| 项 | 值 |
|----|----|
| 交付引擎来源 | cangjie-expert-team v1.2.0（源自 cangjie-openjiuwen-v8 插件） |
| 治理引擎来源 | code_quality_governance_swarm v5.2.0 |
| 语料库 | [CangjieCorpus](https://gitcode.com/Cangjie/CangjieCorpus) 1.1.0 分支（可选增强） |
| 本 skill 版本 | 1.0.0 |
