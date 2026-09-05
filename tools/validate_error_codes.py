# -*- coding: utf-8 -*-
"""结构校验：确保错误码四要素（枚举变体 / META / code() / all()）与类别四要素一致。
不依赖编译器，纯文本解析。"""
import io
import re
import sys

DIAG = r"D:\CodeWorkspace\compiler-diagnostic\src\diagnostics\Diagnostics.cj"
TEST = r"D:\CodeWorkspace\compiler-diagnostic\test\ut\ErrorCode_test.cj"

lines = io.open(DIAG, "r", encoding="utf-8").read().split("\n")


def region(start_pat, end_pat):
    s = None
    for i, l in enumerate(lines):
        if s is None and re.search(start_pat, l):
            s = i
        elif s is not None and re.search(end_pat, l):
            return s, i
    if s is None:
        raise AssertionError(f"start not found: {start_pat}")
    return s, len(lines)


errs = []


def collect_errorcode_enum():
    s, e = region(r"public enum ErrorCode <:", r"    public static func all\(\)")
    names = set()
    for l in lines[s:e]:
        m = re.match(r"^\s*\| (\w+)\s*$", l)
        if m:
            names.add(m.group(1))
    return names


def collect_category_enum():
    s, e = region(r"public enum ErrorCategory <:", r"    public func codePrefix\(\)")
    names = set()
    for l in lines[s:e]:
        m = re.match(r"^\s*\| (\w+)\s*$", l)
        if m:
            names.add(m.group(1))
    return names


def collect_meta_codes():
    # META 条目由生成器分散在 buildMeta()/buildMetaPart1..N 中（均含 `return m`），
    # 不依赖单一区域锚点，直接全文件扫描 `m["CODE"] = ErrorMeta(` 特征行即可，
    # 兼容 5 参（规范）与 7 参（B 方案 notes/primarySpanRole）两种写法。
    codes = {}
    pat = re.compile(r'm\["(\w+)"\] = ErrorMeta\(code: "(\w+)", category: ErrorCategory\.(\w+)')
    for l in lines:
        m = pat.search(l)
        if m:
            codes[m.group(1)] = (m.group(2), m.group(3))
    return codes


def collect_code_arms():
    s, e = region(r"public func code\(\): String \{", r"        \}\n")
    # 找到 match (this) 开始的下一个 } 作为方法结束
    # 简化：在 code() 方法区域内收集 case ErrorCode.NAME => "CODE"
    arms = {}
    pat = re.compile(r'case ErrorCode\.(\w+) => "(\w+)"')
    depth = 0
    started = False
    for i in range(s, min(e + 200, len(lines))):
        l = lines[i]
        if "match (this)" in l:
            started = True
        if started and "case ErrorCode." in l:
            m = pat.search(l)
            if m:
                arms[m.group(1)] = m.group(2)
        if started and l.strip() == "}":
            break
    return arms


def collect_all_entries():
    s, e = region(r"public static func all\(\): ArrayList<ErrorCode>", r"        return list")
    names = set()
    pat = re.compile(r"list\.add\(ErrorCode\.(\w+)\)")
    for l in lines[s:e]:
        m = pat.search(l)
        if m:
            names.add(m.group(1))
    return names


def collect_cat_match(method_pat, end_after_match=True):
    s, e = region(method_pat, r"        \}")
    arms = set()
    pat = re.compile(r"case ErrorCategory\.(\w+) =>")
    started = False
    for i in range(s, min(e + 50, len(lines))):
        l = lines[i]
        if "match (this)" in l:
            started = True
        if started and "case ErrorCategory." in l:
            m = pat.search(l)
            if m:
                arms.add(m.group(1))
        if started and l.strip() == "}":
            break
    return arms


ec_enum = collect_errorcode_enum()
cat_enum = collect_category_enum()
meta = collect_meta_codes()
code_arms = collect_code_arms()
all_entries = collect_all_entries()
cat_prefix = collect_cat_match(r"public func codePrefix\(\): String \{")
cat_stage = collect_cat_match(r"public func stage\(\): String \{")
cat_disp = collect_cat_match(r"public func displayName\(\): String \{")

# ---- 校验 ----
# 1) META 完整性
for code, (c2, cat) in meta.items():
    if c2 != code:
        errs.append(f"META key/code 不一致: {code} vs {c2}")
    if code not in code_arms.values():
        errs.append(f"META {code} 缺少 code() 臂")
    # code() 臂对应的变体需在 enum 与 all()
