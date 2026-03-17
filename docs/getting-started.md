# Getting Started

## Prerequisites

- **macOS 14.0+** (Sonoma or later)
- **Xcode 16+**

## Installation

1. Clone the repository:

```bash
git clone https://github.com/ChadApplication/llmdash.git
cd llmdash
```

2. Generate the Xcode project from the spec file:

```bash
xcodegen generate
```

3. Open the project in Xcode:

```bash
open LLMDash.xcodeproj
```

4. Build and run (Cmd+R).

The app will appear in the macOS menu bar.

## First Use

1. Click the brain icon in the menu bar to open the dashboard.
2. Click the gear icon to open Settings.
3. In the **API Keys** tab, add your LLM provider credentials (OpenAI, Anthropic, or Google AI).
4. In the **Balance** tab, log in to each provider's billing page to enable automatic balance fetching via the built-in WebView.
5. The dashboard will auto-refresh every 5 minutes. You can also click the refresh button manually.

## Widget

After running the app at least once, add the LLMDash widget to your desktop or Notification Center:
1. Right-click on the desktop and select "Edit Widgets".
2. Search for "LLMDash" and add the widget (available in small and medium sizes).
3. The widget reads shared data from the main app via App Groups and refreshes every 5 minutes.
