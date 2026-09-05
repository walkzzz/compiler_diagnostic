#!/usr/bin/env python3
"""
check_bridge_consistency.py - cjc_bridge 代码表与 JSON 镜像一致性校验

生产化守卫：cjc_bridge.cj 中的映射表（CJC_PATTERNS / CJC_INTERNAL）为权威源，
cjc_bridge.json 是其镜像。两者一旦漂移（有人改了代码却忘了 JSON，或反之），
桥接行为就会与生产预期不符。此脚本在 CI 中强制执行，发现漂移即非零退出。

用法:
    python3 tools/check_bridge_consistency.py
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CJC = os.path.join(ROOT, "src", "diagnostics", "cjc_bridge.cj")
JSON = os.path.join(ROOT, "src", "diagnostics", "cjc_bridge.json")


def load_code_tables():
    text = open(CJC, encoding="utf-8").read()
    keywords = re.findall(r'CjcPattern\(keyword:\s*"([^"]+)"', text)
    internals = re.findall(r'CjcInternalCode\(raw:\s*"([^"]+)"', text)
    return set(keywords), set(internals)


def load_json_tables():
    data = json.load(open(JSON, encoding="utf-8"))
    keywords = {e["keyword"] for e in data.get("keyword_patterns", [])}
    internals = {e["cjc"].lower() for e in data.get("internal_codes", [])}
    return keywords, internals


def main():
    if not (os.path.exists(CJC) and os.path.exists(JSON)):
        print("ERROR: cjc_bridge.cj 或 cjc_bridge.json 缺失")
        return 1
    code_kw, code_in = load_code_tables()
    json_kw, json_in = load_json_tables()

    errors = []
    # JSON 应完全被代码覆盖（JSON 是镜像，不应有代码里没有的条目）
    for k in sorted(json_kw - code_kw):
        errors.append(f"JSON keyword 在代码中缺失: '{k}'")
    for k in sorted(json_in - code_in):
        errors.append(f"JSON internal code 在代码中缺失: '{k}'")
    # 代码里多出的条目（说明有人加了代码但没同步 JSON）
    for k in sorted(code_kw - json_kw):
        errors.append(f"代码 keyword 未在 JSON 镜像: '{k}'")
    for k in sorted(code_in - json_in):
        errors.append(f"代码 internal code 未在 JSON 镜像: '{k}'")

    if errors:
        print("FAIL: cjc_bridge 代码表与 JSON 不一致:")
        for e in errors:
            print("  - " + e)
        return 1
    print(f"OK: cjc_bridge 一致性通过 "
          f"(keywords={len(code_kw)}, internal_codes={len(code_in)})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
