#!/usr/bin/env python3
"""
cjlint_check.py - cjlint 门禁检查（CI 用）

cjlint 输出为多段拼接的 JSON（无外层数组），本脚本流式解析，统计 defectLevel，
若存在任意 MANDATORY 级别问题则非零退出（阻断 CI）。SUGGESTIONS 级别不阻断。

用法:
    python3 tools/cjlint_check.py <report.json> [--max-suggestions N]
"""
import json
import sys


def parse_stream(path):
    """流式解析拼接 JSON，返回 issue 列表。"""
    raw = open(path, encoding="utf-8").read()
    dec = json.JSONDecoder()
    i, n = 0, len(raw)
    issues = []
    while i < n:
        while i < n and raw[i] in " \t\r\n":
            i += 1
        if i >= n:
            break
        obj, end = dec.raw_decode(raw, i)
        i = end
        if isinstance(obj, list):
            issues.extend(obj)
        elif isinstance(obj, dict):
            for k in obj:
                if isinstance(obj[k], list):
                    issues.extend(obj[k])
                    break
            else:
                issues.append(obj)
    return issues


def main():
    if len(sys.argv) < 2:
        print("usage: cjlint_check.py <report.json> [--max-suggestions N]")
        return 2
    report = sys.argv[1]
    max_suggest = None
    if "--max-suggestions" in sys.argv:
        idx = sys.argv.index("--max-suggestions")
        if idx + 1 < len(sys.argv):
            max_suggest = int(sys.argv[idx + 1])

    issues = parse_stream(report)
    mandatory = [it for it in issues
                 if isinstance(it, dict) and it.get("defectLevel", "").upper() == "MANDATORY"]
    suggestions = [it for it in issues
                  if isinstance(it, dict) and it.get("defectLevel", "").upper() != "MANDATORY"]

    print(f"cjlint 解析: 总计 {len(issues)} 项")
    print(f"  MANDATORY : {len(mandatory)}")
    print(f"  SUGGESTIONS: {len(suggestions)}")

    if mandatory:
        print("FAIL: 存在 MANDATORY 级问题，门禁不通过:")
        for it in mandatory[:20]:
            line = it.get("line") or it.get("startLine") or "?"
            f = it.get("file") or it.get("path") or ""
            msg = it.get("message") or it.get("description") or ""
            print(f"  - {f}:{line} :: {str(msg)[:120]}")
        return 1

    if max_suggest is not None and len(suggestions) > max_suggest:
        print(f"FAIL: SUGGESTIONS 数量 {len(suggestions)} 超过上限 {max_suggest}")
        return 1

    print("OK: cjlint 门禁通过（MANDATORY=0）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
