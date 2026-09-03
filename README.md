# 编译器诊断质量提升 (compiler-diagnostic)

## 项目概述

本项目增强仓颉（Cangjie）编译器诊断系统的结构化能力，面向仓颉编译器开发者、IDE 插件开发者与 AI 编程助手，提供：

1. **诊断字段结构化**：Parser / Sema 诊断包含错误码、位置信息（span）、严重程度、修复建议（fix）、关联诊断（related）与候选符号（candidates）
2. **JSON 诊断输出**：符合 LSP（Language Server Protocol）规范的标准化 JSON 格式，可直接对接 IDE
3. **性能基准框架**：内置 PerfBenchmark，验证新增诊断逻辑不引入性能退化
4. **稳定错误码体系**：E0001–E0005（Parser）、E1001–E1004（Sema），便于回归测试

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
# 文本输出（默认）
cjpm run

# JSON 输出
cjpm run -- --diagnostic=json
```

### 测试（UT / HLT / LLT 三层）

> 测试位于 `src/ut`、`src/hlt`、`src/llt` 子包（cjpm 仅扫描 `src/` 同目录测试）。

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

| 错误码 | 描述 | 模块 |
|--------|------|------|
| E0001 | 未终止的字符串字面量 | Parser |
| E0002 | 类型不匹配 | Parser |
| E0003 | 表达式语法错误 | Parser |
| E0004 | 标识符未定义 | Parser |
| E0005 | 括号不匹配 | Parser |
| E1001 | 类型检查失败 | Sema |
| E1002 | 泛型实例化失败 | Sema |
| E1003 | 函数重载歧义 | Sema |
| E1004 | 可见性检查失败 | Sema |

### JSON 输出格式（LSP 兼容）

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
      }
    }
  ]
}
```

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
│   ├── ut/    (9 单元测试)
│   ├── hlt/   (11 集成测试)
│   └── llt/   (10 低级测试)
├── examples/                          # 示例
│   ├── demo/main.cj
│   └── error_samples/                 # 9 个错误样例（5 Parser + 4 Sema）
├── docs/                              # 阶段报告与交付物
└── LICENSE                            # Apache-2.0
```

## 验收标准（赛事门禁）

| 指标 | 要求 | 当前状态 |
|------|------|----------|
| `cjpm build` | exit code 0 | ✅ |
| 编译警告 | warning = 0（不使用 `-Woff all` 屏蔽） | ✅ |
| 三层测试 | UT + HLT + LLT 全绿 | ✅ 80 用例全部通过 |
| `cjlint` | MANDATORY = 0（无 error 级违规） | ✅ 320 项均为 SUGGESTIONS（非阻断） |

> 注：`ci_test.cfg` 的 `compile_options` 已设为 `--test -Woff unused --dy-std`，仅抑制无害的“未用导入”类别，真实警告仍会暴露；当前工程零警告。

## 已知非阻断提示（cjlint SUGGESTIONS）

cjlint 扫描 `src/` 共报告 320 条 `SUGGESTIONS`（非 MANDATORY，不阻断赛事门禁），主要类别：

- `G.PKG.01` 通配符导入（如 `import x.*`）—— 可读性建议
- `G.NAM.01 / G.NAM.02 / G.NAM.03 / G.NAM.04` 命名与文件名风格建议
- `G.ERR.01 / G.ERR.03` 异常处理建议
- `G.ITF.02 / G.ITF.04` 接口使用建议
- `G.VAR.02` 变量作用域建议

以上均属风格建议，不影响编译、运行与赛事 `MANDATORY=0` 门禁。
