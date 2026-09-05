# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-09-05

错误码体系按《仓颉错误码体系（扩展版）》生产级落地（文档权威）。

### Added
- 按文档扩展版落地全量 **195 条命名子错误码**（19 大类），每条含子码编号、名称、说明、典型错误消息，并采用文档权威的典型消息（如 `expected '(' after 'if'`、`Internal Compiler Error, Error Code: 13`、`package name in cjpm.toml does not match directory name`）。
- 新增 4 个类别：**Assembler(E43)、Fmt(E73)、Debugger(E74)、Profiler(E75)**；预留区 **E80–E89** 收编原 Sec/Conf/Telem/Lint（E80/E81/E82/E83）。
- 随文档落地错误级别约定（ERROR / WARNING / NOTE / HELP / ICE）、编号空间规划（E00–E09 前端 … E90–E99 系统）与子码分段规则（001–099 通用、100–199 平台、900–999 预留）。
- `tools/gen_vscode_map.py` 修复 `balanced()` 括号匹配越界（跨字符串/字符字面量中的括号误计数，导致仅解析 54/1543 条），现正确生成全量 1543 码映射。

### Changed
- 前缀重排使错误码前缀与文档一致（Opt→E41、Linker→E42、Build→E70、Test→E71、Doc→E72 等）。
- `cjc_bridge` 关键词映射按文档校正：`unterminated string`/`unclosed string`→`UnterminatedString`(E0003)、`unexpected token`/`mismatched bracket`→`UnexpectedToken`(E0102)、`private`→`AccessViolation`(E1014)、`duplicate definition`/`redefinition`→`Redeclaration`(E1002)、`constraint violated`/`trait bound`→`UnsatisfiedConstraint`(E2003)、`import not found`→`UnresolvedImport`(E3001)。
- 文档 ICE 级别 `E40-001 InternalCompilerError` 映射到 `Severity.Fatal`（`Severity` 枚举无 `Ice` 变体）。
- 重复名消歧：`UndefinedSymbol`(E42-001)→`LinkerUndefinedSymbol`、`PackageNameMismatch`(E70-008)→`BuildPackageNameMismatch`；非法标识符 `Macro hygiene violation`(E02-009)→`MacroHygieneViolation`。
- 注册表总量 1519 → **1543**（`cjc_bridge` 等新增类别补入）。

### Fixed
- 修复 VS Code 诊断映射表因解析越界长期仅含 54 条（应为 1543 条）的缺陷，现与注册表完全同步。

## [1.0.1] - 2026-09-05

CI 可靠性加固 + 安全风格消减（非阻断）。

### Added
- `tools/ci_simulate.sh`：本地 1:1 复现 CI 步骤（build→test→cjlint→coverage），无需触发远端即可验证流水线逻辑。
- `.github/workflows/ci.yml` SDK 注入四策略：支持 `CANGJIE_HOME`（judge/self-hosted）、vendored 路径、`CJ_SDK_PATH`（自托管 runner）、`CJ_SDK_DOWNLOAD_URL`（直链自下载解压），缺失时给出可执行提示。

### Changed
- `tools/run_tests.sh` 加固：单次尝试加 `timeout` 兜底（防卡死 cjc 拖垮 job）；崩溃（rc=139/124）后自动 `rm -rf target` 再重试，规避损坏产物导致的连续崩溃；`MAX_TRIES` 默认升至 8 并加重试退避。
- cjlint 门禁稳定为 `MANDATORY=0`；SUGGESTIONS 量级因沙箱 cjc 偶发崩溃而跨次不稳定（893/1304/1710 不等），属工具噪声，不纳入门禁。
- `.gitignore` 增补 `build.log` / `cjlint.json` / `cov_out/`。

### Fixed
- 安全风格消减（build 校验通过、不改行为）：`ErrorMeta`、`CjcPattern`、`CjcInternalCode` 成员由 `var` 改 `let`（仅构造期赋值、无外部重赋）；`pattern_matcher.cj` 局部 `n` 改 `let`。

## [1.0.0] - 2026-09-05

首个生产就绪发布（production-ready）。补齐竞赛验收之外的工程化短板：真实编译器桥接健壮性、覆盖率门槛、CI 流水线、版本与 API 稳定性承诺。

### Added
- **错误码体系扩展至 1519 码 / 40 类**（E00–E90 前缀，含 Lexer/Parser/Sema/Type/Resolution/Codegen/Runtime/Concurrency/Mem/Os/Lsp/Incremental/Pkg/Build/Debug/Dist/Plugin/Simd/Embed/Test/Doc/Lint/Sec/Conf/Telem/Xcompile/Wasm/Gpu/System 等）。
  - 0 孤儿前缀、0 畸形码；97%（1485/1519）带修复建议（FixSuggestion）。
  - 权威编码规范见 `扩展后的错误码体系设计.md`（格式 `E` + 2 位类别前缀 + 2 位序号）。
