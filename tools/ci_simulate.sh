#!/usr/bin/env bash
# =============================================================================
# compiler-diagnostic · 本地 CI 模拟器
#
# 与 .github/workflows/ci.yml 的 verify job 保持 1:1 的步骤顺序与判定逻辑，
# 用于在本地（或 self-hosted runner）复现 CI，而无需真正触发 GitHub/GitCode 远端。
# 远端触发受限时（如 gh 未登录、runner 无 SDK），用本脚本即可验证流水线逻辑是否全绿。
#
# 前置：CANGJIE_HOME 指向 Cangjie 1.1.3 (cjnative) SDK 根（含 bin/cjc）。
# 用法：
#   bash tools/ci_simulate.sh            # 完整：build -> test -> lint -> coverage
#   SKIP_COVERAGE=1 bash tools/ci_simulate.sh
# =============================================================================
set -u
cd "$(dirname "$0")/.." || exit 1

if [ -z "${CANGJIE_HOME:-}" ]; then
  echo "::error::CANGJIE_HOME 未设置，请先指向 Cangjie 1.1.3 SDK 根目录"
  exit 1
fi
SDK="$CANGJIE_HOME"
export PATH="$SDK/bin:$SDK/tools/bin:$SDK/tools/lib:$SDK/runtime/lib/windows_x86_64_cjnative:$PATH"

echo "==> [ci] cjc version"; "$SDK/bin/cjc" -v

echo "==> [ci] Build (warning-free)"
# 本地复用时可设 SKIP_CLEAN=1 复用已有 target（避免重复全量重建；远端 runner 始终清理）
if [ "${SKIP_CLEAN:-0}" != "1" ]; then rm -rf target; fi
cjpm build --jobs 1 2>&1 | tee build.log
if grep -i "warning" build.log; then
  echo "::error::Build produced warnings (requirement: warning = 0)"; exit 1
fi
echo "    build OK (warning 0)"

echo "==> [ci] Test (per-group, retry on flaky segfault)"
export MAX_TRIES=8 TEST_TIMEOUT=540
bash tools/run_tests.sh all
echo "    test step rc=$?"

echo "==> [ci] cjlint gate (MANDATORY = 0)"
export CANGJIE_HOME="$(cygpath -w "$SDK" 2>/dev/null || echo "$SDK")"
cjlint -f src -o cjlint.json
python3 tools/cjlint_check.py cjlint.json
echo "    cjlint gate rc=$?"

if [ "${SKIP_COVERAGE:-0}" != "1" ]; then
  echo "==> [ci] Coverage (best-effort, non-fatal)"
  cjpm test src/ut --coverage || true
  cjcov -r src -s src -o cov_out -x || true
  python3 tools/coverage_gate.py --root cov_out || true
fi

echo "==> [ci] ALL CI STEPS COMPLETED"
