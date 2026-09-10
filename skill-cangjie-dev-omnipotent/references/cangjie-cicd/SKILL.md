---
name: cangjie-cicd
description: >
  仓颉多平台发布工程专家。负责跨平台构建矩阵、二进制产物打包、GitHub Release 自动化。
  当用户需要 CI/CD 配置、多平台构建、二进制分发、发布流水线时使用。
  涵盖 GitHub Actions workflow 编写、Cangjie SDK 下载与配置、交叉编译、
  .exe/.dmg/.tar.gz 产物打包、Release 自动创建、构建矩阵设计。
author: cangjie-expert-team
version: 1.0.0
rail:
  capabilities: [github-actions, cross-compile, release, dmg, exe, tarball]
  constraints: [no-secret-in-workflow, no-skip-checks]
  requires: [github-repo-access, cangjie-sdk-url]
  provides: [workflow-yml, build-matrix, release-assets]
  collaborates_with: [cangjie-release, cangjie-tools, cangjie-doc]
---

# 仓颉多平台发布工程专家 (CJ-CICD)

负责跨平台构建矩阵、二进制产物打包、GitHub Release 自动化全流程。

## 触发场景

- "配置 CI/CD" / "GitHub Actions" / "自动构建"
- "多平台构建" / "交叉编译" / "构建矩阵"
- "创建 Release" / "发布二进制" / "打包 .exe/.dmg"
- "构建流水线" / "发布流水线"
- 任何涉及仓颉项目持续集成与持续交付的任务

## 核心能力

### 1. 跨平台构建矩阵设计

根据目标平台和可用 Cangjie SDK，设计最优构建矩阵：

```
┌─────────────────────────────────────────────────────────┐
│                   构建矩阵决策表                          │
├─────────────┬───────────────┬──────────┬────────────────┤
│ 目标平台     │ Runner        │ SDK      │ 构建方式        │
├─────────────┼───────────────┼──────────┼────────────────┤
│ Linux x64   │ ubuntu-22.04  │ linux-x64│ 原生编译        │
│ Linux ARM64 │ ubuntu-22.04  │ aarch64  │ 原生编译        │
│ macOS ARM64 │ macos-14      │ mac-a64  │ 原生编译        │
│ Windows x64 │ ubuntu-22.04  │ linux-x64│ 交叉编译        │
└─────────────┴───────────────┴──────────┴────────────────┘
```

**关键决策规则：**

1. **SDK 架构必须匹配 Runner 架构**（原生编译时）
   - ❌ 在 x64 runner 上用 aarch64 SDK → `Exec format error`
   - ✅ 在 x64 runner 上用 x64 SDK
2. **交叉编译需要目标平台模块存在**
   - ❌ mac-aarch64 SDK 交叉编译 x86_64 → `darwin_x86_64_cjnative not exist`
   - ✅ linux-x64 SDK 交叉编译 windows → `x86_64-pc-windows-gnu`
3. **macOS 需要 SDKROOT 环境变量**
   - 不设置 → `ld64.lld: undefined symbol: _memcpy`
   - 用 `xcrun --sdk macosx --show-sdk-path` 获取路径

### 2. Cangjie SDK 下载与配置

#### SDK 下载 URL 获取

SDK 地址在 cangjie-lang.cn 的 JS 文件中，不在静态 HTML 中：

```bash
# 1. 下载 version.js
curl -s "https://csdnimg.cn/release/devpress-cangjie/public/js/chunk/organization/download/version.8e688f93.js" -o /tmp/version.js

# 2. 解析 SDK URL
python3 -c "
import re
with open('/tmp/version.js') as f:
    content = f.read()
pattern = r'downLoad\?nsId=(\d+)&fileName=(cangjie-sdk-[^&]+\.tar\.gz)&objectKey=([a-f0-9]+)\"'
for m in re.findall(pattern, content):
    if '1.1.3' in m[1] and 'android' not in m[1] and 'ohos' not in m[1] and 'ios' not in m[1]:
        print(f'nsId={m[0]}  {m[1]}  objectKey={m[2]}')
"
```

#### 已知 SDK URL (1.1.3)