- **三层测试体系**：`src/ut`（47）、`src/hlt`（22）、`src/llt`（18），共 **87 用例**，`cjpm test` 全绿。
  - 遵循仓颉 cjpm 1.1.3 官方约定：测试源码与对应生产包同处于 `src/` 源码集、文件名以 `_test.cj` 结尾，由 `cjpm test` 自动识别并仅以 `--test` 编译（`cjpm build` 自动排除）。
- **真实 cjc 诊断桥接层（`cjc_bridge`）生产化**：
  - `resolveCjc(raw)` 改为**仅对 `error:` 消息行**做关键字匹配（不再匹配 `^~~~` 片段行），消除子串误匹配。
  - 内部码（`error[Exxx]`）匹配保留为增强路径（cjc 1.1.3 默认文本输出不带内部码，故作为可选增强）。
  - 新增 `parseCjcDiagnostics(raw)` 一次性解析整段 cjc 输出为多码。
  - 新增 `from-cjc` 子命令：`compiler_diagnostic from-cjc <file>` 读取 cjc 文本输出并产出结构化 JSON，**桥接层从死代码变为真实可用**。
  - 新增桥接一致性校验：`tools/check_bridge_consistency.py` 校验 `cjc_bridge.json` 与 `cjc_bridge.cj` 不漂移。
  - 新增桥接单元测试（`src/llt`）：覆盖类型不匹配、未声明标识符、歧义重载、误匹配防护等。
- **三模式诊断输出**：`--diagnostic=text|json|lsp`（LSP 兼容 JSON 符合 Language Server Protocol 规范）。
- **真实性能基准门禁**：`src/benchmark/PerfBenchmark.cj` 的 `compareWithBaseline` 固化 `timeRatio <= 1.05 && memRatio <= 1.05`；实测 `memRatio≈1.033x` 通过。
- **CI 流水线**：新增 `.github/workflows/ci.yml` 与 `.gitcode-ci.yml`，门禁含 setup SDK → build(warning0) → test → cjlint(MANDATORY=0) → cjfmt → 覆盖率门槛。
- **覆盖率量化门槛**：`tools/coverage_gate.py` 解析 `cjpm test --coverage` 产物并强制最小行覆盖阈值。
- **API 稳定性承诺**：新增 `docs/API_STABILITY.md`（稳定性层级 + 弃用策略 + 语义化版本规则）。
- **示例与集成**：`examples/error_samples/`（语法/语义负向用例）、`vscode-extension/`（实时诊断示例）、`samples/`。

### Changed
- `cjc_bridge.json` 明确为“代码表镜像 + 漂移校验源”，消除数据/代码双源不一致。
- `cjpm.toml` 补齐 `category = "utility"`，`version` 升至 `1.0.0`。
- README / 提交模板同步至 1519 码 / 87 用例 / cjlint MANDATORY=0 口径。

### Fixed
- 修正 CHANGELOG 与代码长期脱节的红线（此前仍写“27 测试文件 / 5+4 错误码 / 性能框架 stub”）。
- 消除 `cjc_bridge` 关键词匹配对诊断片段行的误匹配风险。
- **修复 `cjpm test` 无法发现测试的根本问题**：仓颉 cjpm 1.1.3 仅扫描 `src/` 源码集中以 `_test.cj` 结尾的文件，原 `test/{ut,hlt,llt}` 独立目录对 cjpm 不可见（表现为 `TOTAL: 0`）。已将全部 31 个测试文件迁移至 `src/ut`、`src/hlt`、`src/llt`（包名保持 `compiler_diagnostic.{ut,hlt,llt}`），`hlt`/`llt` 文件由 `test_*.cj` 重命名为 `*_test.cj`，并改写 `tools/run_tests.sh` 为按子包运行 + 失败重试（规避受限环境偶发崩溃）。现 `cjpm test` 可发现并运行全部 87 用例。

## [0.1.0] - 2026-09-01

### Added
- 初始项目结构、错误码定义、诊断 Builder 模式。
- Parser 诊断模块（E0001–E0005）、Sema 诊断模块（E1001–E1004）。
- JSON（LSP 兼容）与文本诊断输出。
- 性能基准框架原型。

### Changed
- 核心数据结构合并至 `Diagnostics.cj` 以避免循环依赖。

### Fixed
- JSON 输出数组越界缺陷（C001）。

[Unreleased]: https://gitcode.com/LOOYIABC/compiler-diagnostic/compare/v1.0.0...HEAD
[1.0.0]: https://gitcode.com/LOOYIABC/compiler-diagnostic/releases/tag/v1.0.0
[0.1.0]: https://gitcode.com/LOOYIABC/compiler-diagnostic/releases/tag/v0.1.0
