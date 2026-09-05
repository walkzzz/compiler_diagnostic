# 真实 cjc 诊断 → E 码桥接表（C 方案）

> 配套实现：`src/diagnostics/cjc_bridge.cj`（`resolveCjc(raw): Option<ErrorCode>`）+ 数据表 `src/diagnostics/cjc_bridge.json`。
> 作用：把仓颉编译器 `cjc` **真实输出**的诊断文本映射为本工程的 `ErrorCode` 体系，使 JSON/LSP 输出、VS Code 插件、CI 门禁都用同一套 E 码消费诊断，无需硬编码 cjc 内部码。

## 1. 真实 cjc 诊断输出形态

仓颉 `cjc` 诊断同时出现在 stdout/stderr，典型格式（节选自 intellij-cangjie 仓库实测与官方文档）：

```
error: mismatched types ==> main.cj:3:10:
    let x: Int64 = "hello"
                ^~~~~~~
note: expected `Int64`, found `String`
```

部分版本会带内部码（intellij-cangjie 维护的官方码表）：

```
error[E667]: type mismatch ...
```

本桥接层同时消费两类信号：**内部码 `[Exxx]`**（精确、优先级最高）与**消息关键词**（兜底、覆盖面广）。

## 2. 桥接表（与 cjc_bridge.json 同义）

### 2.1 内部码精确映射

| cjc 内部码 | 本工程 ErrorCode | 语义 |
|-----------|----------------|------|
| E667 | `TypeMismatch` (E2001) | 类型不匹配 |
| E75  | `SemaUndefinedSymbol` (E1001) | 未声明的标识符 |
| E673 | `SemaDuplicateImportItem` (E3558) | 重复定义 |
| E488 | `ResolutionModuleNotFound` (E3643) | 包 / 模块未找到 |
| E671 | `TypeInferenceFailed` (E3613) | 无法推断类型 |

### 2.2 关键词 / 子串映射（顺序即优先级，越靠前越具体）

| 命中子串（小写） | 映射到 ErrorCode |
|----------------|----------------|
| `unterminated string` / `unclosed string` | `ParserUnterminatedString` |
| `mismatched bracket` | `ParserMismatchedBracket` |
| `unexpected token` | `ParserInvalidExpression` |
| `unexpected end of file` | `ParserUnexpectedToken` |
| `duplicate import` | `ParserDuplicateImport` |
| `undeclared identifier` / `cannot find` | `SemaUndefinedSymbol` |
| `cannot infer` / `type inference` | `TypeInferenceFailed` |
| `duplicate definition` / `redefinition` | `SemaDuplicateImportItem` |
| `mismatched types` / `type mismatch` | `TypeMismatch` |
| `ambiguous` | `TypeAmbiguousOverload` |
| `constraint violated` / `trait bound` | `TypeConstraintViolation` |
| `private` | `ResolutionPrivateAccess` |
| `module not found` | `ResolutionModuleNotFound` |
| `import not found` | `ResolutionImportNotFound` |
| `macro` | `MacroUndefinedIdentifier` |
| `null pointer` / `null dereference` | `RuntimeNullDereference` |
| `llvm verify` | `BackendLlvmVerifyFailed` |
| `linker` | `CodegenLinkerFailed` |

> 全部目标均为**已确认存在的** `ErrorCode` 变体（1519 个枚举之一）；新增映射只需在 `cjc_bridge.cj` 的 `buildCjcPatterns()`/`buildCjcInternalCodes()` 与 `cjc_bridge.json` 同步追加，不改任何调用方。

## 3. 调用方式

```cangjie
import compiler_diagnostic.diagnostics.*

let raw = "error: mismatched types ==> main.cj:3:10:"
let code = resolveCjc(raw)   // => Some(ErrorCode.TypeMismatch)

// 无法识别时回退到原始文本
match (resolveCjc(unknownText)) {
    case Some(c) => /* 用 c.code() / c.category() 结构化输出 */
    case None => /* 保留原始 cjc 文本 */
}
```

下游 `fromCode(code, span)`、`diagnostics-map.json`、VS Code 插件均可直接消费 `resolveCjc` 的结果，实现"真实编译诊断 → 统一 E 码 → 多端渲染"的闭环。

## 4. 验证状态（重要）

- ✅ 桥接层**引用的所有 ErrorCode 变体均已核对存在于枚举**（脚本 `grep` 验证）。
- ⚠️ 本沙箱 `cjpm build` 全量链接期内存受限（exit 127，已知环境限制），`cjc_bridge.cj` 的**编译**尚未在沙箱实跑；建议在真实 Cangjie 1.1.3 环境执行 `cjpm build` + `./tools/run_tests.sh all` 复核。
- 关键词表为保守最小集，覆盖最常见的 cjc 诊断；可按 2.2 扩展更多子串。
