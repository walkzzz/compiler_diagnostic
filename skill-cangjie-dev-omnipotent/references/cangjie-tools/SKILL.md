---
name: cangjie-tools
description: >
  仓颉工具链开发技能。当用户需要使用或开发 cjpm、cjfmt、cjprof、cjlint、cjcov、
  cjcompat 等工具时使用。涵盖 cangjie_tools 仓库。
author: cangjie-expert-team
rail:
  capabilities: [cjpm-ops, cjfmt, cjprof, cjlint, toolchain-config]
  constraints: [no-source-code-modification]
  requires: [cangjie-sdk-installed]
  provides: [formatted-code, profile-report, lint-result]
  collaborates_with: [cangjie-compiler, cangjie-std]
---

# 仓颉工具链开发技能

用于快速、可靠地执行工具链开发任务。

## 默认工作流

### 1. 明确目标和约束
- 确认预期行为、非目标、兼容性约束（目标平台、输入格式）。

### 2. 定位工具边界
- 找到对应工具目录（cjpm/cjfmt/cjprof/cjlint）。
- 确定工具的输入输出接口。

### 3. 编码前发现 API
- 优先使用 `cjpm ide doc` 查询现有 API。
- 使用 `cjpm ide outline` 进行语义导航。

### 4. 紧密循环验证
- 编辑后运行 `cjpm check`。
- 运行 `cjpm test` 验证工具行为。

### 5. 交付前完成
- 运行 `cjpm fmt`。
- 运行 `cjpm info` 验证 API 变更。

## 工具链架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      Cangjie 工具链                             │
└─────────────────────────────────────────────────────────────────┘

包管理 (cjpm)
├── 模块初始化
├── 依赖管理
├── 增量编译
├── 并行编译
└── 统一编译入口

代码格式化 (cjfmt)
├── 代码自动格式化
├── 编码规范检查
└── 配置化规则

性能分析 (cjprof)
├── CPU 热点采样
├── 堆内存分析
├── 火焰图生成
└── 性能报告

静态分析 (cjlint)
├── 编码规范检查
├── 潜在问题检测
└── 自动修复建议

覆盖率 (cjcov)
├── 代码覆盖率分析
├── HTML 报告
└── 覆盖率阈值

兼容性 (cjcompat)
├── API/ABI 兼容性检查
├── 版本差异分析
└── 兼容性报告
```

## 源代码目录

```
cangjie_tools/
├── cjpm/              # 包管理
│   ├── build/
│   ├── doc/
│   └── src/
├── cjfmt/             # 格式化
│   ├── build/
│   ├── config/
│   ├── doc/
│   ├── include/
│   └── src/
├── cjprof/            # 性能分析
│   ├── build/
│   ├── doc/
│   ├── figures/
│   ├── include/
│   ├── src/
│   └── tests/
├── cjlint/            # 静态分析
│   ├── build/
│   ├── config/
│   ├── doc/
│   └── src/
├── cjcov/             # 覆盖率
│   ├── build/
│   ├── doc/
│   └── src/
├── cjcompat/          # 兼容性
│   ├── build/
│   ├── doc/
│   ├── figures/
│   ├── include/
│   └── src/
├── cjdb/              # 调试器
│   ├── build/
│   ├── doc/
│   └── src/
└── hyperlangExtension/
    ├── build/
    ├── doc/
    └── src/
```

## 验证契约

- **稳定能力事实**：工具链架构、命令接口、输出格式。
- **验证精确事实**：命令参数、配置文件格式，由 `cjpm --help` 和本地文件验证。
- **未验证猜测**：从其他工具链（cargo、npm）推断的行为。

## 文件结构

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主技能入口 |
| `README.md` | 工具链开发概述 |
| `CHANGELOG.md` | 版本变更记录 |
| `references/cjpm-guide.md` | cjpm 使用指南 |
| `references/cjfmt-rules.md` | 格式化规则 |
| `references/cjprof-usage.md` | 性能分析指南 |
