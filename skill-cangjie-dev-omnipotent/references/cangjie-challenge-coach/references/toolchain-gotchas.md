# 仓颉工具链实战陷阱（cjpm / cjc / cjlint / cjfmt / 中心仓发布）

> 来源：chrono-tz → 仓颉 1.1.3 真实移植项目的踩坑复盘（2026-09）。
> 核心原则：**正式门禁 = `cjpm build` 0 error + `cjpm test` 全绿**；warning 允许。cjlint 非门禁，"lint 全零"与"保 build 门禁"互斥时，保 build。

---

## 1. `cjpm build` 拒绝子包 import（必记）

- `import std.core.option` / `.result` / `.exception` / `.ordering` 等子包 import，会被 `cjpm build` 报
  `'option' is not accessible in package 'std.core'`（**编译失败，非 warning**）。
- **只有 `import std.core.*` 通配** 同时被 `cjpm build` 与 flat `cjc -o` 接受。
- 推论：使用 `Result` / `Option` / `Exception` / `Ordering` 时直接通配 import，不要拆子包 import。
- 更深的推论：**cjlint 全零不可达**——通配 import 必触发 G.PKG.01（见 §2）。

## 2. cjlint 非门禁，`cjpm build` / `cjpm test` 才是

- 赛事正式验收门禁 = `cjpm build` 0 error + `cjpm test` 全绿；warning 允许，cjlint 不在正式门禁内。
- cjlint 默认非 MANDATORY 级别，即便有 G.PKG.01 SUGGESTION 也 exit 0（非阻塞）。
- **G.PKG.01（通配 import）因 §1 而不可避免**，属"按设计保留"的 2 条非阻塞 SUGGESTION；审查/治理**不应**以此为阻断项。

## 3. G.EXP.03 在 `cjpm bundle` 是 MANDATORY，会直接阻断发布

- 规则：`&&` / `||` 的**右操作数**若含函数调用（被视为副作用），cjlint 记 `G.EXP.03`。
- 仓库级 `cjlint`（非 MANDATORY）只当 warning；但 **`cjpm bundle` / `cjpm publish` 以 MANDATORY 级执行**，
  一旦命中即 `Error: code specifications with level 'MANDATORY' are violated` → bundle/publish 双双失败。
- 修复：把右操作数的函数调用**提升为局部变量**，再在 `&&`/`||` 中只引用该变量。语义不变。
- 典型触发：`if (!(a(x) && b(y, f(z))))` 中 `f(z)` 在 `&&` 右操作数 → 改为 `let r = f(z); if (!(a(x) && b(y, r)))`。

## 4. G.FUN.01 是「函数行长」规则，不是参数个数

- 实测输出：`G.FUN.01: The function 'X' is recommended to have no more than 50 lines of code.`
- 常见误记：以为参数 >5 触发。实际参数多可用元组压缩（如把 `minV/maxV` 合并为 `range: (Int64, Int64)`），
  但 G.FUN.01 **只查函数行长**。
- 修复：把长函数拆成"薄包装 + 主体"（各自 ≤50 行）。

## 5. `cjpm test` 包装进程退出码不可信

- `cjpm test` 包装器有时即便 testrunner 报全绿，自身仍 EXIT=1（sandbox/teardown 怪象）。
- **权威判据 = 直接运行测试二进制**：`target/release/unittest_bin/<pkg>.exe`（PowerShell 原生）。
- 运行需正确 PATH（4 处）：
  - `$CANGJIE_HOME/runtime/lib/windows_x86_64_cjnative`
  - `$CANGJIE_HOME/lib/windows_x86_64_cjnative`（是 lib 下子目录，**非** `$CANGJIE_HOME/lib`）
  - `$CANGJIE_HOME/tools/lib`
  - 项目 `target/release/<pkg>/`（`lib<pkg>.dll` 所在，缺则 0xC0000135 DLL-not-found）
- Git Bash 直接跑 exe 会 EXIT 127，改用 PowerShell 原生。

## 6. `cjc` 同进程多次调用会累积崩溃

- 资源受限环境（CI/sandbox）下，单进程内连续调用 `cjc` 约 4 次后 native 进程崩溃
  （0xC0000005 / 0xC0000135 类），导致批处理循环**静默中止、无 [FAIL] 输出**。
- 此外 `& $cjc ... 2>&1 | Out-File`（**管道**）在 native 子进程异常退出时会抛未捕获异常，同样中止脚本。
- 对策：
  1. 用 `*>` 重定向（非管道）；
  2. 单例验证用独立进程（每例隔离，如 `verify_one.ps1`），不要把 6+ 次 cjc 调用塞进一个进程；
  3. 示例/批量编译若中途死在第 N 个，多半是环境噪声而非代码错误——逐例隔离重跑验证。

