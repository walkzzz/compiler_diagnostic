---
name: cangjie-stdx
description: >
  仓颉扩展库开发技能。当用户需要开发或使用扩展库（stdx.net、stdx.crypto、
  stdx.encoding、stdx.log、stdx.compress 等）时使用。涵盖 cangjie_stdx 仓库。
author: cangjie-expert-team
rail:
  capabilities: [net, crypto, encoding, log, compress]
  constraints: [no-stdlib-replacement, no-breaking-change]
  requires: [cangjie-sdk-installed]
  provides: [extension-lib, api-doc, integration-example]
  collaborates_with: [cangjie-std, cangjie-net, cangjie-sec]
---

# 仓颉扩展库开发技能

用于快速、可靠地执行扩展库开发任务。

## 默认工作流

### 1. 明确目标和约束
- 确认预期行为、非目标、外部依赖（OpenSSL 3、PCRE2）。

### 2. 定位模块边界
- 找到 `src/stdx/` 目录结构。
- 确定模块的公共 API 边界。

### 3. 编码前发现 API
- 优先使用 `cjpm ide doc stdx.*` 查询现有 API。
- 使用 `cjpm ide outline` 进行语义导航。

### 4. 紧密循环验证
- 编辑后运行 `cjpm check`。
- 运行 `cjpm test` 验证模块行为。

### 5. 交付前完成
- 运行 `cjpm fmt`。
- 运行 `cjpm info` 验证 API 变更。

## 扩展库架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      Cangjie 扩展库 (stdx)                      │
└─────────────────────────────────────────────────────────────────┘

网络 (stdx.net)
├── HTTP/1.1, HTTP/2, WebSocket
├── TLS 安全传输
└── 服务器和客户端

加密 (stdx.crypto)
├── SM4 对称加解密
├── 摘要算法 (MD5, SHA, SM3)
├── 密钥管理
└── 证书处理

编码 (stdx.encoding)
├── Base64
├── Hex
├── JSON
├── URL
└── 其他编码

日志 (stdx.log, stdx.logger)
├── 文本日志
├── JSON 日志
└── 日志级别

压缩 (stdx.compress)
├── zlib
├── tar
└── 其他格式

其他
├── 序列化
├── 语法解析
└── 单元测试扩展
```

## 源代码目录

```
cangjie_stdx/src/stdx/
├── net/                 # 网络
│   ├── http/
│   └── tls/
├── crypto/              # 加密
│   ├── common/
│   ├── crypto/
│   ├── digest/
│   ├── keys/
│   ├── kit/
│   └── x509/
├── encoding/            # 编码
│   ├── base64/
│   ├── hex/
│   ├── json/
│   ├── json_stream/
│   └── url/
├── log/                 # 日志 API
├── logger/              # 日志输出
├── compress/            # 压缩
│   ├── tar/
│   └── zlib/
├── serialization/       # 序列化
├── syntax/              # 语法解析
└── unittest/            # 单元测试扩展
```

## 依赖安装

### Linux
```bash
sudo apt install libssl-dev
```

### Windows
下载 OpenSSL 3.x.x x64 或使用第三方预编译包。

### macOS
```bash
brew install openssl@3
```

## 验证契约

- **稳定能力事实**：扩展库模块结构、HTTP API、加密接口。
- **验证精确事实**：精确 API 名称、签名，由 `cjpm ide doc` 和本地文件验证。
- **未验证猜测**：从其他扩展库推断的 API。

## 文件结构

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主技能入口 |
| `README.md` | 扩展库开发概述 |
| `CHANGELOG.md` | 版本变更记录 |
| `references/net-http-guide.md` | HTTP 模块指南 |
| `references/crypto-guide.md` | 加密模块指南 |
| `references/encoding-guide.md` | 编码模块指南 |