| SDK | objectKey | 大小 |
|-----|-----------|------|
| `cangjie-sdk-linux-x64-1.1.3.tar.gz` | `6a19349d21f5a8178d6fd22b` | ~403 MB |
| `cangjie-sdk-linux-aarch64-1.1.3.tar.gz` | `6a19350321f5a8178d6fd22c` | ~378 MB |
| `cangjie-sdk-mac-aarch64-1.1.3.tar.gz` | `6a19312721f5a8178d6fd225` | ~245 MB |

URL 模式：
```
https://cangjie-lang.cn/v1/files/auth/downLoad?nsId=142267&fileName={sdk_file}&objectKey={object_key}
```

#### 环境变量配置

```bash
SDK_DIR="$(pwd)/cangjie"
export CANGJIE_HOME="$SDK_DIR"
export PATH="$SDK_DIR/bin:$SDK_DIR/tools/bin:$PATH"

# Linux
export LD_LIBRARY_PATH="$SDK_DIR/runtime/lib/linux_x86_64_cjnative:$SDK_DIR/lib/linux_x86_64_cjnative"

# macOS
export DYLD_LIBRARY_PATH="$SDK_DIR/runtime/lib/darwin_aarch64_cjnative:$SDK_DIR/lib/darwin_aarch64_cjnative"
export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
```

### 3. 二进制产物打包

#### Linux → tar.gz

```bash
cjc src/main.cj -s -o everything-cj-linux-x64
tar -czf everything-cj-v1.0.0-linux-x64.tar.gz everything-cj-linux-x64
sha256sum everything-cj-v1.0.0-linux-x64.tar.gz > everything-cj-v1.0.0-linux-x64.tar.gz.sha256
```

#### Windows → .exe (直接可执行)

```bash
# 交叉编译
cjc src/main.cj --target x86_64-pc-windows-gnu -s -o everything-cj-windows-x64.exe
# .exe 直接作为 Release asset，无需打包
sha256sum everything-cj-windows-x64.exe > everything-cj-windows-x64.exe.sha256
```

#### macOS → .dmg (磁盘映像安装包)

```bash
# 原生编译
SYSROOT=$(xcrun --sdk macosx --show-sdk-path)
cjc src/main.cj -B "$SYSROOT/usr/lib" -B "$SYSROOT/usr/lib/system" -s -o everything-cj-macos-aarch64

# 创建 DMG (支持拖拽安装)
mkdir -p dmg_content
cp everything-cj-macos-aarch64 dmg_content/
ln -s /Applications dmg_content/Applications
hdiutil create -volname "Everything-CJ" -srcfolder dmg_content -ov -format UDZO everything-cj-v1.0.0-macos-aarch64.dmg
shasum -a 256 everything-cj-v1.0.0-macos-aarch64.dmg > everything-cj-v1.0.0-macos-aarch64.dmg.sha256
```

### 4. GitHub Actions Workflow 模板

#### 完整多平台构建 workflow

关键点：
- `"on"` 必须加引号（YAML 1.1 中 `on` 是布尔值）
- `permissions: contents: write` 是创建 Release 的必需权限
- `fail-fast: false` 确保一个平台失败不影响其他平台
- macOS 步骤需要 `if: runner.os == 'macOS'` 条件判断

```yaml
name: Build Multi-Platform

"on":
  push:
    tags:
      - 'v*'
  workflow_dispatch:

permissions:
  contents: write

jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: ubuntu-22.04
            target: linux-x64
            # ... SDK 配置
          - os: macos-14
            target: macos-aarch64
            # ... SDK 配置
          - os: ubuntu-22.04
            target: windows-x64
            # ... SDK 配置 (交叉编译)

    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - name: Download Cangjie SDK
        run: |
          wget --no-check-certificate "${{ matrix.sdk_url }}" -O ${{ matrix.sdk_file }}
          tar -zxf ${{ matrix.sdk_file }}
      - name: Setup environment
        run: |
          SDK_DIR="$(pwd)/cangjie"
          echo "CANGJIE_HOME=$SDK_DIR" >> $GITHUB_ENV
          echo "$SDK_DIR/bin" >> $GITHUB_PATH
      - name: Setup macOS SDK
        if: runner.os == 'macOS'
        run: |
          echo "SDKROOT=$(xcrun --sdk macosx --show-sdk-path)" >> $GITHUB_ENV
      - name: Build
        run: |
          cjc src/main.cj ${{ matrix.cjc_target }} -s -o ${{ matrix.artifact_name }}
      - name: Create macOS .dmg
        if: runner.os == 'macOS'
        run: |
          mkdir -p dmg_content
          cp ${{ matrix.artifact_name }} dmg_content/
          ln -s /Applications dmg_content/Applications
          hdiutil create -volname "App" -srcfolder dmg_content -ov -format UDZO app.dmg
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-${{ matrix.target }}
          path: |
            ${{ matrix.artifact_name }}
            app-*.dmg

  release:
    needs: build
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/')
    steps:
      - uses: actions/download-artifact@v4
        with:
          path: artifacts
      - uses: softprops/action-gh-release@v2
        with:
          files: |
            artifacts/**/app-*.tar.gz
            artifacts/**/app-*.exe
            artifacts/**/app-*.dmg
            artifacts/**/*.sha256
```

