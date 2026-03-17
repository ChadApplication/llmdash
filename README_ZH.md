# LLMDash

用于监控 LLM API 余额（OpenAI、Anthropic 等）的 macOS 菜单栏应用，附带桌面小组件。

## 前置要求

- macOS 14.0+
- Xcode 16+

## 安装

```bash
git clone https://github.com/ChadApplication/llmdash.git
cd llmdash
xcodegen generate        # 从 project.yml 生成 Xcode 项目
open LLMDash.xcodeproj   # 在 Xcode 中打开
```

在 Xcode 中构建并运行 (Cmd+R)。

## 功能

- 实时余额显示的菜单栏应用
- 快速查看的 macOS 小组件
- 多服务商支持
- 通过 App Groups 在应用和小组件间共享数据

## 项目结构

```
llmdash/
├── project.yml              # XcodeGen 项目规格
├── LLMDash/                 # 主应用
│   ├── LLMDashApp.swift     # 应用入口（菜单栏）
│   ├── Views/               # SwiftUI 视图
│   ├── Models/              # 数据模型
│   ├── Services/            # API 服务
│   └── Resources/           # 资源
├── LLMDashWidget/           # 小组件扩展
│   └── LLMDashWidget.swift
└── Shared/                  # 共享代码（应用 + 小组件）
    └── SharedBalanceData.swift
```

## 变更日志

### v0.0.1 (2026-03-17)

- 初始公开发布
- 余额监控菜单栏应用
- macOS 小组件扩展
- 项目设置中添加版权和版本信息

## 许可证

Copyright (c) chadchae
