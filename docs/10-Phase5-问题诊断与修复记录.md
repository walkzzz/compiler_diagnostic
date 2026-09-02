# Phase 5 - 问题诊断与修复记录

**执行者**：寇成码
**项目**：compiler-diagnostic
**修复来源**：Phase 4 代码审查反馈

---

## 一、问题清单

| 编号 | 级别 | 文件 | 问题描述 |
|------|------|------|----------|
| C001 | Critical | `src/output/JSONOutput.cj` | 3 处 `for (i in 0..size)` 数组越界，应为 `0..<size` |
| M001 | Major | `test/UT/` | 缺少 DiagnosticCollector 单元测试 |
| M002 | Major | `test/UT/` | 缺少 TextOutput 单元测试 |
| M003 | Major | `README.md` | 文件结构描述与实际实现不一致 |

---

## 二、修复方案

### C001 - JSON 输出数组越界

**根因**：仓颉 `for (i in a..b)` 是闭区间 `[a, b]`，访问 `list[b]` 越界。
**修复**：将 3 处 `0..size` 改为 `0..<size`（左闭右开）。

```cangjie
// 修复前
for (i in 0..diagnostics.size) { ... }
for (i in 0..diag.related.size) { ... }
for (i in 0..arr.size) { ... }

// 修复后
for (i in 0..<diagnostics.size) { ... }
for (i in 0..<diag.related.size) { ... }
for (i in 0..<arr.size) { ... }
```

**验证**：`cjpm build` / `cjlint` / `cjpm test` 全部 exit 0。

---

### M001 - DiagnosticCollector 单元测试

**新建文件**：`test/UT/DiagnosticCollector_test.cj`

测试覆盖：
- `testAdd` — 添加单条诊断，验证 count()
- `testAddAll` — 批量添加，验证 count()
- `testGetMessages` — 验证 getMessages() 返回正确内容和类型
- `testCountEmpty` — 空收集器 count() = 0
- `testClear` — 添加后清除，验证 count() = 0
- `testGroupByCode` — 多条同码诊断归组，验证分组数量和每组条目数

---

### M002 - TextOutput 单元测试

**新建文件**：`test/UT/TextOutput_test.cj`

测试覆盖：
- `testEmptyList` — 空列表输出空字符串
- `testSingleDiagnostic` — 单条诊断包含错误码和消息
- `testWithFix` — 含修复建议的诊断输出包含"修复建议"
- `testWithRelated` — 含关联位置的诊断输出包含关联信息
- `testWithCandidates` — 含候选符号的诊断输出包含候选列表
- `testMultipleDiagnostics` — 多条诊断各自独立输出

---

### M003 - README 与实现不一致

**修复内容**：更新 README 中项目结构描述，与实际文件一致：
- 删除不存在的 `Diagnostic.cj`、`ErrorCode.cj`、`SourceLoc.cj`、`RelatedInfo.cj`、`FixSuggestion.cj` 等分散文件条目
- 改为 `Diagnostics.cj`（合并核心数据结构）的说明
- 补充 `DiagnosticBuilder.cj`、`DiagnosticCollector.cj` 的实际文件描述

---

## 三、验证结果

| 命令 | 退出码 | 状态 |
|------|--------|------|
| `cjpm build` | 0 | ✅ PASS |
| `cjlint` | 0, warnings=0 | ✅ PASS |
| `cjpm test` | 0 | ✅ PASS |

### 新增测试文件
- `test/UT/DiagnosticCollector_test.cj` — 6 个测试用例
- `test/UT/TextOutput_test.cj` — 6 个测试用例

### 更新测试文件
- `test/UT/JSONOutput_test.cj` — 原有测试保持不变（C001 修复后测试可覆盖边界）

### 更新文档
- `README.md` — 项目结构与实际对齐

---

## 四、修复后工程规模

| 项 | 修复前 | 修复后 |
|----|--------|--------|
| 源文件 | 12 | 12 |
| UT 文件 | 4 | 6 |
| HLT 文件 | 11 | 11 |
| LLT 文件 | 10 | 10 |
| 总测试文件 | 25 | 27 |

---

## 五、知识缺口

无。所有修复已通过本地构建和测试验证。

---

*生成时间：2025-07-11*
*修复人：寇成码*
