---
name: cangjie-ui
description: >
  仓颉 UI 开发技能。当用户需要开发或使用动画、UI 组件、布局、HarmonyOS UI 时使用。
  涵盖 lottie4cj、svga-cj、rebound4cj、HarmonyOS-Examples 等仓库。
author: cangjie-expert-team
rail:
  capabilities: [animation, component, layout, lottie, svga, harmonyos]
  constraints: [no-platform-api-break]
  requires: [cangjie-sdk-installed, cangjie-std]
  provides: [ui-component, animation-config, layout-spec]
  collaborates_with: [cangjie-std, cangjie-framework]
---

# 仓颉 UI 开发技能

用于快速、可靠地执行 UI 开发任务。

## 默认工作流

### 1. 明确目标和约束
- 确认预期行为、非目标、平台兼容性约束。

### 2. 定位 UI 模块边界
- 找到对应 UI 模块目录。
- 确定 UI 组件的公共 API 边界。

### 3. 编码前发现 API
- 优先使用 `cjpm ide doc` 查询现有 API。
- 使用 `cjpm ide outline` 进行语义导航。

### 4. 紧密循环验证
- 编辑后运行 `cjpm check`。
- 运行 `cjpm test` 验证 UI 行为。

### 5. 交付前完成
- 运行 `cjpm fmt`。
- 运行 `cjpm info` 验证 API 变更。

## UI 架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      Cangjie UI 生态                            │
└─────────────────────────────────────────────────────────────────┘

动画库
├── lottie4cj
│   ├── JSON 动画
│   ├── Lottie 兼容
│   └── 动画播放
├── svga-cj
│   ├── SVGA 格式
│   └── 动画展示
├── rebound4cj
│   ├── 弹簧动力学
│   └── 物理动画
├── shimmer4cj
│   ├── 闪烁效果
│   └── 多种闪光模式
└── easing-functions-cj
    └── 缓动函数

UI 组件
├── banner4cj
│   └── 广告图片轮播
├── bullet-screen-cj
│   └── 弹幕发送与解析
├── photoview4cj
│   └── 图片缩放浏览
├── rounded-image-view-cj
│   └── 圆角图片
├── circle-image-view-cj
│   └── 圆形图片
├── large-image-cj
│   └── 大图加载
└── gifdrawable4cj
    └── GIF 加载

图像处理
├── svg4cj
│   ├── SVG 解析
│   └── SVG 渲染
├── droplet
│   └── 图像加载
├── droplet-transformations
│   ├── 滤镜 (高亮、灰度、马赛克、油画等)
│   └── 图像转换
└── avif-ffi
    └── AVIF 解码

视频处理
├── ijkplayer-ffi
│   ├── ijkplayer 封装
│   └── 基于 FFmpeg
├── videocache4cj
│   └── 边下边播
├── video-compress-cj
│   └── 视频压缩
└── mp4parser4cj
    └── MP4 解析

音频处理
├── aad4cj
│   └── AAC 解析
├── minimp3-cj
│   └── MP3 解码
└── mp3tag4cj
    └── MP3 标签
```

## 源代码目录

```
lottie4cj/
├── src/
│   ├── parser/           # JSON 解析
│   ├── renderer/         # 渲染器
│   └── view/             # 视图组件
└── tests/

svga-cj/
├── src/
│   ├── parser/           # SVGA 解析
│   ├── decoder/          # 解码器
│   └── view/             # 视图组件
└── tests/

HarmonyOS-Examples/
├── ui/                   # UI 示例
│   ├── components/
│   ├── layouts/
│   └── animations/
└── projects/
```

## 验证契约

- **稳定能力事实**：动画系统、组件 API、布局系统。
- **验证精确事实**：精确 API 名称、签名，由 `cjpm ide doc` 和本地文件验证。
- **未验证猜测**：从其他 UI 框架（Flutter、React Native）推断的 API。

## 文件结构

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主技能入口 |
| `README.md` | UI 开发概述 |
| `CHANGELOG.md` | 版本变更记录 |
| `references/animation-guide.md` | 动画开发指南 |
| `references/component-guide.md` | 组件开发指南 |
| `references/harmonyos-ui.md` | HarmonyOS UI 指南 |
