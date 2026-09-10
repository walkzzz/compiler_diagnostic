---
name: cangjie-doc
description: >
  仓颉文档治理技能。当用户需要创建、维护或治理开源项目文档时使用，包括 README.md、
  CHANGELOG.md、CONTRIBUTING.md、API 文档、发布说明等。
author: cangjie-expert-team
rail:
  capabilities: [readme, changelog, api-doc, contributing, faq]
  constraints: [no-code-modification, docs-only]
  requires: [source-code-available]
  provides: [doc-files, api-reference, style-guide]
  collaborates_with: [cangjie-orientation, cangjie-comm]
---

# 仓颉文档治理技能

用于快速、可靠地执行开源项目文档治理任务。

## 默认工作流

### 1. 明确目标和约束
- 确认文档类型（README、CHANGELOG、CONTRIBUTING、API 文档）
- 确认目标读者（开发者、用户、贡献者）
- 确认项目状态（开发中、发布、维护模式）

### 2. 定位文档边界
- 找到项目根目录
- 确定已有文档文件
- 识别文档缺口

### 3. 文档质量检查
- 检查文档完整性
- 检查文档准确性
- 检查文档一致性

### 4. 紧密循环验证
- 检查链接有效性
- 验证代码示例
- 检查格式规范

### 5. 交付前完成
- 格式化文档
- 更新变更日志
- 提交文档

## 文档类型

### README.md

```markdown
# 项目名称

## 简介
简短的项目描述。

## 快速开始
### 安装
```bash
# 安装命令
```

### 使用
```cangjie
// 使用示例
```

## 特性
- 特性 1
- 特性 2

## 文档
- [使用指南](./docs/)
- [API 参考](./docs/api.md)

## 贡献
请阅读 [CONTRIBUTING.md](./CONTRIBUTING.md)

## 许可证
[MIT License](./LICENSE)
```

### CHANGELOG.md

```markdown
# 变更日志

## [1.0.0] - 2026-04-03

### 新增
- 功能 A
- 功能 B

### 修复
- 修复问题 A

### 变更
- 变更说明
```

### CONTRIBUTING.md

```markdown
# 贡献指南

## 如何贡献
1. Fork 本项目
2. 创建特性分支
3. 提交更改
4. 创建 Pull Request

## 代码规范
- 使用 cjfmt 格式化代码
- 编写单元测试
- 更新文档

## 提交规范
- feat: 新功能
- fix: Bug 修复
- docs: 文档更新
- style: 代码格式
- refactor: 代码重构
```

## 文档治理清单

### 开源项目文档检查清单

| 类别 | 检查项 | 状态 |
|------|--------|------|
| 基础文档 | README.md 存在 | □ |
| 基础文档 | LICENSE 存在 | □ |
| 基础文档 | CHANGELOG.md 存在 | □ |
| 基础文档 | CONTRIBUTING.md 存在 | □ |
| 代码文档 | 代码注释完整 | □ |
| 代码文档 | API 文档完整 | □ |
| 使用文档 | 快速开始指南 | □ |
| 使用文档 | 使用示例 | □ |
| 使用文档 | 常见问题 | □ |

### 文档质量检查

| 检查项 | 标准 |
|--------|------|
| 准确性 | 文档与代码一致 |
| 完整性 | 覆盖所有功能 |
| 一致性 | 术语、格式统一 |
| 可读性 | 结构清晰、语言简洁 |
| 可维护性 | 易于更新和维护 |

## 文档自动化

### 使用 cjpm 生成文档

```bash
# 生成 API 文档
cjpm doc

# 生成项目文档
cjpm doc --output docs/
```

### 文档格式规范

- 使用 Markdown 格式
- 代码块标记语言
- 标题层级清晰
- 链接相对路径

## 文件结构

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主技能入口 |
| `README.md` | 文档治理概述 |
| `CHANGELOG.md` | 版本变更记录 |
| `references/document-templates.md` | 文档模板 |
| `references/checklist.md` | 检查清单 |
