# Rail 系统规范

> 参考: openJiuwen ActionSpec — body-agnostic behavior contract
> 状态: v7.0 设计文档

## 1. Rail 定义

Rail 是每个专家技能的能力约束声明。它回答四个问题：

- **能做什么** (capabilities) — 这个专家具备的能力集合
- **不能做什么** (constraints) — 这个专家的行为边界
- **需要什么** (requires) — 执行前置条件
- **提供什么** (provides) — 执行后产出物

## 2. Rail YAML 格式

```yaml
rail:
  id: cangjie-compiler
  capabilities:
    - compile-cangjie
    - analyze-ast
    - optimize-ir
    - codegen
  constraints:
    - no-runtime-modification
    - no-stdlib-api-break
    - read-only-source-analysis
  requires:
    - cangjie-sdk-installed
    - source-code-available
  provides:
    - compiled-binary
    - optimization-report
    - ast-analysis
  collaborates_with:
    - cangjie-runtime
    - cangjie-tools
    - cangjie-std
  priority: high        # 路由优先级
  fallback: cangjie-orientation  # 失败后回退到的专家
```

## 3. 17 个专家的 Rail 定义

### cangjie-compiler
```yaml
capabilities: [compile-cangjie, analyze-ast, optimize-ir, codegen, type-check]
constraints: [no-runtime-modification, no-stdlib-api-break]
requires: [cangjie-sdk-installed, source-code-available]
provides: [compiled-binary, ast-analysis, type-errors]
collaborates_with: [cangjie-runtime, cangjie-tools, cangjie-std]
```

### cangjie-runtime
```yaml
capabilities: [gc-design, thread-management, ffi-binding, exception-handling]
constraints: [no-compiler-modification, no-api-break-without-migration]
requires: [cangjie-sdk-installed]
provides: [runtime-patch, gc-config, ffi-bridge]
collaborates_with: [cangjie-compiler, cangjie-std]
```

### cangjie-tools
```yaml
capabilities: [cjpm-ops, cjfmt, cjprof, cjlint, toolchain-config]
constraints: [no-source-code-modification]
requires: [cangjie-sdk-installed]
provides: [formatted-code, profile-report, lint-result]
collaborates_with: [cangjie-compiler, cangjie-std]
```

### cangjie-std
```yaml
capabilities: [std-api, collection, io, fs, math, crypto, convert, time]
constraints: [no-internal-impl-exposure, stable-api-guarantee]
requires: [cangjie-sdk-installed]
provides: [api-doc, usage-example, migration-guide]
collaborates_with: [cangjie-compiler, cangjie-stdx, cangjie-tools]
```

### cangjie-stdx
```yaml
capabilities: [net, crypto, encoding, log, compress]
constraints: [no-stdlib-replacement, no-breaking-change]
requires: [cangjie-sdk-installed]
provides: [extension-lib, api-doc, integration-example]
collaborates_with: [cangjie-std, cangjie-net, cangjie-sec]
```

### cangjie-framework
```yaml
capabilities: [cjoy, tea, ioc, rest, middleware, di]
constraints: [no-stdlib-modification, backward-compat]
requires: [cangjie-sdk-installed, cangjie-std, cangjie-stdx]
provides: [framework-scaffold, api-design, integration-guide]
collaborates_with: [cangjie-std, cangjie-stdx, cangjie-net, cangjie-db]
```

### cangjie-db
```yaml
capabilities: [sql, orm, redis, driver, opengauss, mysql]
constraints: [no-driver-source-modification]
requires: [cangjie-sdk-installed, cangjie-std]
provides: [db-driver, orm-config, connection-pool]
collaborates_with: [cangjie-std, cangjie-stdx, cangjie-sec]
```

### cangjie-net
```yaml
capabilities: [http, websocket, mqtt, rpc, grpc, tcp, udp]
constraints: [no-protocol-spec-modification]
requires: [cangjie-sdk-installed, cangjie-std]
provides: [protocol-impl, client-server, api-doc]
collaborates_with: [cangjie-std, cangjie-stdx, cangjie-sec, cangjie-framework]
```

