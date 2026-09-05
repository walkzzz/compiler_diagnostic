# API 稳定性承诺（API Stability）

本文件定义 `compiler-diagnostic` 的公开 API 稳定性层级、弃用策略与版本规则，作为生产采用方的契约依据。

## 1. 稳定性层级

公开 API 按稳定性分为三级，标注于对应符号的文档注释（`/// 稳定性: stable|beta|unstable`）：

| 层级 | 含义 | 兼容性承诺 |
|------|------|------------|
| **stable** | 已稳定，应用于生产 | 次版本号（MINOR）内保持向后兼容；破坏性变更仅在 MAJOR 升级并给出迁移指南 |
| **beta** | 功能可用，接口可能在 MINOR 内微调 | 保留向下兼容或提供 1 个 MINOR 的过渡期 |
| **unstable** | 实验性，可能变动 | 不保证兼容，变更不另行通知，仅用于尝鲜与反馈 |

当前 stable 范围（1.0.0）：
- 错误码体系与 `ErrorCode` 枚举（`src/diagnostics/Diagnostics.cj`）：**stable**。新增错误码以「追加新前缀/E 码」方式扩展，不重用、不删除已有码。
- 三模式诊断输出 `--diagnostic=text|json|lsp`：JSON/LSP 输出 schema **stable**。
- `from-cjc` 子命令（消费真实 cjc 文本输出）：**beta**（输入格式依赖 cjc 文本协议，随 SDK 演进可能调整）。
- `cjc_bridge` 桥接层内部表（`CJC_PATTERNS` / `CJC_INTERNAL`）：**beta**（映射随 cjc 文案演进扩充）。

## 2. 错误码稳定性（核心承诺）

- 错误码格式：`E` + 2 位类别前缀 + 2 位序号（如 `E2001`）。
- **零废弃**：已发布的错误码不会被删除或更改语义；如确需变更，分配新码并保留旧码至少 2 个 MAJOR。
- 新增码只追加，不重用序号；前缀由 `ErrorCategory.codePrefix()` 注册表统一管理（见 `扩展后的错误码体系设计.md`）。
- 未知/未来 cjc 文案在桥接层映射为 `None`，上层回退原始文本，绝不静默误映射。

## 3. 弃用策略

- 任何弃用需满足：① 至少提前 1 个 MINOR 在 `CHANGELOG.md` 与本文档标注；② 保留兼容别名或重载至少 1 个 MINOR；③ 提供迁移示例。
- 移除 stable API 仅允许在 MAJOR 版本，且必须在 `CHANGELOG.md` 的 `### Removed` 段说明并提供升级脚本/指南。

## 4. 语义化版本规则（SemVer）

- **MAJOR**：破坏性变更（删除/重命名 stable API、错误码语义变更、JSON/LSP schema 不兼容）。
- **MINOR**：向后兼容的功能新增（新增 stable API、新增错误码、新增输出模式）。
- **PATCH**：缺陷修复、内部重构、文档修正、beta API 调整。

## 5. 兼容性矩阵

| 组件 | 支持版本 |
|------|----------|
| 仓颉 SDK | 1.1.3 (STS)；预留 LTS 1.0.5 适配接口 |
| 操作系统 | Windows (x86_64) 原生；鸿蒙/服务端为规划目标 |
| 依赖 | 仅 `std` / `stdx`，无第三方依赖 |

## 6. 支持与反馈

- 问题反馈：通过赛事官方渠道或仓库 Issue。
- 生态贡献：见 `docs/14-作品提交模板.md` 的「仓颉AI生态贡献加分申请」章节。
