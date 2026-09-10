---
name: cangjie-framework
description: >
  仓颉应用框架开发技能。当用户需要开发或使用 cjoy、tea 框架，或进行 IoC、
  REST API、中间件、AI Agent 集成时使用。涵盖 cjoy、tea 仓库。
author: cangjie-expert-team
rail:
  capabilities: [cjoy, tea, ioc, rest, middleware, di]
  constraints: [no-stdlib-modification, backward-compat]
  requires: [cangjie-sdk-installed, cangjie-std, cangjie-stdx]
  provides: [framework-scaffold, api-design, integration-guide]
  collaborates_with: [cangjie-std, cangjie-stdx, cangjie-net, cangjie-db]
---

# 仓颉应用框架开发技能

用于快速、可靠地执行应用框架开发任务。

## 默认工作流

### 1. 明确目标和约束
- 确认预期行为、非目标、框架兼容性约束。

### 2. 定位框架边界
- 找到 `cjoy/` 或 `tea/` 目录结构。
- 确定框架的公共 API 边界。

### 3. 编码前发现 API
- 优先使用 `cjpm ide doc cjoy` 或 `cjpm ide doc tea` 查询现有 API。
- 使用 `cjpm ide outline` 进行语义导航。

### 4. 紧密循环验证
- 编辑后运行 `cjpm check`。
- 运行 `cjpm test` 验证框架行为。

### 5. 交付前完成
- 运行 `cjpm fmt`。
- 运行 `cjpm info` 验证 API 变更。

## 框架架构

### cjoy 全栈框架

```
┌─────────────────────────────────────────────────────────────────┐
│                          cjoy 框架                              │
└─────────────────────────────────────────────────────────────────┘

核心模块
├── IoC 容器 (依赖注入)
│   ├── 组件注册
│   ├── 依赖解析
│   └── 生命周期管理
├── REST API (宏路由)
│   ├── 路由定义
│   ├── 参数绑定
│   └── 响应构建
├── 中间件
│   ├── 请求处理链
│   ├── 认证中间件
│   └── 日志中间件
├── JSON 序列化
│   ├── 自动序列化
│   └── 反序列化
├── 参数绑定与校验
│   ├── 自动绑定
│   └── 校验规则
├── 文件上传下载
│   ├── 文件上传
│   └── 文件下载
├── OAuth2
│   ├── 认证授权
│   └── Token 管理
└── MCP 协议
    ├── Agent 通信
    └── 工具注册
```

### tea Web 框架

```
┌─────────────────────────────────────────────────────────────────┐
│                           tea 框架                              │
└─────────────────────────────────────────────────────────────────┘

特性
├── 函数式风格
├── 轻量级、高效
├── 中间件支持
└── 路由系统
```

## 源代码目录

```
cjoy/
├── src/
│   ├── ioc/              # IoC 容器
│   ├── rest/             # REST API
│   ├── middleware/       # 中间件
│   ├── json/             # JSON 序列化
│   ├── validation/       # 参数校验
│   ├── file/             # 文件处理
│   ├── oauth2/           # OAuth2
│   └── mcp/              # MCP 协议
└── tests/

tea/
├── src/
│   ├── router/           # 路由
│   ├── middleware/       # 中间件
│   └── server/           # 服务器
└── tests/
```

## 验证契约

- **稳定能力事实**：框架架构、IoC 容器、REST API 设计。
- **验证精确事实**：精确 API 名称、签名，由 `cjpm ide doc` 和本地文件验证。
- **未验证猜测**：从其他框架（Spring Boot、Express）推断的 API。

## 文件结构

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主技能入口 |
| `README.md` | 框架开发概述 |
| `CHANGELOG.md` | 版本变更记录 |
| `references/cjoy-guide.md` | cjoy 框架指南 |
| `references/tea-guide.md` | tea 框架指南 |
| `references/ioc-patterns.md` | IoC 模式 |