### 5. GitHub Release 自动化

#### 创建 GitHub 仓库 (需要 PAT)

```bash
# 创建仓库
curl -s -X POST -H "Authorization: token $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/user/repos \
  -d '{"name": "repo-name", "private": false}'

# 推送代码
git remote add github git@github.com:user/repo.git
git push github master

# 推送标签触发 Actions
git tag -a v1.0.0 -m "Release v1.0.0"
git push github v1.0.0
```

#### 手动触发 workflow

```bash
curl -s -X POST -H "Authorization: token $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/user/repo/actions/workflows/build.yml/dispatches" \
  -d '{"ref":"master"}'
```

#### 监控构建状态

```bash
# 查看 workflow runs
curl -s -H "Authorization: token $GH_TOKEN" \
  "https://api.github.com/repos/user/repo/actions/runs?per_page=5"

# 查看各 job 状态
curl -s -H "Authorization: token $GH_TOKEN" \
  "https://api.github.com/repos/user/repo/actions/runs/$RUN_ID/jobs"

# 查看失败 job 日志
curl -s -L -H "Authorization: token $GH_TOKEN" \
  "https://api.github.com/repos/user/repo/actions/jobs/$JOB_ID/logs"
```

## 默认工作流

### 1. 需求确认
- 目标平台列表（Linux x64 / macOS ARM64 / Windows x64）
- 产物格式（tar.gz / .exe / .dmg）
- 版本号
- 仓库地址（GitHub / GitCode）

### 2. 构建矩阵设计
- 查询可用 Cangjie SDK
- 匹配 Runner 架构与 SDK 架构
- 确定交叉编译可行性

### 3. Workflow 编写
- 编写 .github/workflows/build.yml
- 配置 SDK 下载、环境变量、构建步骤
- 配置产物打包（tar.gz / .exe / .dmg）
- 配置 Release 自动创建

### 4. 触发与验证
- 推送标签触发构建
- 监控各平台构建状态
- 检查 Release 产物完整性

### 5. 问题排查
- 查看失败 Job 日志
- 修复 SDK 架构不匹配
- 修复 macOS 链接器路径
- 修复 YAML `on` 关键字解析

## 常见问题与解决方案

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| `Exec format error` | SDK 架构与 Runner 不匹配 | 使用匹配架构的 SDK |
| `undefined symbol: _memcpy` | macOS 链接器找不到系统库 | 设置 SDKROOT 环境变量 |
| `target library path is not exist` | SDK 缺少目标平台模块 | 该平台不支持交叉编译，需原生 Runner |
| Workflow 不触发 | YAML `on` 被解析为布尔值 | 用 `"on"` 加引号 |
| Release 创建 403 | GITHUB_TOKEN 权限不足 | 添加 `permissions: contents: write` |
| `cjpm build` 子包名错误 | 子目录包名不符合 `parent.child` 规范 | 用 `cjc` 单文件编译替代 |

## 文件结构

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主技能入口（本文件） |
| `references/build-matrix.md` | 构建矩阵设计详细参考 |
| `references/sdk-urls.md` | Cangjie SDK 下载地址汇总 |
| `references/workflow-templates.md` | GitHub Actions workflow 完整模板 |
