---
name: cangjie-release
description: >
  仓颉发布管理技能。当用户需要版本发布、二进制构建、CI/CD、发布流程时使用。
  涵盖版本管理、cjpm 构建、发布脚本、发布文档。
author: cangjie-expert-team
rail:
  capabilities: [version, build, package, semver, changelog]
  constraints: [no-unreleased-features, no-skip-tests]
  requires: [cangjie-sdk-installed, source-code-available, tests-passing]
  provides: [release-package, release-notes, version-tag]
  collaborates_with: [cangjie-cicd, cangjie-doc, cangjie-tools]
---

# 仓颉发布管理技能

用于快速、可靠地执行版本发布和二进制构建任务。

## 默认工作流

### 1. 明确目标和约束
- 确认版本号（语义化版本）
- 确认目标平台
- 确认发布范围

### 2. 代码检查
- 所有测试通过
- 代码格式化完成
- 无编译警告
- 文档完整

### 3. 版本更新
- 更新版本号
- 更新 CHANGELOG.md
- 创建版本标签

### 4. 构建
- 开发构建测试
- 发布构建
- 多平台构建

### 5. 打包
- 创建发布目录
- 复制二进制文件
- 复制文档
- 创建压缩包

### 6. 发布
- 上传到发布平台
- 编写发布说明
- 通知用户

## 快速任务手册

### 新版本发布

1. 更新版本号
   ```bash
   # 编辑 cjpm.toml
   version = "1.0.0"
   ```

2. 更新 CHANGELOG.md
   ```markdown
   ## [1.0.0] - 2026-04-03
   ### 新增
   - 功能 A
   - 功能 B
   ```

3. 创建版本标签
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

4. 构建发布
   ```bash
   cjpm build --release
   ./scripts/release.sh 1.0.0 x86_64-pc-windows-msvc
   ```

5. 上传发布
   ```bash
   # 使用 gh 工具
gh release create v1.0.0 dist/*
   ```

### 二进制构建

1. 配置构建
   ```toml
   # cjpm.toml
   [build]
   output-type = "executable"
   optimize = "release"
   ```

2. 执行构建
   ```bash
   cjpm build --release
   ```

3. 验证构建
   ```bash
   # 检查二进制文件
   ls target/release/*.exe
   ```

### CI/CD 配置

1. 创建 GitHub Actions 配置
   ```yaml
   # .github/workflows/release.yml
   name: Release
   on:
     push:
       tags:
         - 'v*'
   jobs:
     build:
       runs-on: windows-latest
       steps:
         - uses: actions/checkout@v3
         - name: Build
           run: cjpm build --release
   ```

## 版本管理

### 语义化版本

```
主版本号.次版本号.修订号

- 主版本号: 不兼容的 API 变更
- 次版本号: 向后兼容的功能新增
- 修订号: 向后兼容的问题修复
```

### 版本分支策略

```
main (稳定分支)
├── v1.0.x (补丁分支)
├── v1.1.x (功能分支)
└── v2.0.x (大版本分支)
```

## 构建配置

### cjpm.toml 配置

```toml
[package]
name = "everything_cli"
version = "1.0.0"
edition = "2024"

[build]
output-type = "executable"
optimize = "release"

[profile.release]
opt-level = 3
lto = true
```

### 多平台构建

```bash
# Windows
cjpm build --release --target x86_64-pc-windows-msvc

# Linux
cjpm build --release --target x86_64-unknown-linux-gnu

# macOS
cjpm build --release --target x86_64-apple-darwin
```

## 发布检查清单

### 代码检查

- [ ] 所有测试通过
- [ ] 代码格式化完成
- [ ] 无编译警告
- [ ] 文档完整

### 构建检查

- [ ] 开发构建成功
- [ ] 发布构建成功
- [ ] 所有目标平台构建成功

### 功能检查

- [ ] 核心功能正常
- [ ] CLI 工具正常
- [ ] HTTP API 正常

### 文档检查

- [ ] README.md 更新
- [ ] CHANGELOG.md 更新
- [ ] 版本号正确

## 发布脚本

```bash
#!/bin/bash
# release.sh
VERSION="${1:-1.0.0}"
TARGET="${2:-x86_64-pc-windows-msvc}"

# 构建
cjpm build --release --target "${TARGET}"

# 创建发布目录
mkdir -p "dist/everything_cli-${VERSION}"

# 复制文件
cp "target/${TARGET}/release/Everything-CJ.exe" "dist/everything_cli-${VERSION}/"
cp README.md CHANGELOG.md LICENSE "dist/everything_cli-${VERSION}/"

# 创建压缩包
cd dist
tar -czf "everything_cli-${VERSION}.tar.gz" "everything_cli-${VERSION}"
```

## 发布平台

### GitHub Releases

```bash
gh release create v${VERSION} \
  dist/everything_cli-${VERSION}.tar.gz \
  -t "Everything-CJ v${VERSION}" \
  -n "Release notes..."
```

### GitCode Releases

```bash
gitcode release create v${VERSION} \
  dist/everything_cli-${VERSION}.tar.gz
```

### 中心仓发布

```bash
cjpm publish --registry pkg.cangjie-lang.cn
```

## 文件结构

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主技能入口 |
| `README.md` | 发布管理概述 |
| `CHANGELOG.md` | 版本变更记录 |
| `references/release-checklist.md` | 发布检查清单 |
| `references/semver.md` | 语义化版本规范 |
