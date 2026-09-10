# 仓颉工具链

> [← 返回首页](../README.md) | [工具链](moon-commands.md)

## 概述

仓颉工具链提供完整的开发工具，包括包管理、代码格式化、性能分析、静态分析等。

## 工具列表

### cjpm - 包管理

```bash
# 创建新模块
cjpm new my_module

# 构建项目
cjpm build

# 运行测试
cjpm test

# 添加依赖
cjpm add dependency
```

### cjfmt - 代码格式化

```bash
# 格式化单个文件
cjfmt format file.cj

# 格式化整个项目
cjfmt format .
```

### cjprof - 性能分析

```bash
# CPU 热点采样
cjprof profile --cpu program.cj

# 堆内存分析
cjprof profile --heap program.cj

# 生成火焰图
cjprof flame program.cj
```

### cjlint - 静态分析

```bash
# 代码检查
cjlint check .

# 自动修复
cjlint fix .
```

### cjcov - 覆盖率

```bash
# 生成覆盖率报告
cjcov coverage program.cj

# HTML 输出
cjcov coverage --html program.cj
```

### cjdb - 调试器

```bash
# 启动调试
cjdb program.cj

# 设置断点
break file.cj:10

# 查看变量
print variable
```

## 配置文件

### cjpm.toml

```toml
[package]
name = "my_project"
version = "1.0.0"
cjc-version = "1.0.0"
output-type = "executable"

[dependencies]
# 依赖列表
```

## 相关文件

- [moon-commands.md](moon-commands.md) - 命令参考
- [configuration.md](configuration.md) - 配置指南
- [ide-integration.md](ide-integration.md) - IDE 集成
