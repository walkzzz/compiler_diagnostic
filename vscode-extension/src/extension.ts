// Cangjie Diagnostic Adapter —— VS Code 通用插件模式
//
// 设计原则（通用插件模式）：
//   插件本身不硬编码任何错误码。所有「码 -> 编辑器行为」的映射都来自
//   diagnostics-map.json（由 tools/gen_vscode_map.py 从 Diagnostics.cj 全量生成）。
//   因此编译器每扩展一批错误码，只需重新生成该 JSON，插件无需改代码。
//
// 数据契约（compiler_diagnostic 输出 / diagnostics-map.json 字段）：
//   诊断消息: { code, severity, message, span:{start:{line,column,file}, end:{...}},
//             fix?:{description,replacement}, related?, rootCause? }
//   映射表项: { code, variant, category, severity, lspSeverity,
//             editorSeverity(1=Error,2=Warning), actionable, template, fix }

import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';

interface DiagnosticMapEntry {
  code: string;
  variant: string | null;
  category: string;
  severity: string;
  lspSeverity: 'Error' | 'Warning';
  editorSeverity: 1 | 2;
  actionable: boolean;
  template: string;
  fix: string | null;
}
interface DiagnosticMap {
  schemaVersion: string;
  total: number;
  categories: Record<string, { display: string; stage: string; prefix: string }>;
  codes: DiagnosticMapEntry[];
}
interface RawDiagnostic {
  code: string;
  severity?: string;
  message?: string;
  span?: { start?: { line?: number; column?: number; file?: string }; end?: { line?: number; column?: number } };
  fix?: { description?: string; replacement?: string } | null;
  rootCause?: string;
}

let diagnosticCollection: vscode.DiagnosticCollection | undefined;
let mapCache: DiagnosticMap | undefined;

function loadMap(): DiagnosticMap | undefined {
  const cfg = vscode.workspace.getConfiguration('cangjie.diagnostics');
  const mapRel = cfg.get<string>('mapPath') || 'diagnostics-map.json';
  let mapPath = mapRel;
  if (vscode.workspace.workspaceFolders && vscode.workspace.workspaceFolders.length > 0) {
    mapPath = path.join(vscode.workspace.workspaceFolders[0].uri.fsPath, mapRel);
  }
  try {
    const raw = fs.readFileSync(mapPath, 'utf8');
    mapCache = JSON.parse(raw) as DiagnosticMap;
  } catch (e) {
    vscode.window.showErrorMessage(`Cangjie 诊断映射表加载失败: ${mapPath} — ${(e as Error).message}`);
    mapCache = undefined;
  }
  return mapCache;
}

function resolveSeverity(entry: DiagnosticMapEntry | undefined, rawSeverity?: string): vscode.DiagnosticSeverity {
  // 优先级：用户 override（按码前缀） > 映射表 editorSeverity > 原始 severity > Error
  const cfg = vscode.workspace.getConfiguration('cangjie.diagnostics');
  const override = cfg.get<Record<string, string>>('severityOverride') || {};
  if (entry && override[entry.code.substring(0, entry.code.length - 2)]) {
    const v = override[entry.code.substring(0, entry.code.length - 2)].toLowerCase();
    if (v === 'warning') return vscode.DiagnosticSeverity.Warning;
    if (v === 'error' || v === 'fatal') return vscode.DiagnosticSeverity.Error;
  }
  if (rawSeverity) {
    const s = rawSeverity.toLowerCase();
    if (s === 'warning') return vscode.DiagnosticSeverity.Warning;
    if (s === 'fatal' || s === 'error') return vscode.DiagnosticSeverity.Error;
  }
  if (entry) {
    return entry.editorSeverity === 2 ? vscode.DiagnosticSeverity.Warning : vscode.DiagnosticSeverity.Error;
  }
  return vscode.DiagnosticSeverity.Error;
}

