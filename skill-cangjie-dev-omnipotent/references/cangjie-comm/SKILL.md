---
name: cangjie-comm
description: >
  仓颉社区运营技能。当用户需要进行社区运营、论坛管理、活动组织、贡献管理时使用。
  涵盖 CangjieCommunity、UsersForum、community 仓库。
author: cangjie-expert-team
rail:
  capabilities: [forum, event, contribution, issue-triage, pr-review]
  constraints: [no-code-modification, community-only]
  requires: [repo-access]
  provides: [community-report, event-plan, contribution-guide]
  collaborates_with: [cangjie-doc, cangjie-edu]
---

# 仓颉社区运营技能

用于快速、可靠地执行社区运营任务。

## 默认工作流

### 1. 明确目标和约束
- 确认运营目标、目标用户、资源约束。

### 2. 定位社区平台
- 确定社区平台（论坛、GitHub、社交媒体）。
- 了解平台规则和用户习惯。

### 3. 制定运营策略
- 内容策略
- 活动策略
- 增长策略

### 4. 执行和评估
- 执行运营活动
- 收集反馈
- 评估效果

## 社区架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      Cangjie 社区生态                           │
└─────────────────────────────────────────────────────────────────┘

社区平台
├── CangjieCommunity
│   ├── 社区环境
│   ├── 用户交流
│   └── 资源分享
├── UsersForum
│   ├── 问题讨论
│   ├── 经验分享
│   └── 公告发布
└── community
    ├── 治理架构
    ├── 贡献指南
    └── 开发者协议

活动组织
├── cangjie-workshop
│   └── 工作坊
├── cangjie-exam
│   └── 考试认证
├── cangjie-quiz
│   └── 题库竞赛
└── 黑客松
    └── 编程竞赛

贡献管理
├── Issue 管理
│   ├── Bug 报告
│   ├── 功能请求
│   └── 问题解答
├── PR 管理
│   ├── 代码审查
│   ├── 合并流程
│   └── 贡献者认可
└── 文档贡献
    ├── 文档翻译
    ├── 示例编写
    └── 教程制作

开源生态
├── Cangjie-TPC
│   ├── 三方组件中心
│   ├── 库发布
│   └── 依赖管理
├── Cangjie-Examples
│   ├── 示例代码
│   └── 示例项目
└── Cangjie-TPC 仓库
    └── 三方库
```

## 运营指标

```
┌─────────────────────────────────────────────────────────────────┐
│                      社区运营指标                               │
└─────────────────────────────────────────────────────────────────┘

增长指标
├── 月活用户数
├── 新用户注册数
└── 用户留存率

活跃指标
├── 日发帖数
├── 日回复数
└── 在线时长

质量指标
├── 问题解决率
├── 文档完善度
└── 示例覆盖率

贡献指标
├── PR 提交数
├── Issue 解决数
└── 文档贡献数
```

## 活动类型

### 常规活动

```
每周活动
├── 技术分享
├── 问题答疑
└── 代码审查

每月活动
├── 线上讲座
├── 编程挑战
└── 优秀贡献者评选
```

### 大型活动

```
季度活动
├── 黑客松
├── 培训营
└── 社区大会

年度活动
├── 开发者大会
├── 年度评选
└── 路线图规划
```

## 源代码目录

```
CangjieCommunity/
├── posts/                  # 帖子
├── events/                 # 活动
├── resources/              # 资源
└── docs/                   # 文档

UsersForum/
├── categories/             # 分类
├── topics/                 # 话题
└── announcements/          # 公告

community/
├── governance/             # 治理
├── contributing/           # 贡献
└── CLA/                    # 协议
```

## 验证契约

- **稳定能力事实**：社区架构、活动类型、运营指标。
- **验证精确事实**：活动规则、贡献流程，由社区文档和本地文件验证。
- **未验证猜测**：从其他开源社区（Apache、Linux）推断的运营方式。

## 文件结构

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主技能入口 |
| `README.md` | 社区运营概述 |
| `CHANGELOG.md` | 版本变更记录 |
| `references/community-guide.md` | 社区运营指南 |
| `references/event-planning.md` | 活动策划指南 |
| `references/contribution-guide.md` | 贡献指南 |
