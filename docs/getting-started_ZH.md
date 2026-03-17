# 快速入门

## 前置条件

- **macOS 14.0+**（Sonoma 或更高版本）
- **Xcode 16+**

## 安装

1. 克隆代码仓库：

```bash
git clone https://github.com/ChadApplication/llmdash.git
cd llmdash
```

2. 从 spec 文件生成 Xcode 项目：

```bash
xcodegen generate
```

3. 在 Xcode 中打开项目：

```bash
open LLMDash.xcodeproj
```

4. 构建并运行（Cmd+R）。

应用将出现在 macOS 菜单栏中。

## 首次使用

1. 点击菜单栏中的大脑图标打开仪表盘。
2. 点击齿轮图标打开设置。
3. 在 **API Keys** 标签页中，添加你的 LLM 提供商凭证（OpenAI、Anthropic 或 Google AI）。
4. 在 **Balance** 标签页中，登录每个提供商的账单页面，通过内置 WebView 启用自动余额获取。
5. 仪表盘将每 5 分钟自动刷新。你也可以手动点击刷新按钮。

## 小组件

应用运行至少一次后，将 LLMDash 小组件添加到桌面或通知中心：
1. 右键点击桌面并选择"编辑小组件"。
2. 搜索"LLMDash"并添加小组件（提供小尺寸和中尺寸）。
3. 小组件通过 App Groups 从主应用读取共享数据，每 5 分钟刷新一次。
