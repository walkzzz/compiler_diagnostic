---
name: cangjie-edu
description: >
  仓颉教育推广技能。当用户需要开发课程、编写教材、进行培训、设计教学方案时使用。
  涵盖 Learning、cangjie-books、cangjie-course 等仓库。
author: cangjie-expert-team
rail:
  capabilities: [course, tutorial, training, exercise, certification]
  constraints: [no-production-code-modification]
  requires: [cangjie-sdk-installed]
  provides: [course-material, tutorial, exercise-solution]
  collaborates_with: [cangjie-orientation, cangjie-comm, cangjie-doc]
---

# 仓颉教育推广技能

用于快速、可靠地执行教育推广任务。

## 默认工作流

### 1. 明确目标和约束
- 确认目标学员、教学目标、课时安排。

### 2. 定位教学内容
- 确定教学主题（语言基础、编译器、运行时、框架等）。
- 选择对应教材和参考资料。

### 3. 设计教学方案
- 制定教学大纲
- 设计实践环节
- 准备教学材料

### 4. 验证教学效果
- 设计练习题
- 准备测试题
- 收集反馈

## 教育资源架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      Cangjie 教育资源                           │
└─────────────────────────────────────────────────────────────────┘

教材配套
├── 仓颉编程快速上手
│   ├── 作者：刘玥、张荣超
│   └── 配套仓库：仓颉编程快速上手-刘玥_张荣超
├── 图解仓颉编程
│   ├── 作者：刘玥、张荣超
│   └── 配套仓库：图解仓颉编程-刘玥_张荣超
├── 图解仓颉高效编程
│   ├── 作者：吴京润
│   └── 配套仓库：图解仓颉高效编程-吴京润
├── 仓颉语言元编程
│   ├── 作者：张磊
│   ├── 出版社：清华大学出版社
│   └── 配套仓库：仓颉语言元编程-张磊
├── 仓颉语言实战
│   ├── 作者：张磊
│   ├── 出版社：清华大学出版社
│   └── 配套仓库：仓颉语言实战-张磊
└── 仓颉编程基础及应用
    ├── 作者：陈波、何睿（重庆大学）
    ├── 出版社：清华大学出版社
    └── 配套仓库：仓颉编程基础及应用_陈波_何睿_重庆大学

课程资源
├── cangjie-course
├── cangjie-learning
├── cangjie-tutorial
└── Learning (高校实践)

学习资料
├── cangjie-awesome
├── cangjie-resources
├── cangjie-knowledge
├── cangjie-notes
└── cangjie-books

实践平台
├── cangjie-practice
├── cangjie-study
├── cangjie-workshop
├── cangjie-exam
└── cangjie-quiz
```

## 教学大纲

### 初级课程（40 课时）

```
模块 1：语言基础（10 课时）
├── 仓颉语言简介
├── 基本语法
├── 数据类型
├── 控制流
└── 函数

模块 2：面向对象（10 课时）
├── 类与对象
├── 继承与多态
├── 接口
└── 泛型

模块 3：标准库（10 课时）
├── 集合库
├── I/O
├── 文件系统
└── 网络

模块 4：实践项目（10 课时）
├── 控制台应用
├── Web 应用
└── 综合项目
```

### 中级课程（40 课时）

```
模块 1：编译器原理（15 课时）
├── 词法分析
├── 语法分析
├── 语义分析
├── 中间表示
└── 代码生成

模块 2：运行时系统（15 课时）
├── 垃圾回收
├── 线程管理
├── 异常处理
└── FFI

模块 3：工具链（10 课时）
├── cjpm
├── cjfmt
├── cjprof
└── cjlint
```

### 高级课程（40 课时）

```
模块 1：框架开发（15 课时）
├── cjoy 框架
├── tea 框架
└── 中间件开发

模块 2：AI Agent（15 课时）
├── CangjieMagic
├── MCP 协议
└── Agent 开发

模块 3：开源贡献（10 课时）
├── 社区参与
├── PR 提交
└── 文档编写
```

## 源代码目录

```
Learning/
├── materials/            # 教学材料
├── courses/              # 课程
├── projects/             # 项目
└── universities/         # 高校合作

cangjie-course/
├── src/
│   ├── lessons/          # 课程内容
│   ├── exercises/        # 练习题
│   └── tests/            # 测试题
└── docs/

cangjie-books/
└── references/           # 书籍参考
```

## 验证契约

- **稳定能力事实**：课程结构、教材体系、教学大纲。
- **验证精确事实**：课程内容、练习题答案，由本地文件和教材验证。
- **未验证猜测**：从其他编程语言课程推断的教学内容。

## 文件结构

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主技能入口 |
| `README.md` | 教育推广概述 |
| `CHANGELOG.md` | 版本变更记录 |
| `references/curriculum-design.md` | 课程设计指南 |
| `references/textbook-list.md` | 教材列表 |
| `references/teaching-methods.md` | 教学方法 |
