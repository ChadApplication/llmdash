# Architecture

LLMDash is a macOS menu bar application for monitoring LLM API credit balances, with a companion widget extension. It is built entirely in SwiftUI with no external dependencies.

## Main App (`LLMDash/`)

### Entry Point (`LLMDashApp.swift`)

The app uses `@main` with SwiftUI's `MenuBarExtra` scene to render as a menu bar app (no dock icon). The menu bar extra uses `.menuBarExtraStyle(.window)` to display a popover window. A secondary `Window` scene provides the Settings view.

### Models

- **`LLMProvider.swift`**: Defines `ProviderType` enum (`openai`, `anthropic`, `google`) with provider-specific metadata (icon, admin key hints, billing URLs). Defines `LLMProviderAccount` struct with id, name, type, API key, active status, and optional manual balance.
- **`UsageData.swift`**: Holds per-account usage data including total tokens used, total cost, remaining credits, hard limit, period dates, and last updated timestamp. Includes formatted string helpers.
- **`AppState.swift`**: The central `@MainActor ObservableObject` managing all app state. Holds accounts, usage data map, fetched balances, loading state, and error messages. Coordinates auto-refresh (5-minute timer), balance auto-refresh via `BalanceAutoRefresher`, and widget sync via `syncToWidget()`.

### Views

- **`DashboardView.swift`**: The main menu bar popover. Shows a summary bar (total cost, active provider count), a scrollable list of provider cards, error display, and a footer with auto-refresh status and quit button. Fixed at 360x480 points.
- **`ProviderCardView.swift`**: Individual card showing provider name, balance, cost, and token usage.
- **`SettingsView.swift`**: Tabbed settings window with API Keys tab (add/remove provider accounts) and Balance tab (web-based login to fetch balances from provider billing pages).
- **`WebLoginView.swift`**: Wraps a WKWebView for in-app browser login to provider billing pages.

### Services

- **`UsageService.swift`**: Fetches usage data from provider Admin APIs.
  - **OpenAI**: Calls `/v1/organization/costs` for 30-day cost data and `/v1/organization/usage/completions` for token counts. Uses Bearer token auth with admin key. Gracefully handles 403 (falls back to web-scraped balance).
  - **Anthropic**: Calls `/v1/organizations/cost_report` and `/v1/organizations/usage_report/messages` with `x-api-key` header. Same 30-day rolling window.
  - **Google AI**: Returns manual balance only (no API usage fetching implemented).

- **`AccountStore.swift`**: Persists account metadata (name, type, active status) to `~/Library/Application Support/LLMDash/accounts.json`. API keys are stored separately in the macOS Keychain via Security framework for secure credential storage.

- **`WebBalanceFetcher.swift`**: Interactive web-based balance fetcher. Opens a WKWebView to provider billing pages, waits for page load, then extracts balance amounts from page text using regex patterns. Supports retry (up to 3 attempts with 3-second delays for SPA rendering).

- **`BalanceAutoRefresher.swift`**: Background balance fetcher that runs every 5 minutes. Uses headless (1x1 pixel) WKWebViews to load billing pages and extract balances without user interaction. Relies on persisted browser sessions (cookies) from prior WebBalanceFetcher logins. 30-second timeout per provider.

## Widget Extension (`LLMDashWidget/`)

### `LLMDashWidget.swift`

A WidgetKit extension providing small and medium widget sizes.

- **`BalanceTimelineProvider`**: Loads shared data from disk and creates timeline entries. Refreshes every 5 minutes via `.after()` timeline policy.
- **`SmallWidgetView`**: Shows the LLMDash logo and up to 2 provider balances.
- **`MediumWidgetView`**: Shows total cost summary on the left and a full provider list on the right with per-provider balance and cost.

## Shared Data (`Shared/`)

### `SharedBalanceData.swift`

Defines the data contract between the main app and the widget extension. Uses App Groups (`group.com.llmdash`) for shared file storage.

- `SharedBalanceData`: Contains an array of `SharedProviderBalance` entries, total cost, and last updated timestamp.
- Data is serialized as JSON with ISO 8601 dates.
- The main app writes to the shared file via `save()` after each refresh, then calls `WidgetCenter.shared.reloadAllTimelines()` to trigger widget updates.
- The widget reads via `SharedBalanceData.load()`.
- Falls back to `~/Library/Application Support/LLMDash/` if the App Group container is unavailable.
