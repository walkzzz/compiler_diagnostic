---
name: cangjie-runtime
description: >
  仓颉运行时开发技能。当用户需要开发运行时、垃圾回收、线程管理、异常处理、
  FFI、Loader 或理解运行时架构时使用。涵盖 cangjie_runtime 仓库。
author: cangjie-expert-team
rail:
  capabilities: [gc-design, thread-management, ffi-binding, exception-handling]
  constraints: [no-compiler-modification, no-api-break-without-migration]
  requires: [cangjie-sdk-installed]
  provides: [runtime-patch, gc-config, ffi-bridge]
  collaborates_with: [cangjie-compiler, cangjie-std]
---

# 仓颉运行时开发技能

用于快速、可靠地执行运行时开发任务。

## 默认工作流

### 1. 明确目标和约束
- 确认预期行为、非目标、性能限制（GC 延迟、线程调度延迟）。

### 2. 定位模块边界
- 找到 `runtime/` 目录结构。
- 确定 GC、CJThread、异常处理的边界。

### 3. 编码前发现 API
- 优先使用 `cjpm ide doc` 查询现有 API。
- 使用 `cjpm ide outline` 进行语义导航。

### 4. 紧密循环验证
- 编辑后运行 `cjpm check`。
- 运行 `cjpm test` 验证运行时行为。
- 运行 `cjprof` 分析性能影响。

### 5. 交付前完成
- 运行 `cjpm fmt`。
- 运行 `cjpm info` 验证 API 变更。
- 报告更改和性能影响。

## 运行时架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      Cangjie Runtime                            │
└─────────────────────────────────────────────────────────────────┘

垃圾回收 (GC)
├── Fully Concurrent GC
│   └── 消除 STW 暂停
├── Sweep
│   └── 内存碎片整理
└── Pointer Tag
    └── 区分垃圾与新内存

线程管理 (CJThread)
├── Schedule
│   ├── 线程调度
│   ├── 监视器
│   ├── 处理器
│   └── schmon
└── Stack Grow
    └── 连续栈自动扩容

异常处理
├── Exception
│   └── 运行时逻辑错误（必须捕获）
└── Error
    └── 内部系统错误（应用不应抛出）

其他组件
├── Loader
│   └── 包粒度加载，支持反射
├── Object Model
│   └── 对象元数据、方法表
├── FFI
│   └── C/ArkTS 互操作
└── DFX
    └── 日志、CPU Profiling、堆快照
```

## 源代码目录

```
cangjie_runtime/runtime/src/
├── Base           # 基础模块
├── CJThread       # 线程管理
├── Common         # 公共模块
├── Concurrency    # 并发管理
├── CpuProfiler    # CPU 分析
├── Demangler      # 符号反修饰
├── Exception      # 异常处理
├── Heap           # 堆内存管理
├── Inspector      # DFX 工具
├── Loader         # 加载器
├── Mutator        # 变器管理
├── ObjectModel    # 对象模型
├── Signal         # 信号处理
├── StackMap       # 栈元数据
├── Sync           # 同步原语
├── UnwindStack    # 栈展开
├── Utils          # 工具类
├── arch           # 硬件适配
└── os             # 系统适配
```

## GC 设计要点

### Fully Concurrent GC

```
目标：消除 Stop-The-World 暂停

实现：
1. 标记阶段：并发标记存活对象
2. 清理阶段：并发清理垃圾对象
3. 重定位阶段：并发整理内存碎片

关键数据结构：
- Mark BitMap：标记存活对象
- Forwarding Table：重定位表
- Free List：空闲内存列表
```

### CJThread 调度

```
目标：轻量级线程，高效并发

实现：
1. 用户态线程调度
2. 工作窃取负载均衡
3. 连续栈自动扩容

关键数据结构：
- Schedule：调度器
- Monitor：监视器
- Processor：处理器
```

## 验证契约

- **稳定能力事实**：GC 并发模型、CJThread 调度、异常处理机制。
- **验证精确事实**：GC 参数、线程 API、FFI 接口，由 `cjpm ide` 和本地文件验证。
- **未验证猜测**：从其他运行时（JVM、Go runtime）推断的行为。

## 文件结构

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主技能入口 |
| `README.md` | 运行时开发概述 |
| `CHANGELOG.md` | 版本变更记录 |
| `references/gc-design.md` | GC 设计文档 |
| `references/thread-scheduling.md` | 线程调度文档 |
| `references/ffi-guide.md` | FFI 开发指南 |
