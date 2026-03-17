# 아키텍처

LLMDash는 LLM API 크레딧 잔액을 모니터링하기 위한 macOS 메뉴 바 애플리케이션으로, 위젯 확장 프로그램이 함께 제공됩니다. 외부 의존성 없이 전적으로 SwiftUI로 구축되었습니다.

## 메인 앱 (`LLMDash/`)

### 진입점 (`LLMDashApp.swift`)

앱은 `@main`과 SwiftUI의 `MenuBarExtra` 씬을 사용하여 메뉴 바 앱으로 렌더링됩니다 (독 아이콘 없음). 메뉴 바 엑스트라는 `.menuBarExtraStyle(.window)`를 사용하여 팝오버 윈도우를 표시합니다. 보조 `Window` 씬은 설정 뷰를 제공합니다.

### 모델

- **`LLMProvider.swift`**: `ProviderType` 열거형 (`openai`, `anthropic`, `google`)을 프로바이더별 메타데이터(아이콘, 관리자 키 힌트, 결제 URL)와 함께 정의합니다. id, 이름, 타입, API 키, 활성 상태, 선택적 수동 잔액을 가진 `LLMProviderAccount` 구조체를 정의합니다.
- **`UsageData.swift`**: 총 사용 토큰, 총 비용, 남은 크레딧, 하드 리밋, 기간 날짜, 마지막 업데이트 타임스탬프를 포함한 계정별 사용량 데이터를 보유합니다. 포맷된 문자열 헬퍼를 포함합니다.
- **`AppState.swift`**: 모든 앱 상태를 관리하는 중앙 `@MainActor ObservableObject`입니다. 계정, 사용량 데이터 맵, 조회된 잔액, 로딩 상태, 오류 메시지를 보유합니다. 자동 새로고침(5분 타이머), `BalanceAutoRefresher`를 통한 잔액 자동 새로고침, `syncToWidget()`을 통한 위젯 동기화를 조율합니다.

### 뷰

- **`DashboardView.swift`**: 메인 메뉴 바 팝오버입니다. 요약 바(총 비용, 활성 프로바이더 수), 프로바이더 카드의 스크롤 가능한 목록, 오류 표시, 자동 새로고침 상태 및 종료 버튼이 있는 푸터를 보여줍니다. 360x480 포인트로 고정됩니다.
- **`ProviderCardView.swift`**: 프로바이더 이름, 잔액, 비용, 토큰 사용량을 보여주는 개별 카드입니다.
- **`SettingsView.swift`**: API Keys 탭(프로바이더 계정 추가/제거)과 Balance 탭(프로바이더 결제 페이지에서 잔액을 조회하기 위한 웹 기반 로그인)이 있는 탭 형식의 설정 윈도우입니다.
- **`WebLoginView.swift`**: 프로바이더 결제 페이지에 인앱 브라우저 로그인을 위해 WKWebView를 래핑합니다.

### 서비스

- **`UsageService.swift`**: 프로바이더 Admin API에서 사용량 데이터를 조회합니다.
  - **OpenAI**: 30일 비용 데이터를 위해 `/v1/organization/costs`를, 토큰 수를 위해 `/v1/organization/usage/completions`를 호출합니다. 관리자 키로 Bearer 토큰 인증을 사용합니다. 403은 우아하게 처리합니다 (웹 스크래핑 잔액으로 폴백).
  - **Anthropic**: `x-api-key` 헤더로 `/v1/organizations/cost_report` 및 `/v1/organizations/usage_report/messages`를 호출합니다. 동일한 30일 롤링 윈도우입니다.
  - **Google AI**: 수동 잔액만 반환합니다 (API 사용량 조회 미구현).

- **`AccountStore.swift`**: 계정 메타데이터(이름, 타입, 활성 상태)를 `~/Library/Application Support/LLMDash/accounts.json`에 영속화합니다. API 키는 안전한 자격 증명 저장을 위해 Security 프레임워크를 통해 macOS Keychain에 별도 저장됩니다.

- **`WebBalanceFetcher.swift`**: 대화형 웹 기반 잔액 조회기입니다. 프로바이더 결제 페이지에 WKWebView를 열고 페이지 로드를 기다린 후 정규식 패턴을 사용하여 페이지 텍스트에서 잔액을 추출합니다. 재시도를 지원합니다 (SPA 렌더링을 위해 3초 간격으로 최대 3회 시도).

- **`BalanceAutoRefresher.swift`**: 5분마다 실행되는 백그라운드 잔액 조회기입니다. 사용자 상호작용 없이 결제 페이지를 로드하고 잔액을 추출하기 위해 헤드리스(1x1 픽셀) WKWebView를 사용합니다. 이전 WebBalanceFetcher 로그인에서 영속화된 브라우저 세션(쿠키)에 의존합니다. 프로바이더당 30초 타임아웃입니다.

## 위젯 확장 (`LLMDashWidget/`)

### `LLMDashWidget.swift`

소형 및 중형 위젯 크기를 제공하는 WidgetKit 확장입니다.

- **`BalanceTimelineProvider`**: 디스크에서 공유 데이터를 로드하고 타임라인 항목을 생성합니다. `.after()` 타임라인 정책으로 5분마다 새로고침됩니다.
- **`SmallWidgetView`**: LLMDash 로고와 최대 2개의 프로바이더 잔액을 표시합니다.
- **`MediumWidgetView`**: 왼쪽에 총 비용 요약을, 오른쪽에 프로바이더별 잔액과 비용이 포함된 전체 프로바이더 목록을 표시합니다.

## 공유 데이터 (`Shared/`)

### `SharedBalanceData.swift`

메인 앱과 위젯 확장 간의 데이터 계약을 정의합니다. 공유 파일 저장을 위해 App Groups (`group.com.llmdash`)를 사용합니다.

- `SharedBalanceData`: `SharedProviderBalance` 항목 배열, 총 비용, 마지막 업데이트 타임스탬프를 포함합니다.
- 데이터는 ISO 8601 날짜 형식의 JSON으로 직렬화됩니다.
- 메인 앱은 각 새로고침 후 `save()`를 통해 공유 파일에 기록한 다음 `WidgetCenter.shared.reloadAllTimelines()`를 호출하여 위젯 업데이트를 트리거합니다.
- 위젯은 `SharedBalanceData.load()`를 통해 읽습니다.
- App Group 컨테이너를 사용할 수 없는 경우 `~/Library/Application Support/LLMDash/`로 폴백합니다.
