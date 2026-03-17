# 시작하기

## 사전 요구 사항

- **macOS 14.0+** (Sonoma 이상)
- **Xcode 16+**

## 설치

1. 리포지토리를 클론합니다:

```bash
git clone https://github.com/ChadApplication/llmdash.git
cd llmdash
```

2. spec 파일에서 Xcode 프로젝트를 생성합니다:

```bash
xcodegen generate
```

3. Xcode에서 프로젝트를 엽니다:

```bash
open LLMDash.xcodeproj
```

4. 빌드하고 실행합니다 (Cmd+R).

앱이 macOS 메뉴 바에 나타납니다.

## 처음 사용 시

1. 메뉴 바의 뇌 아이콘을 클릭하여 대시보드를 엽니다.
2. 톱니바퀴 아이콘을 클릭하여 설정을 엽니다.
3. **API Keys** 탭에서 LLM 프로바이더 자격 증명을 추가합니다 (OpenAI, Anthropic 또는 Google AI).
4. **Balance** 탭에서 각 프로바이더의 결제 페이지에 로그인하여 내장 WebView를 통한 자동 잔액 조회를 활성화합니다.
5. 대시보드는 5분마다 자동 새로고침됩니다. 새로고침 버튼을 수동으로 클릭할 수도 있습니다.

## 위젯

앱을 최소 한 번 실행한 후 바탕화면이나 알림 센터에 LLMDash 위젯을 추가하세요:
1. 바탕화면을 우클릭하고 "위젯 편집"을 선택합니다.
2. "LLMDash"를 검색하고 위젯을 추가합니다 (소형 및 중형 크기 제공).
3. 위젯은 App Groups를 통해 메인 앱의 공유 데이터를 읽으며 5분마다 새로고침됩니다.
