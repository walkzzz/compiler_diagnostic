# Cangjie Diagnostic Adapter（VS Code 通用插件模式）

把 `compiler_diagnostic` 的诊断输出（JSON，含 `code` 字段）映射为编辑器
**Diagnostic（波浪线 / 问题面板）**、**severity** 与**快速修复建议**。

## 通用插件模式（核心思想）

插件**不硬编码任何错误码**。所有「码 → 编辑器行为」的映射都来自
`diagnostics-map.json`，该文件由 `tools/gen_vscode_map.py` 从
`src/diagnostics/Diagnostics.cj` 的 `ErrorMeta` 全量生成（当前约 1500+ 码）。

> 因此：编译器每扩展一批错误码，只需重新运行生成脚本，插件**无需改代码**即可生效。

## 目录结构

```
vscode-extension/
├── package.json                 # 语言贡献 + 命令 + 设置项
├── language-configuration.json  # Cangjie 语言括号/注释规则
├── tsconfig.json
├── diagnostics-map.json         # 由 tools/gen_vscode_map.py 生成（单一数据源）
└── src/extension.ts            # 通用适配器
```

## 使用

```bash
cd vscode-extension
npm install
# 在 VS Code 中按 F5 启动扩展开发宿主（Extension Development Host）
```

然后将 `compiler_diagnostic` 的输出（JSON 数组或 `{ "diagnostics": [...] }`）粘贴到编辑器，
执行命令 **Cangjie: 应用诊断映射** 即可在工作区渲染诊断。

## 设置项（settings.json）

| 设置 | 说明 |
|---|---|
| `cangjie.diagnostics.mapPath` | 映射表路径（默认 `diagnostics-map.json`） |
| `cangjie.diagnostics.severityOverride` | 按错误码前缀覆盖严重级别，如 `{ "E90": "Warning" }` |
| `cangjie.diagnostics.autoApplyOnOutput` | 监听任务输出自动渲染（预留） |

## 映射表字段

```jsonc
{
  "code": "E1101",
  "variant": "BackendLlvmVerifyFailed",
  "category": "Backend",
  "severity": "Error",
  "lspSeverity": "Error",       // 对应 LSP DiagnosticSeverity
  "editorSeverity": 1,          // 1=Error, 2=Warning
  "actionable": true,           // 是否提供快速修复
  "template": "LLVM 模块校验失败：{pass}",
  "fix": "检查生成的中间表示"
}
```
