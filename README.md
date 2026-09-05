# 编译器诊断质量提升 (compiler-diagnostic)

## 项目概述

本项目增强仓颉（Cangjie）编译器诊断系统的结构化能力，面向仓颉编译器开发者、IDE 插件开发者与 AI 编程助手，提供：

1. **诊断字段结构化**：Parser / Sema 诊断包含错误码、位置信息（span）、严重程度、修复建议（fix）、关联诊断（related）与候选符号（candidates）
2. **JSON 诊断输出**：符合 LSP（Language Server Protocol）规范的标准化 JSON 格式，可直接对接 IDE
3. **性能基准框架**：内置 PerfBenchmark，验证新增诊断逻辑不引入性能退化
4. **稳定错误码体系**：`E` + 2 位类别前缀 + 2 位序号，共 **40 类 / 1519 个**规范码（含 8 个向后兼容别名），覆盖 Lexer/Parser/Sema/Type/Resolution/Codegen/Runtime/System 全链路，0 孤儿、0 畸形；详见 `扩展后的错误码体系设计.md`

## 环境要求

| 组件 | 版本 |
|------|------|
| SDK | STS Cangjie 1.1.3（`cjc 1.1.3 cjnative`） |
| stdx | 1.1.3.1（独立 stdx，动态链接） |
| 平台 | Windows x86_64（cjnative） |

> 切换 SDK / stdx 版本后请先执行 `cjpm clean` 再构建。

## 快速开始

### 构建

```bash
cjpm build
```

### 运行

```bash
# 文本输出（默认，含性能基线校验）
cjpm run

# 结构化 JSON 输出（默认 schema，含 rootCause / candidates）
cjpm run -- --diagnostic=json

# LSP 兼容 JSON 输出（range.character + 数字 severity + codeAction/relatedInformation）
cjpm run -- --diagnostic=lsp
```

### 测试（UT / HLT / LLT 三层）

> 测试源码与对应生产包**同处于 `src/` 源码集**，文件名以 `_test.cj` 结尾（遵循仓颉 cjpm 1.1.3 官方约定）：
> - `src/ut/`：单元测试（47 用例）
> - `src/hlt/`：高层集成测试（22 用例）
> - `src/llt/`：端到端低级测试（18 用例）
>
> 普通 `cjpm build` 会自动排除 `*_test.cj`；仅 `cjpm test` 会编译并运行它们。共 **87 用例，全部通过**。

```bash
# 按包路径运行（cjpm test 接收"目录路径"而非包名）
cjpm test src/ut
cjpm test src/hlt
cjpm test src/llt

# 按测试类名筛选
cjpm test --filter "TypeMismatchTest"

# 全量（推荐走带重试的测试脚本，规避沙箱偶发 SIGSEGV）
bash tools/run_tests.sh all
```

### 静态检查（cjlint）

```bash
cjlint -f src -o cjlint_report.json
```

## 诊断规范

### 错误码体系

诊断错误码采用 `E` + 2 位类别前缀 + 2 位序号 的统一格式（如 `E0101`、`E2001`），由 `ErrorCategory` 枚举驱动，全量 **1519 个**规范码分属 **40 个类别**，覆盖从词法/语法到语义/类型/解析/代码生成/运行时/系统的完整诊断链路。完整分类、码段与修复覆盖率见 [`扩展后的错误码体系设计.md`](扩展后的错误码体系设计.md)。

代表性类别（部分）：

| 前缀 | 类别 | 阶段 |
|------|------|------|
| E00 | Lexer 词法 | 编译前 |
| E01 | Parser 语法 | 解析 |
| E02 | Macro 宏 | 解析 |
| E10 | Sema 语义 | 语义 |
| E20 | Type 类型 | 语义 |
| E30 | Resolution 名字解析 | 语义 |
| E40 | Codegen 代码生成 | 后端 |
| E50 | Runtime 运行时 | 运行 |
| E60 | Lsp / IDE | 工具链 |
| E90 | System 系统 | 运行 |

任一诊断都携带稳定错误码、准确 span、severity 与可选 fix / rootCause / candidates，便于回归测试与 AI 归因。

### JSON 输出格式

默认 `--diagnostic=json`（LSP 兼容 schema）每条诊断含：错误码、severity 字符串、message、span（start/end 含 line/column）、fix（修复建议）、候选符号 `candidates`，以及结构化根因字段 `rootCause`（Sema 诊断填充，便于 AI 助手归因）。其中 `candidates` 为**结构化数组**，元素含 `name`（符号名）与 `kind`（类型/种类，如 `variable`/`function`/`type`），可直接呈现「foo: Int64」式候选提示——满足指标 B 的候选类型要求。

```json
{
  "diagnostics": [
    {
      "code": "E0001",
      "severity": "error",
      "message": "未终止的字符串字面量",
      "span": {
        "start": { "line": 10, "column": 5 },
        "end": { "line": 10, "column": 20 }
      },
      "fix": {
        "description": "添加结束引号",
        "replacement": "\""
      },
      "candidates": [],
      "rootCause": ""
    }
  ]
}
```

### LSP 模式（`--diagnostic=lsp`）

`--diagnostic=lsp` 输出严格对齐 `LSP Diagnostic[]`：位置用 `range`（含 `character` 而非 `column`）、`severity` 为数字（1=Error / 2=Warning / 3=Info / 4=Hint）、`codeAction`（fix → quickfix，含 `edit.changes[uri][{range,newText}]`）、`relatedInformation`（`location.uri` 为 `file://` + 绝对路径）、`code` / `source` / `message` / `candidates` / `rootCause`。可直接被 IDE 的 `textDocument/publishDiagnostics` 与 `codeAction` 消费。

