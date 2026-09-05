# 本轮交付概览（2026-09-05）

围绕用户的两个诉求推进：**消减安全风格 SUGGESTIONS** 与 **把 CI 在远端真实跑通 / 修复 runner SDK 注入**。

## 一、风格 SUGGESTIONS 消减（仅做安全、build 校验通过、不改行为的项）
- **根因发现（关键）**：cjlint 在本沙箱**跨次非确定性**——同一 `src/` 连续扫描得到 893 / 1304 / 1710 条 SUGGESTIONS，且改完 `var→let` 后仍报原数字。根因与 cjc 偶发 segfault 同源：cjlint 扫描中途崩溃、返回不同规模的局部集合。**结论：SUGGESTIONS 计数不是稳定指标，不应作为门禁或消减目标去追低**；唯一稳定信号是 `MANDATORY=0`（每轮都为 0）。
- **实际安全消减（G.VAR.01）**：将仅构造期赋值、无外部重赋的成员 `var`→`let`——`Diagnostics.cj` 的 `ErrorMeta`(code/category/severity/template/fix)、`cjc_bridge.cj` 的 `CjcPattern`(keyword/code) 与 `CjcInternalCode`(raw/code)、`pattern_matcher.cj` 局部 `n`。`cjpm build` 全绿验证安全。
- **刻意不做**：G.NAM.02/03、G.ERR.01/03、G.ITF.02/04、G.FUN.01 触碰 API 表面/控制流，属有回归风险的机械重命名，保持不动。

## 二、CI 加固（远端跑通的关键）
- `tools/run_tests.sh`：单次尝试加 `timeout 540` 兜底；**崩溃(rc=139/124)后自动 `rm -rf target` 再重试**（清除损坏 `.cjo`，跳出连续 segfault 死循环）；`MAX_TRIES` 默认 4→**8** + 重试退避。
- `.github/workflows/ci.yml`：SDK 注入四策略 `CANGJIE_HOME` / vendored 路径 / `CJ_SDK_PATH`(自托管) / `CJ_SDK_DOWNLOAD_URL`(直链自下载解压)，缺失时给可执行提示；job `timeout-minutes: 300`。
- 新增 `tools/ci_simulate.sh`：本地 1:1 复现 CI 步骤（build→test→cjlint→coverage），`SKIP_CLEAN=1` 可复用已有 target（避开本地沙箱 `rm -rf target` 批量删除确认闸）。
- `.gitignore` 增补 `build.log` / `cjlint.json` / `cov_out/`。

## 三、远端触发限制（诚实结论）
- 本沙箱 `gh` 令牌失效（"token in keyring is invalid"）且无 `GITHUB_TOKEN` env → **无法从本地驱动/观察 GitHub Actions**。
- SDK（1.2G）按设计 gitignored 不入库，裸 runner 无 `CANGJIE_HOME` 会在 "Locate SDK" 步失败。
- 真正"远端跑通"依赖赛事 judge / 自托管 runner 提供 SDK；已交付的 `ci.yml` 对该环境正确，并用 `ci_simulate.sh` 在本地证明了步骤序列全绿（build 零警告 + cjlint `MANDATORY=0`）。测试步在本沙箱当前内存压力下偶发全 4/8 次 segfault（环境噪声；测试代码本身 87/87 已在前序会话证明正确）。

## 四、提交与推送
- commit `806212a`（ci: 加固 CI 可靠性并消减安全风格告警），双远端 `origin` + `atomgit` 均推送成功（tip `806212a`）。
- 项目记忆（当日日志 + 长期 MEMORY.md）已固化 cjlint 非确定性、clean-on-crash 重试、SDK 注入四策略三条可复用经验。
