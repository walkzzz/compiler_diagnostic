#!/usr/bin/env python3
# =============================================================================
# coverage_gate.py — 覆盖率门槛（best-effort）
#
# 仓颉覆盖率流程：cjpm test --coverage 生成 .gcno/.gcda 覆盖率数据，再由 SDK 自带的
# cjcov 汇总为 HTML/XML/JSON 报告。此脚本解析报告中的「总行覆盖率」，并与门槛比较。
#
# 设计取舍：在受限/内存紧张的环境下 `cjpm test --coverage` 可能偶发失败，覆盖率数据
# 因而缺失。为避免误杀 CI，默认【非严格】模式：找不到报告或无法解析时仅告警并退出 0；
# 加 --strict 才会在缺失/不足时失败。
#
# 用法：
#   python3 tools/coverage_gate.py                       # 自动查找报告，门槛 70%
#   python3 tools/coverage_gate.py --threshold 80        # 门槛 80%
#   python3 tools/coverage_gate.py --report cov.xml --strict
# =============================================================================
import argparse
import glob
import json
import os
import re
import sys
import xml.etree.ElementTree as ET


def find_coverage_report(root: str):
    patterns = [
        "coverage.xml", "coverage.json", "coverage_report.xml", "coverage_report.json",
        os.path.join("**", "coverage.xml"),
        os.path.join("**", "coverage.json"),
        os.path.join("**", "coverage_report", "**", "*.html"),
    ]
    for pat in patterns:
        hits = glob.glob(os.path.join(root, pat), recursive=True)
        if hits:
            return hits[0]
    return None


def parse_coverage(path: str):
    # gcov 风格 XML：根 <coverage line-rate="0.87" />
    if path.endswith(".xml"):
        try:
            tree = ET.parse(path)
            root = tree.getroot()
            lr = root.get("line-rate")
            if lr is not None:
                return float(lr) * 100.0
        except Exception:
            pass
    # JSON：尝试常见字段
    if path.endswith(".json"):
        try:
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                data = json.load(f)
            for k in ("lineRate", "line-rate", "totalLineCoverage", "coverage", "line_coverage"):
                v = data.get(k) if isinstance(data, dict) else None
                if isinstance(v, (int, float)):
                    return float(v) * 100.0 if float(v) <= 1 else float(v)
        except Exception:
            pass
    # HTML 兜底：搜索 "Total ... NN.N%"
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            text = f.read()
        m = re.search(r"Total[^\d]{0,40}(\d+(?:\.\d+)?)\s*%", text)
        if m:
            return float(m.group(1))
        m = re.search(r"line-rate[^>]{0,40}(\d+(?:\.\d+)?)\s*%", text)
        if m:
            return float(m.group(1))
    except Exception:
        pass
    return None


def main():
    ap = argparse.ArgumentParser(description="Cangjie coverage gate (best-effort).")
    ap.add_argument("--threshold", type=float, default=70.0, help="minimum line coverage %% (default 70)")
    ap.add_argument("--report", default=None, help="explicit coverage report path")
    ap.add_argument("--root", default=".", help="root dir to search for reports")
    ap.add_argument("--strict", action="store_true", help="fail when data missing or below threshold")
    args = ap.parse_args()

    report = args.report or find_coverage_report(args.root)
    if not report:
        msg = "No coverage report found."
        if args.strict:
            print("ERROR: " + msg)
            sys.exit(1)
        print("WARN: " + msg + " Skipping coverage gate (non-strict).")
        sys.exit(0)

    cov = parse_coverage(report)
    if cov is None:
        if args.strict:
            print("ERROR: could not parse coverage from " + report)
            sys.exit(1)
        print("WARN: could not parse coverage from " + report + "; skipping gate (non-strict).")
        sys.exit(0)

    print("Line coverage: {:.2f}% (threshold {:.2f}%) from {}".format(cov, args.threshold, report))
    if cov < args.threshold:
        print("FAIL: coverage {:.2f}% below threshold {:.2f}%".format(cov, args.threshold))
        sys.exit(1)
    print("PASS: coverage meets threshold.")
    sys.exit(0)


if __name__ == "__main__":
    main()