## 7. `cjlint -o <file>` 会向已存在文件「追加」

- 重跑前先 `rm -f cjlint_report.json`，否则 JSON 数组翻倍、条数虚高导致误判。

## 8. 工具链锁定陷阱（CANGJIE_HOME）

- 全局 `CANGJIE_HOME` 可能默认指向旧版（如 1.1.0）。若只"用绝对路径调 1.1.3 的 cjc.exe"却**不覆盖 CANGJIE_HOME**，
  编译器虽是 1.1.3，但配的运行时/std 可能仍是旧版 → 工具链并未真正锁定。
- 正确锁定：`source <sdk>/cangjie/envsetup.ps1`（脚本把 CANGJIE_HOME 钉到自身目录，并把 bin/lib/runtime 前置 PATH），
  或显式 `export CANGJIE_HOME=<sdk-path>`。
- `cjpm` 是原生 Windows exe：需把 `$SDK/tools/bin` 加入 PATH（那里有 `libc++.dll`/`libunwind.dll` 等依赖），否则 0xC0000135。
- `cjlint`/`cjfmt` 需要 `CANGJIE_HOME` 为 Windows 形式 `D:/...`（非 `/d/...`），否则 EXIT 127。

## 9. `cjpm publish` 401 = 注册中心 token 缺失

- 注册中心配置在 `~/.cjpm/cangjie-repo.toml` 的 `[repository.home]`：
  `registry = "https://pkg.cangjie-lang.cn/registry"`、`token = ""`（默认**空**）。
- `cjpm publish` 用该 `token` 向注册中心鉴权，空即 `401 authentication failed`。
- **git 凭据 ≠ cjpm 注册中心凭据**：`~/.git-credentials` 的 gitcode/atomgit 令牌只管 git，
  与 cjpm 包注册中心无关（故 `git push` 能成但 `cjpm publish` 401，正是此因）。
- `cjpm` **没有 `login` 子命令**：鉴权纯靠 `cangjie-repo.toml` 的 `token` 字段。修复步骤：
  1. 到 `https://pkg.cangjie-lang.cn` 登录/注册 → 账户设置生成 Personal Access Token（前缀 `QXCT_`）；
  2. 把 `token = "..."` 填进 `~/.cjpm/cangjie-repo.toml` 的 `[repository.home]`；
  3. 重跑 `cjpm publish -V`。
- 该 toml **应加 `.gitignore`**（发布令牌，禁止进仓库）。
- 其他发布错误：
  - `409` = `name@version`（如 `chrono_tz@0.1.0`）已被占用 → 升 `cjpm.toml` 的 `version` 重发；
  - `403` / `400` = organization（cjpm.toml 中现常为空）或命名空间权限问题。

## 10. PowerShell 5.1 读无 BOM 的 UTF-8 .ps1 会按 GBK 解析

- 中文注释字节被误解析为 `\"` 致字符串提前闭合 → 脚本语法错误。
- 对策：CI/批处理脚本改为**全 ASCII 注释**，或保存为 **UTF-8 with BOM**。

## 11. `cjfmt` 无 check 模式

- 确认某文件是否已格式化：格式化到临时文件，规范化（去 BOM / 换行 / 行尾空白）后逐行比较，有差异即"未格式化"。

## 12. 元组用下标访问

- 仓颉元组用 `tup[0]` 访问元素，**不是** `tup.0`（`.0` 会被当浮点字面量报编译错）。

---

### 一页速查（排查顺序）

| 现象 | 优先怀疑 |
|---|---|
| `cjpm build` 报 `'X' is not accessible in package 'std.core'` | §1 子包 import，改通配 `import std.core.*` |
| `cjpm bundle` 报 `MANDATORY ... violated` | §3 G.EXP.03，`&&`/`||` 右操作数有函数调用，提局部变量 |
| `cjpm publish` 报 `401 authentication failed` | §9 注册中心 token 为空（git 令牌无效） |
| `cjpm test` 退出 1 但日志全绿 | §5 包装器怪癖，直接跑 unittest_bin/*.exe |
| 批处理脚本跑几个 cjc 后静默崩 | §6 cjc 累积崩溃 + 管道异常，改 `*> ` 重定向 + 隔离进程 |
| G.FUN.01 误以为是参数过多 | §4 实为行长 ≤50，拆分函数 |
| cjlint 条数翻倍 | §7 `-o` 追加，重跑前先 rm |
| 编译器版本对、运行时却怪错 | §8 CANGJIE_HOME 未真锁定，source envsetup 或显式 export |