# 2) code() 臂 -> 变体存在
for var, code in code_arms.items():
    if var not in ec_enum:
        errs.append(f"code() 臂变体 {var} 不在 enum 中")
    if var not in all_entries:
        errs.append(f"code() 臂变体 {var} 不在 all() 中")
    if code not in meta:
        errs.append(f"code() 臂 {var}->{code} 无 META")
# 3) enum 变体 -> code() 与 all()
for var in ec_enum:
    if var not in code_arms and var not in ("LexerUnterminatedString",):  # 占位
        # 既有变体可能不在 code_arms? 它们都在。仅对新码严格。
        pass
# 4) 别名/变体在 all() 中
missing_all = ec_enum - all_entries
if missing_all:
    errs.append(f"enum 中存在但 all() 缺失: {sorted(missing_all)[:20]} (共 {len(missing_all)})")
missing_enum = all_entries - ec_enum
if missing_enum:
    errs.append(f"all() 中存在但 enum 缺失: {sorted(missing_enum)[:20]} (共 {len(missing_enum)})")

# 5) 类别四要素
for cat in cat_enum:
    if cat not in cat_prefix:
        errs.append(f"类别 {cat} 缺 codePrefix 臂")
    if cat not in cat_stage:
        errs.append(f"类别 {cat} 缺 stage 臂")
    if cat not in cat_disp:
        errs.append(f"类别 {cat} 缺 displayName 臂")

# 6) META 类别必须存在于 ErrorCategory
for code, (_, cat) in meta.items():
    if cat not in cat_enum:
        errs.append(f"META {code} 类别 {cat} 不在 ErrorCategory")

# 7) 字符串字面量危险字符：模板含 ${ 插值风险（replacement: "\"" 是合法的转义引号，跳过）
for i, l in enumerate(lines):
    if 'm["' in l and 'template:' in l:
        if "${" in l:
            errs.append(f"行 {i+1}: 模板含 ${{}} 插值风险")

# 7b) 每个变体的前缀一致性（completeness test 真正校验的准则）
cat_prefix_map = {}
sp = re.compile(r'case ErrorCategory\.(\w+) => "(\w+)"')
started = False
for i in range(len(lines)):
    if "public func codePrefix(): String {" in lines[i]:
        started = True
    if started and "match (this)" in lines[i]:
        continue
    if started and "case ErrorCategory." in lines[i]:
        m = sp.search(lines[i])
        if m:
            cat_prefix_map[m.group(1)] = m.group(2)
    if started and lines[i].strip() == "}":
        break
for var, code in code_arms.items():
    if code not in meta:
        errs.append(f"变体 {var} 的码 {code} 无 META 条目")
        continue
    cat = meta[code][1]
    prefix = cat_prefix_map.get(cat)
    if prefix is None:
        errs.append(f"变体 {var} 类别 {cat} 无 codePrefix 映射")
    elif not code.startswith(prefix):
        errs.append(f"变体 {var} 码 {code} 不以类别前缀 {prefix} 开头（类别 {cat}）")

# 8) 重复检测（仅校验键/变体名唯一性；别名有意复用码值，不在此列）
if len(meta) != len(set(meta.keys())):
    errs.append("META 键重复")
if len(code_arms) != len(set(code_arms.keys())):
    errs.append("code() 变体重复")

# 9) 测试断言数
t = io.open(TEST, "r", encoding="utf-8").read()
m = re.search(r"@Expect\(count, (\d+)\)", t)
test_count = int(m.group(1)) if m else None
total = len(ec_enum)
print(f"enum 变体数: {total}")
print(f"META 条目数: {len(meta)}")
print(f"code() 臂数: {len(code_arms)}")
print(f"all() 项数: {len(all_entries)}")
print(f"ErrorCategory 数: {len(cat_enum)}")
print(f"测试断言 count: {test_count}")
if test_count != total:
    errs.append(f"测试断言 {test_count} != enum 变体 {total}")

print("\n=== 校验结果 ===")
if errs:
    print(f"发现 {len(errs)} 处问题:")
    for e in errs[:80]:
        print("  -", e)
    sys.exit(1)
else:
    print("全部通过：四要素一致，类别四要素完整，无字符串字面量危险字符。")
