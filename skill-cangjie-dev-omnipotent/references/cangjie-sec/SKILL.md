---
name: cangjie-sec
description: >
  仓颉安全加密开发技能。当用户需要开发或使用密码学、国密算法（SM2/SM3/SM4）、
  TLS、证书、安全协议时使用。涵盖 hicrypto、crypto-ffi、stdx.crypto 仓库。
author: cangjie-expert-team
rail:
  capabilities: [crypto, sm2, sm3, sm4, tls, cert, key-management]
  constraints: [no-key-exposure, no-insecure-defaults]
  requires: [cangjie-sdk-installed, cangjie-std]
  provides: [crypto-impl, tls-config, security-audit]
  collaborates_with: [cangjie-std, cangjie-stdx, cangjie-net]
---

# 仓颉安全加密开发技能

用于快速、可靠地执行安全加密开发任务。

## 默认工作流

### 1. 明确目标和约束
- 确认预期行为、非目标、安全合规约束。

### 2. 定位安全模块边界
- 找到对应安全模块目录。
- 确定安全模块的公共 API 边界。

### 3. 编码前发现 API
- 优先使用 `cjpm ide doc` 查询现有 API。
- 使用 `cjpm ide outline` 进行语义导航。

### 4. 紧密循环验证
- 编辑后运行 `cjpm check`。
- 运行 `cjpm test` 验证安全功能。

### 5. 交付前完成
- 运行 `cjpm fmt`。
- 运行 `cjpm info` 验证 API 变更。

## 安全加密架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      Cangjie 安全加密生态                       │
└─────────────────────────────────────────────────────────────────┘

密码学库
├── hicrypto (华为自研)
│   ├── openHiTls 底层
│   ├── 高效、敏捷
│   └── 全场景密码学
├── crypto-ffi
│   ├── 对称加密
│   ├── 非对称加密
│   └── 哈希算法
└── 摘要算法
    ├── sha256-cj
    └── md2-cj

国密算法
├── SM2 (非对称加密)
├── SM3 (摘要算法)
└── SM4 (对称加密)
    └── stdx.crypto.crypto

编码算法
├── base64-cj
└── hibase32-cj

证书处理
├── X.509 证书
└── TLS 安全传输
    └── stdx.net.tls
```

## 国密算法

```
┌─────────────────────────────────────────────────────────────────┐
│                      国密算法 (SM Series)                       │
└─────────────────────────────────────────────────────────────────┘

SM2 - 非对称加密
├── 基于椭圆曲线
├── 密钥交换
├── 数字签名
└── 加密解密

SM3 - 摘要算法
├── 256 位哈希
├── 消息认证
└── 完整性校验

SM4 - 对称加密
├── 128 位分组
├── 工作模式 (ECB, CBC)
└── 填充模式 (PKCS7)
```

## 源代码目录

```
hicrypto/
├── src/
│   ├── cipher/           # 对称加密
│   ├── digest/           # 摘要算法
│   └── signature/        # 签名算法
└── tests/

crypto-ffi/
├── src/
│   ├── cipher/           # 对称加密
│   ├── digest/           # 摘要算法
│   └── key/              # 密钥管理
└── tests/

stdx.crypto/
├── crypto/               # SM4 加密
├── digest/               # 摘要算法
├── keys/                 # 密钥管理
├── x509/                 # 证书处理
└── tests/
```

## 验证契约

- **稳定能力事实**：国密算法、密码学接口、TLS 协议。
- **验证精确事实**：精确 API 名称、签名，由 `cjpm ide doc` 和本地文件验证。
- **未验证猜测**：从其他密码学库（OpenSSL、BoringSSL）推断的 API。

## 文件结构

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主技能入口 |
| `README.md` | 安全加密开发概述 |
| `CHANGELOG.md` | 版本变更记录 |
| `references/sm-algorithms.md` | 国密算法指南 |
| `references/tls-guide.md` | TLS 配置指南 |
| `references/crypto-best-practices.md` | 加密最佳实践 |
