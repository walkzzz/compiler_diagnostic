---
name: cangjie-db
description: >
  仓颉数据库开发技能。当用户需要开发或使用数据库驱动（openGauss、MySQL、PostgreSQL）、
  ORM、Redis 客户端、键值存储时使用。涵盖 opengauss-driver、redis-sdk、
  sql_builder 等仓库。
author: cangjie-expert-team
rail:
  capabilities: [sql, orm, redis, driver, opengauss, mysql]
  constraints: [no-driver-source-modification]
  requires: [cangjie-sdk-installed, cangjie-std]
  provides: [db-driver, orm-config, connection-pool]
  collaborates_with: [cangjie-std, cangjie-stdx, cangjie-sec]
---

# 仓颉数据库开发技能

用于快速、可靠地执行数据库开发任务。

## 默认工作流

### 1. 明确目标和约束
- 确认预期行为、非目标、数据库兼容性约束。

### 2. 定位模块边界
- 找到对应数据库驱动目录。
- 确定驱动的公共 API 边界。

### 3. 编码前发现 API
- 优先使用 `cjpm ide doc` 查询现有 API。
- 使用 `cjpm ide outline` 进行语义导航。

### 4. 紧密循环验证
- 编辑后运行 `cjpm check`。
- 运行 `cjpm test` 验证驱动行为。

### 5. 交付前完成
- 运行 `cjpm fmt`。
- 运行 `cjpm info` 验证 API 变更。

## 数据库架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      Cangjie 数据库生态                         │
└─────────────────────────────────────────────────────────────────┘

关系型数据库驱动
├── openGauss Driver
│   ├── openGauss/PostgreSQL 驱动
│   ├── Proto3 协议模块
│   ├── Pgconn 连接管理
│   ├── Driver 驱动接口
│   └── Sqlpool 连接池
├── MariaDB Driver
│   ├── MariaDB/MySQL/TiDB/OceanBase
│   └── 连接池管理
├── MySQL Client FFI
│   └── MySQL 客户端
└── ODBC
    └── ODBC 标准实现

Redis 客户端
├── redis-sdk
│   ├── RESP2/RESP3 协议
│   ├── 发布订阅
│   ├── 哨兵模式
│   ├── 集群模式
│   └── 多线程支持

ORM
├── sql_builder
│   └── ORM 组件
└── dataORM4cj
    └── 端侧 ORM

键值存储
├── kv4cj
│   └── 轻量级 KV
└── simplekv
    └── 高效 KV（排序、范围扫描、并发安全）
```

## 性能亮点

### redis-sdk 性能

对比 Jedis 客户端：
- 多线程 1 个 socket 连接，平均 TPS 提升 **29.21 倍**
- 多线程 3 个 socket 连接，平均 TPS 提升 **15.87 倍**

## 源代码目录

```
opengauss-driver/
├── src/
│   ├── proto3/           # Proto3 协议
│   ├── pgconn/           # 连接管理
│   ├── driver/           # 驱动接口
│   └── sqlpool/          # 连接池
└── tests/

redis-sdk/
├── src/
│   ├── client/           # 客户端
│   ├── protocol/         # RESP 协议
│   ├── sentinel/         # 哨兵
│   ├── cluster/          # 集群
│   └── pubsub/           # 发布订阅
└── tests/

sql_builder/
├── src/
│   └── orm/              # ORM 组件
└── tests/
```

## 验证契约

- **稳定能力事实**：数据库协议、驱动接口、连接池设计。
- **验证精确事实**：精确 API 名称、签名，由 `cjpm ide doc` 和本地文件验证。
- **未验证猜测**：从其他数据库驱动（JDBC、Redis 客户端）推断的 API。

## 文件结构

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主技能入口 |
| `README.md` | 数据库开发概述 |
| `CHANGELOG.md` | 版本变更记录 |
| `references/opengauss-guide.md` | openGauss 驱动指南 |
| `references/redis-guide.md` | Redis 客户端指南 |
| `references/orm-guide.md` | ORM 使用指南 |