function toRange(span?: RawDiagnostic['span']): vscode.Range {
  const s = span?.start ?? {};
  const e = span?.end ?? {};
  const sl = Math.max(0, (s.line ?? 1) - 1);
  const sc = Math.max(0, (s.column ?? 1) - 1);
  const el = Math.max(0, (e.line ?? (s.line ?? 1)) - 1);
  const ec = Math.max(0, (e.column ?? (s.column ?? 1)) - 1);
  return new vscode.Range(sl, sc, el, ec);
}

function buildMarkdown(entry: DiagnosticMapEntry | undefined, raw: RawDiagnostic): vscode.MarkdownString {
  const md = new vscode.MarkdownString();
  md.isTrusted = true;
  md.appendMarkdown(`**${raw.code}**`);
  if (entry) md.appendMarkdown(` · ${entry.category} · ${entry.severity}\n\n`);
  md.appendMarkdown(raw.message || entry?.template || '（无描述）\n');
  if (raw.rootCause) md.appendMarkdown(`\n\n**根因**：${raw.rootCause}`);
  if (entry?.fix) md.appendMarkdown(`\n\n**建议修复**：${entry.fix}`);
  if (entry?.variant) md.appendMarkdown(`\n\n\`${entry.variant}\``);
  return md;
}

function applyDiagnostics(rawList: RawDiagnostic[]): void {
  if (!diagnosticCollection) return;
  if (!mapCache) loadMap();
  const mapByCode = new Map<string, DiagnosticMapEntry>();
  mapCache?.codes.forEach((c) => mapByCode.set(c.code, c));

  const byFile = new Map<string, vscode.Diagnostic[]>();
  for (const raw of rawList) {
    const entry = mapByCode.get(raw.code);
    const diag = new vscode.Diagnostic(
      toRange(raw.span),
      raw.message || entry?.template || '（未知道诊断）',
      resolveSeverity(entry, raw.severity),
    );
    diag.code = raw.code;
    diag.source = 'compiler_diagnostic';
    diag.relatedInformation = raw.rootCause ? [new vscode.DiagnosticRelatedInformation(diag.range, raw.rootCause)] : undefined;
    const file = raw.span?.start?.file || vscode.window.activeTextEditor?.document.fileName;
    if (!file) continue;
    if (!byFile.has(file)) byFile.set(file, []);
    byFile.get(file)!.push(diag);
  }
  diagnosticCollection.clear();
  for (const [file, diags] of byFile) {
    const uri = vscode.Uri.file(file);
    diagnosticCollection.set(uri, diags);
  }
}

// 命令：从选中的 JSON / 任务输出应用诊断
async function applyFromSelectionOrFile(): Promise<void> {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    vscode.window.showWarningMessage('请先打开包含 compiler_diagnostic JSON 输出的文件');
    return;
  }
  const text = editor.document.getText();
  try {
    const parsed = JSON.parse(text);
    const list: RawDiagnostic[] = Array.isArray(parsed) ? parsed : (parsed.diagnostics ?? [parsed]);
    applyDiagnostics(list);
    vscode.window.showInformationMessage(`已应用 ${list.length} 条诊断映射`);
  } catch (e) {
    vscode.window.showErrorMessage(`解析 compiler_diagnostic 输出失败：${(e as Error).message}`);
  }
}

export function activate(context: vscode.ExtensionContext): void {
  diagnosticCollection = vscode.languages.createDiagnosticCollection('cangjie');
  loadMap();
  context.subscriptions.push(
    vscode.commands.registerCommand('cangjie.applyDiagnosticMap', applyFromSelectionOrFile),
    vscode.commands.registerCommand('cangjie.openDiagnosticDoc', () => {
      const panel = vscode.window.createWebviewPanel('cangjieDiagDoc', 'Cangjie 错误码文档', vscode.ViewColumn.Beside);
      const codes = mapCache?.codes ?? [];
      panel.webview.html = `<h1>compiler_diagnostic 错误码（${codes.length}）</h1><ul>${codes
        .slice(0, 500)
        .map((c) => `<li><b>${c.code}</b> ${c.category}: ${c.template}</li>`)
        .join('')}</ul>`;
    }),
  );
}

export function deactivate(): void {
  diagnosticCollection?.clear();
  diagnosticCollection?.dispose();
}
