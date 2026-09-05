# -*- coding: utf-8 -*-
"""从扩展后的 Diagnostics.cj 抽取全部 1527 个错误码的元数据，
生成 vscode-extension/diagnostics-map.json（开发工具映射表）。
该表是「VS Code 通用插件模式」的唯一数据源：插件据此把编译器诊断
（含 code 字段）映射为编辑器 Diagnostic（severity / 快速修复 / 文档链接）。"""
import io
import json
import os
import re

ROOT = r"D:\CodeWorkspace\compiler-diagnostic"
DIAG = os.path.join(ROOT, "src", "diagnostics", "Diagnostics.cj")
OUT = os.path.join(ROOT, "vscode-extension", "diagnostics-map.json")

text = io.open(DIAG, "r", encoding="utf-8").read()
lines = text.split("\n")


def region(start_pat, end_pat):
    s = None
    for i, l in enumerate(lines):
        if s is None and re.search(start_pat, l):
            s = i
        elif s is not None and re.search(end_pat, l):
            return s, i
    return s, len(lines)


# ---- ErrorCategory 元数据 ----
cat_start, _ = region(r"public enum ErrorCategory <:", r"    public func codePrefix")
cat_enum = []
for l in lines[cat_start:cat_start + 60]:
    m = re.match(r"^\s*\| (\w+)\s*$", l)
    if m:
        cat_enum.append(m.group(1))
    if "public func codePrefix" in l:
        break

def collect_cat_arms(method_pat):
    s, _ = region(method_pat, r"        \}")
    out = {}
    pat = re.compile(r'case ErrorCategory\.(\w+) => "([^"]*)"')
    started = False
    for i in range(s, min(s + 80, len(lines))):
        if "match (this)" in lines[i]:
            started = True
        if started and "case ErrorCategory." in lines[i]:
            mm = pat.search(lines[i])
            if mm:
                out[mm.group(1)] = mm.group(2)
        if started and lines[i].strip() == "}":
            break
    return out

cat_prefix = collect_cat_arms(r"public func codePrefix\(\): String \{")
cat_stage = collect_cat_arms(r"public func stage\(\): String \{")
cat_disp = collect_cat_arms(r"public func displayName\(\): String \{")

# ---- ErrorCode -> code 映射（用于拿 variant 名）----
code_start, _ = region(r"public func code\(\): String \{", r"        \}")
var_to_code = {}
pat = re.compile(r'case ErrorCode\.(\w+) => "(\w+)"')
started = False
for i in range(code_start, min(code_start + 9000, len(lines))):
    if "match (this)" in lines[i]:
        started = True
    if started and "case ErrorCode." in lines[i]:
        mm = pat.search(lines[i])
        if mm:
            var_to_code[mm.group(1)] = mm.group(2)
    if started and lines[i].strip() == "}":
        break

# ---- META 条目（paren-aware 解析，兼容 5 参 / 7 参含 notes 的 ErrorMeta）----
def balanced(text, start):
    """text[start]=='(' 时返回匹配 ')' 的索引，否则返回 start。"""
    if start >= len(text) or text[start] != '(':
        return start
    depth = 0
    i = start
    n = len(text)
    while i < n:
        c = text[i]
        if c == '(':
            depth += 1
        elif c == ')':
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return i

def find_meta_blocks(text):
    blocks = []
    i = 0
    n = len(text)
    while i < n:
        j = text.find('m["', i)
        if j == -1:
            break
        km = re.match(r'm\["(\w+)"\] = ErrorMeta\(', text[j:j + 80])
        if not km:
            i = j + 2
            continue
        code = km.group(1)
        k = text.find('ErrorMeta(', j) + len('ErrorMeta')
        end = balanced(text, k)
        blocks.append((code, text[k:end]))
        i = end + 1
    return blocks

blocks = find_meta_blocks(text)
total_meta = len(blocks)
codes = []
note_pat = re.compile(r'DiagnosticNote\(message:\s*"((?:[^"\\]|\\.)*)",\s*spanRole:\s*"((?:[^"\\]|\\.)*)"\)')
for code, inner in blocks:
    cat = re.search(r'category:\s*ErrorCategory\.(\w+)', inner)
    sev = re.search(r'severity:\s*Severity\.(\w+)', inner)
    tpl = re.search(r'template:\s*"((?:[^"\\]|\\.)*)"', inner)
    cat = cat.group(1) if cat else ""
    sev = sev.group(1) if sev else "Error"
    tpl = tpl.group(1).replace('\\"', '"') if tpl else ""
    # fix：None 或 Some(FixSuggestion(...))（paren-aware）
    fix = None
    fixm = re.search(r'fix:\s*', inner)
    if fixm:
        fstart = fixm.end()
        if inner[fstart:fstart + 4] == 'None':
            fix = None
        else:
            p = inner.index('(', fstart)
            fend = balanced(inner, p)
            fix = inner[p:fend + 1].replace('\\"', '"')
    # notes：ArrayList<DiagnosticNote>([...])
    notes = []
    nm = re.search(r'notes:\s*ArrayList<DiagnosticNote>\(', inner)
    if nm:
        ns = nm.end() - 1
        nend = balanced(inner, ns)
        notes_raw = inner[ns + 1:nend]
        for mm in note_pat.finditer(notes_raw):
            notes.append({"message": mm.group(1).replace('\\"', '"'),
                          "spanRole": mm.group(2)})
    psr = re.search(r'primarySpanRole:\s*"([^"]*)"', inner)
    primary_span_role = psr.group(1) if psr else "primary"
    # 反查 variant 名
    var = None
    for v, c in var_to_code.items():
        if c == code:
            var = v
            break
    codes.append({
        "code": code,
        "variant": var,
        "category": cat,
        "severity": sev,
        "lspSeverity": "Error" if sev in ("Fatal", "Error") else "Warning",
        "editorSeverity": 1 if sev in ("Fatal", "Error") else 2,
        "actionable": sev in ("Fatal", "Error"),
        "template": tpl,
        "fix": fix,
        "primarySpanRole": primary_span_role,
        "notes": notes,
    })

# 按 code 排序
codes.sort(key=lambda x: x["code"])

categories = {}
for c in cat_enum:
    categories[c] = {
        "display": cat_disp.get(c, c),
        "stage": cat_stage.get(c, ""),
        "prefix": cat_prefix.get(c, ""),
    }

mapping = {
    "schemaVersion": "1.0.0",
    "generatedBy": "tools/gen_vscode_map.py",
    "source": "src/diagnostics/Diagnostics.cj",
    "total": len(codes),
    "categories": categories,
    "codes": codes,
}

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with io.open(OUT, "w", encoding="utf-8") as f:
    json.dump(mapping, f, ensure_ascii=False, indent=2)

print(f"[map] META 条目识别: {total_meta}（正则精确匹配 {len(codes)}）")
print(f"[map] 类别数: {len(categories)}")
print(f"[map] 已写入 {OUT}（total={len(codes)}）")
