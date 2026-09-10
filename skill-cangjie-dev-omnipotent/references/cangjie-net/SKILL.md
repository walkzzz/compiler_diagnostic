---
name: cangjie-net
description: >
  仓颉网络协议开发技能。当用户需要开发或使用 HTTP、WebSocket、MQTT、RPC、
  gRPC、OAuth、GraphQL 等网络协议时使用。涵盖 httpclient4cj、rpc4cj、
  mqtt4cj 等仓库。
author: cangjie-expert-team
rail:
  capabilities: [http, websocket, mqtt, rpc, grpc, tcp, udp]
  constraints: [no-protocol-spec-modification]
  requires: [cangjie-sdk-installed, cangjie-std]
  provides: [protocol-impl, client-server, api-doc]
  collaborates_with: [cangjie-std, cangjie-stdx, cangjie-sec, cangjie-framework]
---

# 仓颉网络协议开发技能

用于快速、可靠地执行网络协议开发任务。

## 默认工作流

### 1. 明确目标和约束
- 确认预期行为、非目标、协议兼容性约束。

### 2. 定位协议边界
- 找到对应协议目录。
- 确定协议的公共 API 边界。

### 3. 编码前发现 API
- 优先使用 `cjpm ide doc` 查询现有 API。
- 使用 `cjpm ide outline` 进行语义导航。

### 4. 紧密循环验证
- 编辑后运行 `cjpm check`。
- 运行 `cjpm test` 验证协议行为。

### 5. 交付前完成
- 运行 `cjpm fmt`。
- 运行 `cjpm info` 验证 API 变更。

## 网络协议架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      Cangjie 网络协议生态                       │
└─────────────────────────────────────────────────────────────────┘

HTTP
├── httpclient4cj
│   ├── HTTP/1.1, HTTP/2
│   ├── 连接池
│   ├── Socket 复用
│   └── 响应缓存
└── stdx.net.http
    ├── HTTP 服务器
    ├── WebSocket
    └── TLS

WebSocket
├── TPC-Cangjie-WebSocket
│   └── 实时通信
└── stdx.net.http
    └── WebSocket 升级

MQTT
├── mqtt4cj
│   └── MQTT 消息队列协议

RPC
├── rpc4cj
│   ├── ProtoBuf RPC
│   ├── HTTP/2 传输
│   ├── 双向流
│   └── 流控
└── grpc-cj
    └── gRPC 支持

其他协议
├── oauth4cj        OAuth 授权
├── graphql4cj      GraphQL 客户端
├── ntp4cj          NTP 时间同步
├── xmpp4cj         XMPP 客户端
└── eventsource4cj  SSE 服务端推送
```

## 源代码目录

```
httpclient4cj/
├── src/
│   ├── client/           # 客户端
│   ├── pool/             # 连接池
│   └── cache/            # 缓存
└── tests/

rpc4cj/
├── src/
│   ├── client/           # 客户端
│   ├── server/           # 服务器
│   ├── protocol/         # 协议
│   └── codec/            # 编解码
└── tests/

mqtt4cj/
├── src/
│   ├── client/           # 客户端
│   ├── protocol/         # MQTT 协议
│   └── broker/           # 代理
└── tests/
```

## 验证契约

- **稳定能力事实**：协议架构、连接管理、传输层设计。
- **验证精确事实**：精确 API 名称、签名，由 `cjpm ide doc` 和本地文件验证。
- **未验证猜测**：从其他网络库（OkHttp、gRPC）推断的 API。

## 文件结构

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主技能入口 |
| `README.md` | 网络协议开发概述 |
| `CHANGELOG.md` | 版本变更记录 |
| `references/http-guide.md` | HTTP 客户端指南 |
| `references/rpc-guide.md` | RPC 框架指南 |
| `references/mqtt-guide.md` | MQTT 协议指南 |