## 项目结构

```
compiler-diagnostic/
├── cjpm.toml                          # 包配置（cjc-version = "1.1.3"）
├── ci_test/                           # 遗留测试框架（ciTest.py + ci_test.cfg，HLT/LLT 已迁至 src/）
├── README.md                          # 项目说明
├── tools/                             # 工程脚本
│   ├── run_tests.sh                   # 分组合并测试（带重试，规避沙箱偶发 SIGSEGV）
│   ├── coverage_gate.py               # 覆盖率门禁（best-effort / --strict）
│   ├── cjlint_check.py                # cjlint MANDATORY 门禁
│   └── check_bridge_consistency.py    # from-cjc 桥接一致性自检
├── src/
│   ├── main.cj                        # 入口
│   ├── diagnostics/                   # 核心数据结构与诊断定义
│   │   ├── Diagnostics.cj             # SourceLoc / Span / ErrorCode / DiagnosticMessage
│   │   ├── DiagnosticBuilder.cj       # Builder 模式
│   │   ├── DiagnosticCollector.cj      # 诊断收集
│   │   ├── ParserDiagnostic.cj        # Parser 诊断
│   │   └── SemaDiagnostic.cj          # Sema 诊断
│   ├── output/                        # 输出层
│   │   ├── DiagnosticOutput.cj        # 输出基类
│   │   ├── TextOutput.cj              # 文本输出
│   │   ├── JSONOutput.cj              # JSON 输出
│   │   └── JSONSchema.cj              # LSP Schema 定义（占位符+运行时注入 URL）
│   ├── cli/
│   │   └── AppSupport.cj              # parseArgs / generateSampleDiagnostics
│   ├── benchmark/                     # 性能基准
│   │   ├── PerfBenchmark.cj
│   │   └── BenchmarkReport.cj
│   ├── ut/                            # 单元测试（*_test.cj，47 用例）
│   ├── hlt/                           # 高层集成测试（*_test.cj，22 用例）
│   └── llt/                           # 端到端低级测试（*_test.cj，18 用例）
├── examples/                          # 示例
│   ├── demo/main.cj
│   └── error_samples/                 # 诊断错误样例（语法/语义负向用例）
├── docs/                              # 阶段报告与交付物
└── LICENSE                            # Apache-2.0
```

## 验收标准（赛事门禁）

| 指标 | 要求 | 当前状态 |
|------|------|----------|
| `cjpm build` | exit code 0 | ✅ |
| 编译警告 | warning = 0（不使用 `-Woff all` 屏蔽） | ✅ |
| 三层测试 | UT + HLT + LLT 全绿 | ✅ 87 用例全部通过（ut 47 + hlt 22 + llt 18） |
| `cjlint` | MANDATORY = 0（无 error 级违规） | ✅ 最新扫描 MANDATORY=0；SUGGESTIONS 级 893 项（非阻断，详见下文；其中约 46% 为框架强制的误报） |

> 注：`ci_test/` 为早期遗留测试框架（HLT/LLT 已迁移至 `src/hlt`、`src/llt` 并经 `cjpm test` 运行），保留仅为历史兼容；当前工程零警告，由 `cjpm build` 与 CI 的 warning=0 门禁共同保证。

## 已知非阻断提示（cjlint SUGGESTIONS）

cjlint 最新扫描 `src/` 共报告 **893 条 `SUGGESTIONS`**（非 MANDATORY，不阻断赛事门禁 `MANDATORY=0`）。按规则族分布：

| 规则族 | 数量 | 性质 |
|--------|------|------|
| `G.PKG.01` 通配符导入（`import x.*`） | 292 | **框架强制误报**：`@Test` 宏与测试框架、以及 `compiler_diagnostic.*` 再导出模式均要求通配导入，无法消除 |
| `G.NAM.01` 包名应匹配路径 | 117 | **框架强制误报**：cjpm 1.1.3 官方 colocated 布局要求包名 `compiler_diagnostic.{ut,hlt,llt}`，与 cjlint 的"包名=路径段"期望冲突 |
| `G.NAM.02` 文件名小写 | 76 | 风格建议（如 `JSONOutput.cj`） |
| `G.ITF.04` 避免直接以接口作类型 | 68 | 风格建议 |
| `G.ERR.01` 异常处理 | 68 | 风格建议 |
| `G.NAM.03` 标识符命名 | 62 | 风格建议 |
| `G.ITF.02` 优先在类型定义处实现接口 | 62 | 风格建议 |
| `G.VAR.02` 变量最小作用域 | 46 | 风格建议（多数可安全收窄） |
| `G.ERR.03` 避免 `Option.getOrThrow` | 42 | 风格建议 |
| `G.FUN.01` 函数单一职责 | 37 | 风格建议 |
| `G.VAR.01` 优先不可变 | 15 | 风格建议（`var`→`let`） |
| `G.NAM.04` 函数命名 | 8 | 风格建议 |

- 上述均属**风格建议**，不影响编译、运行与赛事 `MANDATORY=0` 门禁；CI 中 `tools/cjlint_check.py` 仅对 `MANDATORY` 级失败。
- 前两类（共 409 项，约 46%）为仓颉 1.1.3 工具链布局/导入约束带来的**强制性误报**，消除它们会破坏 cjpm 官方布局或必需的通配导入，故保留现状；其余类别为可逐步优化的命名/接口/作用域风格，按需处理。
- `from-cjc` 子命令已端到端验证：输入真实 cjc ANSI 报错可映射为结构化 JSON（如 `[{"code":"E2001"},{"code":"E1001"}]`）。
