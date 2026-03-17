# LLMDash

LLM API 잔액(OpenAI, Anthropic 등)을 모니터링하기 위한 macOS 메뉴 바 앱과 위젯.

## 사전 요구 사항

- macOS 14.0+
- Xcode 16+

## 설치

```bash
git clone https://github.com/ChadApplication/llmdash.git
cd llmdash
xcodegen generate        # project.yml에서 Xcode 프로젝트 생성
open LLMDash.xcodeproj   # Xcode에서 열기
```

Xcode에서 빌드 및 실행 (Cmd+R).

## 기능

- 실시간 잔액 표시가 가능한 메뉴 바 앱
- 빠른 확인을 위한 macOS 위젯
- 멀티 프로바이더 지원
- App Groups를 통한 앱과 위젯 간 데이터 공유

## 프로젝트 구조

```
llmdash/
├── project.yml              # XcodeGen 프로젝트 스펙
├── LLMDash/                 # 메인 앱
│   ├── LLMDashApp.swift     # 앱 진입점 (메뉴 바)
│   ├── Views/               # SwiftUI 뷰
│   ├── Models/              # 데이터 모델
│   ├── Services/            # API 서비스
│   └── Resources/           # 에셋
├── LLMDashWidget/           # 위젯 익스텐션
│   └── LLMDashWidget.swift
└── Shared/                  # 공유 코드 (앱 + 위젯)
    └── SharedBalanceData.swift
```

## 변경 이력

### v0.0.1 (2026-03-17)

- 초기 공개 릴리스
- 잔액 모니터링 메뉴 바 앱
- macOS 위젯 익스텐션
- 프로젝트 설정에 저작권 및 버전 정보

## 라이선스

Copyright (c) chadchae
