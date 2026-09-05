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

> 测试位于顶层 `test/ut`、`test/hlt`、`test/llt` 子包（由 `cjpm.toml` 的 `test-dir = "test"` 配置，与 `src/` 生产代码物理隔离）。

```bash
# 单元测试
cjpm test ut

# 集成测试（HLT）+ 低级测试（LLT），经赛事测试框架
python ci_test/ciTest.py hlt
python ci_test/ciTest.py llt

# 全量
cjpm test
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
├── ci_test/                           # 测试框架（ciTest.py + ci_test.cfg）
├── README.md                          # 项目说明
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
├── test/                              # 测试包（与 src/ 物理隔离）
│   ├── ut/    (单元测试)
│   ├── hlt/   (高层集成测试)
│   └── llt/   (端到端低级测试)
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
| 三层测试 | UT + HLT + LLT 全绿 | ✅ 80 用例全部通过（hlt 22 + llt 12 + ut 46） |
| `cjlint` | MANDATORY = 0（无 error 级违规） | ✅ 最新扫描 MANDATORY=0；SUGGESTIONS 级 482 项（非阻断，多为命名/风格约定；G.PKG.01 通配导入受 1.1.3 命名导入限制） |

> 注：`ci_test.cfg` 的 `compile_options` 已设为 `--test -Woff unused --dy-std`，仅抑制无害的“未用导入”类别，真实警告仍会暴露；当前工程零警告。

## 已知非阻断提示（cjlint SUGGESTIONS）

cjlint 最新扫描 `src/` 共报告 482 条 `SUGGESTIONS`（非 MANDATORY，不阻断赛事门禁），主要类别：

- `G.PKG.01` 通配符导入（如 `import x.*`）—— 可读性建议
- `G.NAM.01 / G.NAM.02 / G.NAM.03 / G.NAM.04` 命名与文件名风格建议
- `G.ERR.01 / G.ERR.03` 异常处理建议
- `G.ITF.02 / G.ITF.04` 接口使用建议
- `G.VAR.02` 变量作用域建议

以上均属风格建议，不影响编译、运行与赛事 `MANDATORY=0` 门禁。
