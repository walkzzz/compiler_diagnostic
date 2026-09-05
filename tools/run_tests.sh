#!/usr/bin/env bash
# =============================================================================
# compiler-diagnostic · 按子包逐个运行测试
#
# 测试包已独立为顶层 test/ 目录，并按层次拆分为三个子包：
#   test/ut   单元测试（ut）      —— cjpm test ut
#   test/hlt  高层测试（hlt）     —— cjpm test hlt
#   test/llt  端到端测试（llt）   —— cjpm test llt
#
# 用法：
#   ./tools/run_tests.sh ut       # 仅单元测试
#   ./tools/run_tests.sh hlt      # 仅高层测试
#   ./tools/run_tests.sh llt      # 仅端到端测试
#   ./tools/run_tests.sh all      # 依次 ut -> hlt -> llt（默认）
#
# 依赖：cjpm (Cangjie 1.1.3)。需 CANGJIE_HOME 指向 vendored SDK。
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

PKG="${1:-all}"

run_one() {
  echo ""
  echo "===== cjpm test $1 ====="
  cjpm test "$1"
}

case "$PKG" in
  ut | hlt | llt)
    run_one "$PKG"
    ;;
  all)
    run_one ut && run_one hlt && run_one llt
    ;;
  *)
    echo "未知子包: $PKG （可选：ut | hlt | llt | all）"
    exit 1
    ;;
esac
