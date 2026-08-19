# 디자인 출처

**Figma** https://www.figma.com/design/QKHhjWJNfvj1zcwThW29rz/Challenge5?node-id=30-24

이 파일이 **UI의 단일 출처**다. 코드와 어긋나면 Figma가 맞다.
디자인을 바꿔야 하면 Figma를 먼저 고치고, 그다음 코드를 맞춘다.

---

## 페이지 구성

| 페이지 | node | 내용 |
|---|---|---|
| `① Foundations` | `30:22` | 컬러 토큰, 타입 스케일, 스페이싱·라디우스 |
| `② Components` | `30:23` | 컴포넌트 라이브러리 |
| `③ App UI` | `30:24` | 12개 화면 |
| `Lo-Fi Prototype` | `0:1` | 초기 스케치·레퍼런스 (구현 기준 아님) |

---

## 화면 → 뷰 매핑

| Figma 프레임 | 크기 | View | 스펙 |
|---|---|---|---|
| `01 온보딩 · 땀 민감도` | 402×874 | `SensitivityStepView` | 001 |
| `02 온보딩 · 이동 패턴` | 402×874 | `TransportStepView` | 001 |
| `03 온보딩 · 알림 권한` | 402×874 | `NotificationStepView` | 001 |
| `04 홈 · 땀 등급 (스크롤)` | 402×1339 | `HomeView` | 002 |
| `05 등급 상세` | 402×874 | `StageDetailView` | 002 |
| `06 지도` | 402×874 | `MapHomeView` | 003 |
| `07 경로 입력` | 402×874 | `RouteInputView` | 003 |
| `08 실내외 비율 (스크롤)` | 402×1150 | `RouteResultView` | 003 |
| `09 이동 중` | 402×874 | `MoveView` | 004 |
| `10 마이페이지` | 402×1019 | `ProfileView` | 005 |
| `11 자가 기록` | 402×874 | `SweatLogView` | 005 |
| `12 지수 개선` | 402×874 | `CalibrationReportView` | 005 |

`(스크롤)` 표기가 붙은 프레임은 874pt를 넘는 세로 스크롤 화면이다.

---

## 컴포넌트 → Swift 매핑

| Figma 컴포넌트 | Variants | Swift |
|---|---|---|
| `Button` | Primary / Dark / Ghost | `SweatButton(style:)` |
| `Chip` | Off / On | `SweatChip(isOn:)` |
| `Selectable Card` | Off / On | `SelectableCard(isSelected:)` |
| `Score Button` | Off / On | `ScoreButton(isSelected:)` |
| `Text Field` | — | `SweatTextField` |
| `Info Card` | — | `InfoCard` |
| `Notice Card` | — | `NoticeCard` |
| `Stat Cell` | — | `StatCell` |
| `Factor Bar` | — | `FactorBar(ratio:)` |
| `Waypoint Row` | — | `WaypointRow` |
| `Segment Bar` | — | `SegmentBar(segments:)` |
| `Tab Bar` | Home / Map / Me | `SweatTabBar` |
| `Sweat Character` | Stage 1–6 | `SweatCharacter(stage:)` |
| `Weather Face` | Level 1–4 | `WeatherFace(level:)` |
| `Forecast Hour Cell` | — | `ForecastHourCell` |
| `Forecast Day Row` | — | `ForecastDayRow(range:)` |
| `List Row` | Menu / Setting | `SettingsRow(style:)` |
| `Location Header` | — | `LocationHeader` |
| `Search FAB` | — | `SearchFAB` |
| `iOS / Status Bar`, `iOS / Home Indicator` | — | 구현하지 않음 (OS 제공) |

---

## 토큰 매핑 규칙

Figma 변수 컬렉션 `Sweat App` → `DesignSystem` 패키지

```
ink/900          → Ink.n900
accent/base      → Accent.base
bg/surface       → Surface.card
stage/3-body     → StageColor.body(3)
radius/lg        → Radius.lg
space/4          → Space.x4
```

텍스트 스타일 `Body/15` → `SweatType.body15`

**자간** — Figma의 `-2%`는 SwiftUI에서 `.tracking(-0.02 * fontSize)`로 환산한다.

**한글 폰트** — SF Pro에 한글 글리프가 없어 시스템이 Apple SD Gothic Neo로 대체한다.
`Font.system`을 쓰면 자동 처리되므로 커스텀 폰트를 등록하지 않는다.

---

## 높이는 Figma를 따르지 않는다

**결정 2026-08-19** — SwiftUI 기본 조판을 따른다.

SwiftUI에는 Figma의 line-height에 대응하는 API가 없다. `lineSpacing`은 한 `Text`
안의 줄 사이에만 들어가므로 한 줄짜리 텍스트에는 효과가 없고, 그만큼 상자가 작다.
Selectable Card 기준 Figma 77.9pt 대 SwiftUI 70.7pt.

화면을 구현할 때 **Figma의 프레임 높이를 목표로 삼지 않는다.**
간격(`Space.*`)과 요소 순서를 맞추고, 높이는 콘텐츠가 정하게 둔다.
`.frame(height:)`로 Figma 값에 맞추면 Dynamic Type에서 글자가 먼저 잘린다.

---

## 알려진 제약

Figma 인스턴스는 하위 레이어 크기를 변경할 수 없다.
그래서 `Factor Bar`의 채움 폭과 `Forecast Day Row`의 범위 막대는
디자인 파일에서 detach된 상태다. **코드에서는 파라미터로 받는다** —
`FactorBar(ratio: 0.486)`, `ForecastDayRow(range: 26.8...35.8, bounds: 24.6...36.4)`

`06 지도`, `08 실내외 비율`의 지도는 양식화된 플레이스홀더다. 실제 지도가 아니다.
