# 构建矩阵设计参考

## Cangjie SDK 1.1.3 可用平台

| SDK 文件 | 架构 | 模块路径 | 原生编译 | 交叉编译目标 |
|---------|------|---------|---------|-------------|
| `cangjie-sdk-linux-x64-1.1.3.tar.gz` | x86_64 | `linux_x86_64_cjnative` | Linux x64 | Windows x64 (gnu) |
| `cangjie-sdk-linux-aarch64-1.1.3.tar.gz` | ARM64 | `linux_aarch64_cjnative` | Linux ARM64 | Windows x64 (gnu) |
| `cangjie-sdk-mac-aarch64-1.1.3.tar.gz` | ARM64 | `darwin_aarch64_cjnative` | macOS ARM64 | ❌ 无 x86_64 模块 |

## GitHub Actions Runner 架构

| Runner | 架构 | OS | 可用 SDK |
|--------|------|-----|---------|
| `ubuntu-22.04` | x86_64 | Ubuntu 22.04 | linux-x64 (原生), linux-aarch64 (不可执行) |
| `ubuntu-22.04-arm` | ARM64 | Ubuntu 22.04 | linux-aarch64 (原生), linux-x64 (不可执行) |
| `macos-14` | ARM64 | macOS 14 (Sonoma) | mac-aarch64 (原生) |
| `macos-13` | x86_64 | macOS 13 (Ventura) | mac-aarch64 (通过 Rosetta 2) |
| `windows-latest` | x86_64 | Windows Server | 无 Cangjie SDK |

## 构建矩阵推荐配置

### 3 平台 (推荐)

```yaml
matrix:
  include:
    # Linux x64 — 原生
    - os: ubuntu-22.04
      target: linux-x64
      sdk: cangjie-sdk-linux-x64-1.1.3.tar.gz
      cjc_target: ''

    # macOS ARM64 — 原生
    - os: macos-14
      target: macos-aarch64
      sdk: cangjie-sdk-mac-aarch64-1.1.3.tar.gz
      cjc_target: ''

    # Windows x64 — 交叉编译
    - os: ubuntu-22.04
      target: windows-x64
      sdk: cangjie-sdk-linux-x64-1.1.3.tar.gz
      cjc_target: '--target x86_64-pc-windows-gnu'
```

### 4 平台 (含 Linux ARM64)

```yaml
matrix:
  include:
    # Linux x64 — 原生
    - os: ubuntu-22.04
      target: linux-x64
      sdk: cangjie-sdk-linux-x64-1.1.3.tar.gz
      cjc_target: ''

    # Linux ARM64 — 原生 (需要 ARM64 runner)
    - os: ubuntu-22.04-arm
      target: linux-aarch64
      sdk: cangjie-sdk-linux-aarch64-1.1.3.tar.gz
      cjc_target: ''

    # macOS ARM64 — 原生
    - os: macos-14
      target: macos-aarch64
      sdk: cangjie-sdk-mac-aarch64-1.1.3.tar.gz
      cjc_target: ''

    # Windows x64 — 交叉编译
    - os: ubuntu-22.04
      target: windows-x64
      sdk: cangjie-sdk-linux-x64-1.1.3.tar.gz
      cjc_target: '--target x86_64-pc-windows-gnu'
```

## 产物格式选择

| 平台 | 推荐格式 | 备选格式 | 说明 |
|------|---------|---------|------|
| Linux | `.tar.gz` | — | 标准压缩包 |
| macOS | `.dmg` | `.tar.gz` | DMG 支持拖拽安装 |
| Windows | `.exe` | `.zip` | 直接可执行文件 |

## 不可行的组合（已验证）

| 组合 | 错误 | 原因 |
|------|------|------|
| x64 Runner + aarch64 SDK | `Exec format error` | 架构不匹配 |
| mac-aarch64 SDK → x86_64 交叉编译 | `darwin_x86_64_cjnative not exist` | SDK 无 x86_64 模块 |
| macOS 不设 SDKROOT | `undefined symbol: _memcpy` | 链接器找不到系统库 |
| Linux 交叉编译 macOS | `library not found for -lSystem` | macOS 系统库不可用 |
