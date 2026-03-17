# 架构

LLMDash 是一个用于监控 LLM API 额度余额的 macOS 菜单栏应用，附带一个小组件扩展。完全使用 SwiftUI 构建，无外部依赖。

## 主应用 (`LLMDash/`)

### 入口点 (`LLMDashApp.swift`)

应用使用 `@main` 和 SwiftUI 的 `MenuBarExtra` 场景渲染为菜单栏应用（无 Dock 图标）。菜单栏附加项使用 `.menuBarExtraStyle(.window)` 显示弹出窗口。另有一个 `Window` 场景提供设置视图。

### 模型

- **`LLMProvider.swift`**：定义 `ProviderType` 枚举（`openai`、`anthropic`、`google`），包含提供商特定的元数据（图标、管理密钥提示、账单 URL）。定义 `LLMProviderAccount` 结构体，包含 id、名称、类型、API 密钥、活跃状态和可选的手动余额。
- **`UsageData.swift`**：保存每账户的使用数据，包括总 token 使用量、总费用、剩余额度、硬限额、计费周期日期和最后更新时间戳。包含格式化字符串辅助方法。
- **`AppState.swift`**：核心 `@MainActor ObservableObject`，管理所有应用状态。持有账户、使用数据映射、已获取余额、加载状态和错误信息。协调自动刷新（5 分钟定时器）、通过 `BalanceAutoRefresher` 进行余额自动刷新，以及通过 `syncToWidget()` 进行小组件同步。

### 视图

- **`DashboardView.swift`**：主菜单栏弹出窗口。显示摘要栏（总费用、活跃提供商数量）、可滚动的提供商卡片列表、错误显示，以及底部的自动刷新状态和退出按钮。固定为 360x480 点。
- **`ProviderCardView.swift`**：单个卡片，显示提供商名称、余额、费用和 token 使用量。
- **`SettingsView.swift`**：标签式设置窗口，包含 API Keys 标签页（添加/移除提供商账户）和 Balance 标签页（基于 Web 登录提供商账单页面以获取余额）。
- **`WebLoginView.swift`**：封装 WKWebView，用于在应用内浏览器登录提供商账单页面。

### 服务

- **`UsageService.swift`**：从提供商管理 API 获取使用数据。
  - **OpenAI**：调用 `/v1/organization/costs` 获取 30 天费用数据，调用 `/v1/organization/usage/completions` 获取 token 计数。使用 Bearer token 认证和管理密钥。优雅处理 403 错误（回退到网页抓取的余额）。
  - **Anthropic**：调用 `/v1/organizations/cost_report` 和 `/v1/organizations/usage_report/messages`，使用 `x-api-key` 请求头。同样采用 30 天滚动窗口。
  - **Google AI**：仅返回手动余额（未实现 API 使用量获取）。

- **`AccountStore.swift`**：将账户元数据（名称、类型、活跃状态）持久化到 `~/Library/Application Support/LLMDash/accounts.json`。API 密钥通过 Security 框架单独存储在 macOS 钥匙串中，确保凭证安全存储。

- **`WebBalanceFetcher.swift`**：交互式基于 Web 的余额获取器。打开 WKWebView 访问提供商账单页面，等待页面加载后使用正则表达式从页面文本中提取余额金额。支持重试（最多 3 次，每次间隔 3 秒以等待 SPA 渲染）。

- **`BalanceAutoRefresher.swift`**：后台余额获取器，每 5 分钟运行一次。使用无界面（1x1 像素）的 WKWebView 加载账单页面，无需用户交互即可提取余额。依赖先前 WebBalanceFetcher 登录时持久化的浏览器会话（cookie）。每个提供商 30 秒超时。

## 小组件扩展 (`LLMDashWidget/`)

### `LLMDashWidget.swift`

一个 WidgetKit 扩展，提供小尺寸和中尺寸两种小组件。

- **`BalanceTimelineProvider`**：从磁盘加载共享数据并创建时间线条目。通过 `.after()` 时间线策略每 5 分钟刷新一次。
- **`SmallWidgetView`**：显示 LLMDash 标志和最多 2 个提供商余额。
- **`MediumWidgetView`**：左侧显示总费用摘要，右侧显示完整的提供商列表，包含每个提供商的余额和费用。

## 共享数据 (`Shared/`)

### `SharedBalanceData.swift`

定义主应用和小组件扩展之间的数据契约。使用 App Groups（`group.com.llmdash`）进行共享文件存储。

- `SharedBalanceData`：包含 `SharedProviderBalance` 条目数组、总费用和最后更新时间戳。
- 数据序列化为 JSON，使用 ISO 8601 日期格式。
- 主应用在每次刷新后通过 `save()` 写入共享文件，然后调用 `WidgetCenter.shared.reloadAllTimelines()` 触发小组件更新。
- 小组件通过 `SharedBalanceData.load()` 读取数据。
- 如果 App Group 容器不可用，回退到 `~/Library/Application Support/LLMDash/`。