### cangjie-ai
```yaml
capabilities: [agent, mcp, llm, planner, cangjie-magic, magic-explorer]
constraints: [no-model-weight-modification, no-external-api-call-without-permission]
requires: [cangjie-sdk-installed, cangjie-std, cangjie-net]
provides: [agent-dsl, mcp-server, tool-registration]
collaborates_with: [cangjie-framework, cangjie-net, cangjie-tools]
```

### cangjie-sec
```yaml
capabilities: [crypto, sm2, sm3, sm4, tls, cert, key-management]
constraints: [no-key-exposure, no-insecure-defaults]
requires: [cangjie-sdk-installed, cangjie-std]
provides: [crypto-impl, tls-config, security-audit]
collaborates_with: [cangjie-std, cangjie-stdx, cangjie-net]
```

### cangjie-ui
```yaml
capabilities: [animation, component, layout, lottie, svga, harmonyos]
constraints: [no-platform-api-break]
requires: [cangjie-sdk-installed, cangjie-std]
provides: [ui-component, animation-config, layout-spec]
collaborates_with: [cangjie-std, cangjie-framework]
```

### cangjie-release
```yaml
capabilities: [version, build, package, semver, changelog]
constraints: [no-unreleased-features, no-skip-tests]
requires: [cangjie-sdk-installed, source-code-available, tests-passing]
provides: [release-package, release-notes, version-tag]
collaborates_with: [cangjie-cicd, cangjie-doc, cangjie-tools]
```

### cangjie-cicd
```yaml
capabilities: [github-actions, cross-compile, release, dmg, exe, tarball]
constraints: [no-secret-in-workflow, no-skip-checks]
requires: [github-repo-access, cangjie-sdk-url]
provides: [workflow-yml, build-matrix, release-assets]
collaborates_with: [cangjie-release, cangjie-tools, cangjie-doc]
```

### cangjie-doc
```yaml
capabilities: [readme, changelog, api-doc, contributing, faq]
constraints: [no-code-modification, docs-only]
requires: [source-code-available]
provides: [doc-files, api-reference, style-guide]
collaborates_with: [cangjie-orientation, cangjie-comm]
```

### cangjie-edu
```yaml
capabilities: [course, tutorial, training, exercise, certification]
constraints: [no-production-code-modification]
requires: [cangjie-sdk-installed]
provides: [course-material, tutorial, exercise-solution]
collaborates_with: [cangjie-orientation, cangjie-comm, cangjie-doc]
```

### cangjie-comm
```yaml
capabilities: [forum, event, contribution, issue-triage, pr-review]
constraints: [no-code-modification, community-only]
requires: [repo-access]
provides: [community-report, event-plan, contribution-guide]
collaborates_with: [cangjie-doc, cangjie-edu]
```

### cangjie-orientation
```yaml
capabilities: [faq, guide, example, getting-started, api-lookup]
constraints: [read-only, no-code-modification]
requires: []
provides: [answer, example-code, doc-link]
collaborates_with: [all]  # 通用回退，可与任何专家联动
```

## 4. Rail 组合规则

当 Swarm 模式需要多个专家协作时，Rail 组合：

```
Rail(A) + Rail(B):
  capabilities = A.capabilities ∪ B.capabilities
  constraints  = A.constraints ∪ B.constraints
  requires     = A.requires ∪ B.requires
  provides     = A.provides ∪ B.provides
  collaborates = A.collaborates ∪ B.collaborates
```

冲突检测：如果 A.constraints 与 B.capabilities 冲突（A 禁止某事，B 要做某事），则不能组合。

## 5. Rail 门控算法

```
can_execute(skill, task, context):
  rail = load_rail(skill)

  # 1. 能力检查：任务需要的能力是否都在 Rail 中
  for cap in task.required_capabilities:
    if cap not in rail.capabilities:
      return Reject("missing capability: " + cap)

  # 2. 约束检查：任务是否违反任何约束
  for constraint in rail.constraints:
    if task.violates(constraint):
      return Reject("constraint violated: " + constraint)

  # 3. 依赖检查：前置条件是否满足
  for dep in rail.requires:
    if not check_dependency(dep, context):
      return Reject("dependency not met: " + dep)

  return Accept()
```
