# LLMDash

macOS menu bar app for monitoring LLM API balances (OpenAI, Anthropic, etc.) with a companion widget.

## Prerequisites

- macOS 14.0+
- Xcode 16+

## Installation

```bash
git clone https://github.com/ChadApplication/llmdash.git
cd llmdash
xcodegen generate        # Generate Xcode project from project.yml
open LLMDash.xcodeproj   # Open in Xcode
```

Build and run from Xcode (Cmd+R).

## Features

- Menu bar app with real-time balance display
- macOS widget for quick glance
- Multi-provider support
- Shared data between app and widget via App Groups

## Project Structure

```
llmdash/
├── project.yml              # XcodeGen project spec
├── LLMDash/                 # Main app
│   ├── LLMDashApp.swift     # App entry point (menu bar)
│   ├── Views/               # SwiftUI views
│   ├── Models/              # Data models
│   ├── Services/            # API services
│   └── Resources/           # Assets
├── LLMDashWidget/           # Widget extension
│   └── LLMDashWidget.swift
└── Shared/                  # Shared code (app + widget)
    └── SharedBalanceData.swift
```

## Changelog

### v0.0.1 (2026-03-17)

- Initial public release
- Menu bar app with balance monitoring
- macOS widget extension
- Copyright and version in project settings

## License

Copyright (c) chadchae
