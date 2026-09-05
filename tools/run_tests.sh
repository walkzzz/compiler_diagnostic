#!/usr/bin/env bash
# =============================================================================
# compiler-diagnostic · 按子包逐个运行测试（带重试）
#
# 仓颉 cjpm 1.1.3 的测试发现规则：测试源码必须以 `_test.cj` 结尾、且与对应生产包
# 同处于 src/ 源码集（详见 cjpm.toml 注释）。三层测试包位于：
#   src/ut    单元测试（ut）   —— cjpm test src/ut
#   src/hlt   高层测试（hlt）  —— cjpm test src/hlt
#   src/llt   端到端测试（llt） —— cjpm test src/llt
#
# cjpm test 在受限环境（内存压力）下可能偶发崩溃（exit 127 / 无输出），故每个子包
# 最多重试 MAX_TRIES 次直到通过。全量 `cjpm test` 一次性跑全部子包更易触发崩溃，
# 因此这里改为逐子包运行，更稳定。
#
# 用法：
#   ./tools/run_tests.sh ut       # 仅单元测试
#   ./tools/run_tests.sh hlt      # 仅高层测试
#   ./tools/run_tests.sh llt      # 仅端到端测试
#   ./tools/run_tests.sh all      # 依次 ut -> hlt -> llt（默认）
#   MAX_TRIES=6 ./tools/run_tests.sh all
#
# 依赖：cjpm (Cangjie 1.1.3, cjnative)。需 CANGJIE_HOME 指向仓库内 vendored SDK。
# 建议在 Git Bash 下运行（PowerShell 非 TTY 下 cjpm test 不回显，见项目记忆）。
# =============================================================================
set -u
cd "$(dirname "$0")/.." || exit 1

# ---- 环境：锁定仓库内 vendored SDK（请勿改用系统 SDK） ----
if [ -z "${CANGJIE_HOME:-}" ]; then
  export CANGJIE_HOME="/d/CodeWorkspace/compiler-diagnostic/cangjie-sdk-1.1.3/cangjie"
fi
case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*)
    export PATH="$CANGJIE_HOME/bin:$CANGJIE_HOME/tools/bin:$CANGJIE_HOME/tools/lib:$CANGJIE_HOME/runtime/lib/windows_x86_64_cjnative:$PATH"
    ;;
esac

MAX_TRIES="${MAX_TRIES:-4}"

run_group() {
  local g="$1"; local n=0; local rc=1
  while [ "$n" -lt "$MAX_TRIES" ]; do
    n=$((n + 1))
    echo ""
    echo "===== cjpm test src/$g (attempt $n/$MAX_TRIES) ====="
    cjpm test "src/$g"
    rc=$?
    if [ "$rc" -eq 0 ]; then
      echo ">> src/$g PASSED"
      return 0
    fi
    echo "!! src/$g attempt $n failed (rc=$rc); retrying..."
  done
  return "$rc"
}

PKG="${1:-all}"
case "$PKG" in
  ut | hlt | llt)
    run_group "$PKG"
    ;;
  all)
    run_group ut && run_group hlt && run_group llt
    ;;
  *)
    echo "未知子包: $PKG （可选：ut | hlt | llt | all）"
    exit 1
    ;;
esac
