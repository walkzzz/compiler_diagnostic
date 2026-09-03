# 贡献指南（CONTRIBUTING）

感谢你关注 **compiler-diagnostic**（仓颉挑战赛 K1 技术课题：编译器诊断质量提升）。
本指南说明如何在本仓库下进行开发、测试与提交，确保持续满足赛事门禁。

---

## 1. 环境要求

| 组件 | 版本 |
|------|------|
| SDK | STS Cangjie 1.1.3（`cjc 1.1.3 cjnative`） |
| stdx | 1.1.3.1（已 vendored 于仓库 `cangjie-stdx-1.1.3.1/`，相对路径引用，无需安装） |
| 平台 | Windows x86_64（cjnative） |

> 编译器（SDK）由本地环境经 `CANGJIE_HOME` 提供；仓库不入库 SDK，仅入库 stdx 动态库。
> 切换 SDK / stdx 版本后请先执行 `cjpm clean` 再构建。

---

## 2. 本地开发流程

```bash
# 1) 构建
cjpm build

# 2) 运行（文本 / JSON 诊断输出，并附带性能基准打印）
cjpm run
cjpm run -- --diagnostic=json

# 3) 三层测试（UT / HLT / LLT）
cjpm test            # 全量
cjpm test ut         # 仅单元测试

# 4) 静态检查（赛事门禁：MANDATORY = 0）
cjlint -f src -o cjlint_report.json
```

> ⚠️ `cjlint` 的 `CANGJIE_HOME` 须为 **Windows 盘符风格**路径（如 `D:\path\to\cangjie`），
> 否则会报 `Can not find realpath`；而 `PATH` 须用 Git Bash 正斜杠风格。

---

## 3. 赛事门禁（提交前必须全部满足）

| 门禁 | 要求 | 命令 |
|------|------|------|
| 编译通过 | `cjpm build` exit 0 | `cjpm build` |
| 零警告 | warning = 0（**不得**用 `-Woff all` 屏蔽） | `ci_test/ci_test.cfg` → `--test -Woff unused --dy-std` |
| 三层测试全绿 | UT + HLT + LLT 全通过 | `cjpm test` |
| 静态检查 | `cjlint` MANDATORY = 0 | `cjlint -f src` |
| 可复现 | stdx 相对路径 vendored，干净克隆可编译 | 见 `cjpm.toml` |
| 合规 | 无本机绝对路径 / 用户名硬编码 | 全仓扫描 |

---

## 4. 编码规范

- 包名下划线分隔（`compiler_diagnostic`），类名大驼峰，方法/变量小驼峰。
- 公共 API 使用具名参数（`param!: Type`）声明，调用方可按名传参。
- 优先使用 `DiagnosticBuilder` 构造 `DiagnosticMessage`，避免直接调用其多重载构造函数。
- 错误码集中在 `src/diagnostics/Diagnostics.cj` 的 `ErrorCode` 枚举；新增诊断须补充 `code()` 与 `description()` 映射。
- 新增 `ErrorCode` 必须同步补充 `examples/error_samples/` 样例与三层测试。

---

## 5. 测试层级约定

| 层级 | 目录 | 职责 |
|------|------|------|
| UT | `src/ut` | 单元：单模块 / 单函数行为 |
| HLT | `src/hlt` | 集成：跨模块诊断组装与输出 |
| LLT | `src/llt` | 低级：边界、序列化、schema 一致性 |

测试类使用 `@Test` 宏；**避免使用含子串 `Check` 的类名**（cjlint `G_SEC.01` 会对宏展开产物误报 MANDATORY）。

---

## 6. 提交规范

- 提交信息以 `feat:` / `fix:` / `docs:` / `test:` 前缀，简述动机与门禁影响。
- 提交前请本地复跑 §3 全部门禁；CI 失败请优先排查 warning 与 cjlint MANDATORY。
- 切勿提交：SDK（`cangjie-sdk-1.1.3/`）、`*.zip`、构建产物（`target/`）、临时目录（`scratch/`）、个人路径。

---

## 7. 议题与讨论

仓库托管于 GitHub `walkzzz/compiler_diagnostic`。提交 Issue / PR 前请先阅读本文档与相关阶段报告（`docs/`）。
