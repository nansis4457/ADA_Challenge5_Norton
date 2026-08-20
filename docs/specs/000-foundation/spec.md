# [000] 파운데이션 — 스펙

**상태** Approved
**브랜치** `000-foundation`
**작성** 2026-08-19

---

## 1. 문제

프로젝트가 Xcode 템플릿 상태다. `ContentView`는 "Hello, world!"이고,
Swift 언어 모드는 5.0, 패키지 구조도 디자인 토큰도 도메인 로직도 없다.

이 상태에서 화면부터 만들면 두 가지가 확정적으로 깨진다.

- 색상·폰트를 리터럴로 쓰게 되어 규칙 「색과 글꼴은 토큰으로」이 구조적으로 위반된다
- 등급 산출 로직이 뷰에 섞여 규칙 「문구는 뷰 밖에」를 되돌릴 수 없게 된다

## 2. 이 기능이 끝나면

001~005의 어떤 화면이든, **토큰과 도메인 타입만 조합하면** 만들 수 있다.
등급 산출은 시뮬레이터 없이 테스트로 검증되고, 구간 경계를 바꿔도 파일 하나만 고치면 된다.

사용자에게 보이는 변화는 없다. 이건 내부 기반 작업이다.

## 3. 사용자 시나리오

해당 없음 — 사용자 대면 기능이 아니다.
대신 **개발자 시나리오**로 검증한다.

```
Given  DesignSystem 패키지가 링크된 새 View
When   개발자가 SweatButton(style: .primary, title: "다음") 을 쓴다
Then   Figma의 Button/Primary와 픽셀 단위로 일치한다
```

```
Given  체감온도 34.2℃, 민감도 보통
When   SweatStageEngine.stage(...) 호출
Then   .three 를 반환한다
```

## 4. 요구사항

| ID | 요구사항 | 검증 방법 |
|---|---|---|
| R1 | Swift 언어 모드가 6.0이고, strict concurrency `complete`에서 경고 0으로 빌드된다 | `xcodebuild` 로그에 warning 없음 |
| R2 | `SweatDomain`은 `Foundation` 외 의존성이 없다 | 패키지 매니페스트 검사 |
| R3 | 체감온도·민감도·보정값을 넣으면 1~6단계를 반환한다 | 경계값 10개 전수 테스트 |
| R4 | 습도·풍속을 바꿔도 단계는 변하지 않는다 | 규칙 「습도·풍속을 단계에 두 번 세지 않는다」 회귀 테스트 |
| R5 | 구간 경계값이 코드 한 곳에만 존재한다 | `grep`으로 28/33/35/36/43 산재 없음 확인 |
| R6 | Figma 컬러 토큰 **35개**가 `DesignSystem`에 1:1로 존재한다 | 매핑 표와 대조 (48은 컬러가 아니라 변수 전체 개수였음 — T040에서 정정) |
| R7 | Figma 텍스트 스타일이 코드에 존재한다 (000 시점 29개, 001에서 `Stat/20` 추가로 30개) | 동일 |
| R8 | `design-source.md`의 컴포넌트 19개 중 **버튼·칩·카드·입력 5종**이 구현되어 Figma와 일치한다 | 스냅샷 비교 |
| R9 | 등급별 문구·추천이 도메인에서 나오고, 뷰에 문자열 리터럴이 없다 | 카피 린트 |
| R10 | 카피 전체에 규칙 「단정하지 않는다」 금지 패턴이 없다 | 정규식 린트 테스트 |

## 5. 화면

없음. 단, 구현한 컴포넌트를 눈으로 확인할 **카탈로그 화면**을 하나 만든다
(`ComponentCatalogView` — 디버그 빌드 전용, 릴리스에 포함하지 않음).

디자인 출처: `docs/design-source.md`

## 6. 문구

이 스펙에서 도메인에 정의하는 카피는 6단계 메인 멘트와 추천 행동이다.
원본은 `땀_날씨앱_구간화_UI_멘트_개발가이드.md` §2, §5.

| 단계 | 메인 멘트 |
|---|---|
| 1 | 오늘은 땀 걱정이 적어요 |
| 2 | 슬슬 땀이 날 수 있어요 |
| 3 | 오늘은 땀이 많이 날 수 있어요 |
| 4 | 오늘은 더위와 땀에 주의하세요 |
| 5 | 오늘은 더위가 매우 강해요 |
| 6 | 오늘은 야외 활동을 줄여주세요 |

추천 행동은 수분·복장·경로·휴식·안전 5개 카테고리에서 단계별로 2~3개.

## 7. 범위 밖

- 날씨 API 연동 → 002
- 나머지 컴포넌트 14종 → 각 화면 스펙에서 필요할 때
- 마스코트 `Shape` 구현 → 002 (홈에서 처음 쓰임)
- SwiftData 스키마 → 005

## 8. 미해결 질문

- [ ] **체감온도 산식 계수 검증** — `architecture.md` §5.4
      *이 브랜치를 막지 않는다.* 산식 구현은 002 담당이고, 이 스펙의 엔진은 체감온도를
      **입력으로 받는다** (spec.md §7). 다만 R3 테스트의 `34.2℃ → 3단계`는 검증 전까지 가정이다.
- [ ] **보정값의 단위가 규칙과 어긋난다** *(T031에서 발견)*
      규칙 「기록이 예측을 고친다」는 보정 폭을 `±1.5`**단계**로 규정하는데, `SweatStageEngine`의
      `calibration` 파라미터는 **℃**다. 단계 폭이 구간마다 달라(28~33℃는 5℃,
      35~36℃는 1℃) 1:1 환산이 안 된다. 현재 `calibrationLimit = 3.0℃`는
      **근거 없는 잠정치**다. 셋 중 하나를 골라야 한다.
      1. 보정을 ℃로 유지 → 규칙 「기록이 예측을 고친다」를 ℃ 기준으로 개정
      2. 보정을 단계 단위로 → 엔진이 단계 인덱스를 직접 이동
      3. `CalibrationEngine`(005)이 단계 오차를 ℃로 환산 → 환산 규칙을 정의
      **005 착수 전까지 결정한다.** 이 브랜치는 막지 않는다.

- [x] ~~줄높이 근사가 단일 행 텍스트에는 적용되지 않는다~~ → **①번으로 결정 (2026-08-19)**
      **SwiftUI 기본 조판을 따른다.** Figma의 높이 값은 참고값으로 강등한다.
      Selectable Card 기준 카드당 약 7pt 차이가 나고 세로로 누적되지만, 그대로 둔다.

      다른 두 안을 버린 이유 — `.frame(height:)` 고정은 Dynamic Type에서 글자가
      먼저 잘린다. 접근성을 픽셀 정합성과 맞바꾸는 셈이다. 패딩으로 line-height
      상자를 흉내내는 방식은 폰트 기본 줄높이를 정확히 알아야 하는데, 그 값은
      SwiftUI가 공개하지 않아 추정에 의존하게 된다.

      **따르는 규칙** — 화면 구현에서 Figma의 프레임 높이를 목표로 삼지 않는다.
      간격(`Space.*`)과 순서를 맞추고, 높이는 콘텐츠가 정하게 둔다.

- [x] ~~Figma 컴포넌트가 space 토큰 밖의 값을 쓴다~~ → **토큰으로 정렬 (2026-08-19)**

      | 컴포넌트 | 현재 → 토큰 | 결과 |
      |---|---|---|
      | Button 좌우 | 20 → 22 (`space/5`) | 변화 없음 (전체폭 중앙정렬) |
      | Score Button 상하 | 18 → 16 (`space/4`) | 높이 60 → 56 |
      | Text Field | 14/15 → 16 (`space/4`) | 높이 50 → 54 |
      | **Chip 상하** | **9 유지** | 토큰으로 낮추면 8이 되어 터치 타깃이 더 나빠진다 |

      Chip만 예외다. 아래 터치 타깃 결정과 충돌하므로 시각 여백을 건드리지 않는다.
      Figma도 함께 고친다. 정렬이 끝나면 `lint-tokens.sh`의 간격·반경 검사를
      경고에서 오류로 올릴 수 있다.

- [x] ~~Chip의 터치 영역이 44pt 미만이다~~ → **시각 유지, 프레임만 44pt (2026-08-19)**
      상하 여백 9를 그대로 두고 버튼 프레임의 최소 높이만 44pt로 준다.
      보기에는 37pt 칩이고 탭 영역은 44pt다.

      다른 두 안을 버린 이유 — 여백을 16으로 키우면 높이가 50pt가 되어 칩이
      눈에 띄게 두꺼워진다(디자인 변경). 12로는 41.9pt라 여전히 미달이다.
      그대로 두는 것은 HIG 위반이라 선택지가 아니다.

      **대가** — 칩 행 높이가 7pt 늘어난다. 앱 전체에 칩 행이 두 곳뿐이라
      누적 14pt다. 받아들인다.

- [x] ~~패키지를 6개로 처음부터 나눌지~~ → **2개(`SweatDomain`, `DesignSystem`)로 시작.** 나머지는 실제로 쓰이는 스펙에서 추가한다 (spec.md §1)
- [x] ~~컴포넌트 스냅샷 테스트 도구 도입~~ → **보류.** 이번엔 카탈로그 화면 육안 대조로 갈음한다 (spec.md §8)

## 9. 완료 조건

- [x] R1~R10 전부 검증됨 *(R6의 "48개"는 35개로 정정)*
- [x] 카탈로그 화면에서 5종 컴포넌트가 Figma와 일치
      — 색상·테두리·반경·굵기·선택 상태 일치. **높이는 카드당 약 7pt 차이** (미해결 §8)
- [x] 접근성: VoiceOver 라벨, 선택 상태, Dynamic Type 대응 완료
      — **Chip 터치 타깃 37pt는 미결** (미해결 §8)
- [x] 규칙 「도메인은 순수하게」·II·III·IV·V·VIII·X 위반 없음 — 전부 코드·테스트로 강제
- [x] `docs/specs/README.md`의 000 상태를 `Implemented`로 갱신

### 최종 검증 (2026-08-19)

| | 결과 |
|---|---|
| 토큰 린트 | 통과 |
| 도메인 테스트 | 24개 통과 |
| 앱 빌드 Debug | 성공 · 경고 0 |
| 앱 빌드 Release | 성공 · 경고 0 |

### 001로 넘기는 결정 사항

이 스펙은 완료되지만, 다음 셋은 **001 착수 전에 정해야 한다.** §8 참조.

1. 줄높이 처리 방식 — 화면 레이아웃 전체가 의존
2. 토큰 밖 여백 (20·9·18·14·15)
3. Chip 터치 타깃 37pt

---

# 구현 계획

> 여기서부터는 *어떻게*다. 위쪽은 *무엇을·왜*.

## 10. 규칙 점검

| 규칙 | 해당 | 지키는 방법 |
|---|---|---|
| 도메인은 순수하게 | ✅ | `SweatDomain/Package.swift`의 `dependencies: []`. T032에서 매니페스트 검사 테스트 |
| 문구는 뷰 밖에 | ✅ | 카피는 `SweatCopy`가 `SweatStage`에서 파생시킨다. 뷰는 카피를 주입받는다 |
| 단정하지 않는다 | ✅ | T035에서 전 카피를 순회하며 금지 패턴 정규식 검사 |
| 습도·풍속을 단계에 두 번 세지 않는다 | ✅ | `SweatStageEngine.stage(_:)` 시그니처에 습도·풍속을 **받지 않는다.** 구조적으로 불가능하게 만든다 |
| 경계값은 한 곳에 | ✅ | `SweatStage.range`만이 경계를 안다. T032에서 리터럴 산재 검사 |
| 기록이 예측을 고친다 | ⬜ | 005에서. 이번엔 `calibration` 파라미터 자리만 만든다 |
| 추정치는 추정치로 | ⬜ | 003에서 |
| 색과 글꼴은 토큰으로 | ✅ | 컴포넌트 5종이 토큰만 사용. T060에서 리터럴 검출 스크립트 |
| 접근성은 마감이 아니다 | ⚠️ | VoiceOver 라벨·선택 상태·Dynamic Type은 전부 넣었다. **다만 Chip의 터치 타깃이 37pt로 HIG 최소 44pt에 미달한다.** 시각 크기와 행 높이에 영향이 있어 디자인 결정이 필요하다 (spec.md 미해결) |
| Swift 6 | ✅ | T010에서 `SWIFT_VERSION = 6.0`. 경고 0이 완료 조건 |

**최종 확인 (T090, 2026-08-19)**

강제 방식이 문서가 아니라 **코드와 테스트**인 것들:

| 원칙 | 무엇이 막아주나 |
|---|---|
| I | `dependencies: []` + 매니페스트·import 검사 테스트 |
| III | 금지 패턴 린트 테스트 (역검증 완료) |
| IV | `stage()` 시그니처에 습도·풍속이 없음 — 위반이 컴파일되지 않는다 |
| V | 경계값 산재 검사 테스트 (역검증 완료) |
| VIII | `Scripts/lint-tokens.sh` (역검증 완료) |
| X | 빌드 경고 0 |

**위반 없음. 단, IX는 Chip 터치 타깃 결정이 남아 있다.**

---

## 11. 구조

```
ADA_Challenge5_Norton/
├── Packages/
│   ├── SweatDomain/
│   │   ├── Package.swift              dependencies: []
│   │   ├── Sources/SweatDomain/
│   │   │   ├── SweatStage.swift       경계값 단일 출처
│   │   │   ├── Sensitivity.swift
│   │   │   ├── SweatStageEngine.swift
│   │   │   └── SweatCopy.swift        멘트 · 추천
│   │   └── Tests/SweatDomainTests/
│   │       ├── SweatStageEngineTests.swift
│   │       └── SweatCopyLintTests.swift
│   └── DesignSystem/
│       ├── Package.swift
│       ├── README.md                  Figma ↔ Swift 매핑 표
│       └── Sources/DesignSystem/
│           ├── Tokens/
│           │   ├── Color+Hex.swift
│           │   ├── Palette.swift      48색
│           │   ├── SweatType.swift    29 스타일
│           │   └── Layout.swift       Space · Radius
│           └── Components/
│               ├── SweatButton.swift
│               ├── SweatChip.swift
│               ├── SelectableCard.swift
│               ├── ScoreButton.swift
│               ├── SweatTextField.swift
│               └── ComponentCatalogView.swift
├── Scripts/
│   └── lint-tokens.sh                 색상·폰트 리터럴 검출
├── ADA_Challenge5_Norton.xcodeproj
└── ADA_Challenge5_Norton/             앱 타깃
```

| 타입 | 책임 | 레이어 |
|---|---|---|
| `SweatStage` | 1~6단계 + 경계 범위 + 상태 라벨 | Domain |
| `Sensitivity` | 개인 민감도 → 온도 오프셋 | Domain |
| `SweatStageEngine` | 체감온도 → 단계 | Domain |
| `SweatCopy` | 단계 → 메인 멘트 · 추천 행동 | Domain |
| `Palette` / `SweatType` / `Layout` | Figma 토큰 | DesignSystem |
| 컴포넌트 5종 | Figma 컴포넌트 미러 | DesignSystem |

---

## 12. 데이터 흐름

```
체감온도(℃) ─┐
민감도       ─┼─→ SweatStageEngine ─→ SweatStage ─→ SweatCopy ─→ 뷰
보정값       ─┘                          │
                                          └─→ Palette.stage(n) ─→ 마스코트 색
```

습도·풍속은 이 경로에 **들어오지 않는다** (규칙 「습도·풍속을 단계에 두 번 세지 않는다」). 002에서 설명 문구를 만들 때
`SweatCopy`와 나란히 놓이는 별도 타입(`EnvironmentNote`)으로 처리한다.

---

## 13. 액터 격리 방침

Xcode 26의 `SWIFT_APPROACHABLE_CONCURRENCY`가 이미 켜져 있다.
앱 타깃과 `DesignSystem`은 **기본 `@MainActor` 격리**가 편하다 — 전부 UI다.
그러나 `SweatDomain`은 반대다. 순수 계산이 `@MainActor`에 묶이면
`actor` Repository(002~)에서 호출할 때마다 `await`가 붙고, 테스트도 메인 스레드에 갇힌다.

**방침**
- 앱 타깃 · `DesignSystem` → 기본 격리 `MainActor`
- `SweatDomain` → 기본 격리 없음(`nonisolated`). 모든 공개 타입은 `Sendable`

### T010에서 확인된 사실 (빌드 로그 실측)

앱 타깃에 이미 다음이 걸려 있고, 실제 컴파일러 플래그로 전달되는 것을 확인했다.

| 빌드 설정 | 전달된 플래그 |
|---|---|
| `SWIFT_VERSION = 6.0` | `-swift-version 6` |
| `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` | `-default-isolation=MainActor` |
| `SWIFT_APPROACHABLE_CONCURRENCY = YES` | `-enable-upcoming-feature NonisolatedNonsendingByDefault`, `-enable-upcoming-feature InferIsolatedConformances` |

`SWIFT_STRICT_CONCURRENCY = complete`는 별도 플래그로 나타나지 않는다.
Swift 6 언어 모드에서 완전 검사가 기본이라 중복이기 때문이다.
그럼에도 명시해 둔 이유는, 누군가 언어 모드를 5로 되돌려도 안전망이 남게 하기 위함이다.

### T011 결론 (빌드 로그 실측, 2026-08-19)

로컬 SPM 패키지는 Xcode 타깃의 빌드 설정을 **상속하지 않는다.** 확인된 결과는 다음과 같다.

| 대상 | `-default-isolation` | 결과 |
|---|---|---|
| 앱 타깃 | `MainActor` | 빌드 설정에서 상속 |
| `DesignSystem` | `MainActor` | 매니페스트에 `.defaultIsolation(MainActor.self)` **명시 필요** |
| `SweatDomain` | 없음 | 조치 없이 nonisolated가 기본 — 원하던 대로 |

따라서 도메인에 `nonisolated`를 일일이 붙이는 대체안은 필요하지 않다.
`DesignSystem`만 매니페스트에서 명시하면 된다.

확인 방법 (재현용):

```bash
cd Packages/<패키지> && rm -rf .build && swift build --verbose 2>&1 | grep default-isolation
```

---

## 14. 외부 의존

| 의존 | 용도 | 실패 시 |
|---|---|---|
| 없음 | — | — |

이번 스펙은 네트워크·권한·서드파티 의존이 0이다. 그래서 전부 단위 테스트로 검증 가능하다.

---

## 15. 테스트 계획

| 대상 | 방식 | 케이스 |
|---|---|---|
| `SweatStageEngine` | 단위 (파라미터) | 경계값 10개: 27.9 / 28.0 / 32.9 / 33.0 / 34.9 / 35.0 / 35.9 / 36.0 / 42.9 / 43.0 |
| 민감도 오프셋 | 단위 | 동일 온도 × 3민감도 → 예상 단계 |
| 규칙 「습도·풍속을 단계에 두 번 세지 않는다」 회귀 | 단위 | 시그니처에 습도·풍속이 없음을 컴파일로 보장 + 문서화 테스트 |
| 극단값 | 단위 | -50℃ / 100℃ / NaN 입력 시 크래시 없음 |
| `SweatCopy` | 단위 | 6단계 전부 멘트·추천이 비어 있지 않음 |
| UX Writing | 단위 (린트) | 전 카피에 금지 패턴 부재 — 아래 참조 |
| 디자인 토큰 | 스크립트 | Features 소스에 색상·폰트 리터럴 부재 |
| 컴포넌트 | 수동 (카탈로그) | Figma와 나란히 눈으로 대조 |

### UX Writing 금지 패턴

```
\d+\s*(mL|ml|리터|L)      분비량 수치
\d+\s*배                   배수 표현
땀\s*(매우\s*)?많음         단정형 상태 표기
= *땀                      등식 표현
```

허용 예외 — 5·6단계 안전 안내는 단정형을 허용한다 (규칙 「단정하지 않는다」).
테스트는 안전 문구 필드를 별도로 취급한다.

### 체감온도 산식

**이번 스펙에서 산식을 구현하지 않는다.** 입력은 체감온도(℃)이고, 그 값을 만드는 책임은 002다.
스펙의 미해결 질문 1(산식 계수 검증)은 이 브랜치를 막지 않는다.

---

## 16. 리스크

| 리스크 | 영향 | 대응 |
|---|---|---|
| Swift 6 전환 시 경고 폭발 | 일정 지연 | 현재 소스가 템플릿 2파일뿐이라 실질 위험 낮음. 패키지 추가 **전에** 전환한다 |
| 패키지별 기본 격리 설정 실패 | 도메인이 MainActor에 묶임 | `nonisolated` 명시로 대체 (§5) |
| Figma 토큰 48개 수동 전사 오류 | 색이 미묘하게 다름 | 매핑 표에 hex를 함께 적고, 카탈로그 화면을 Figma와 나란히 대조 |
| 컴포넌트가 Figma와 미세하게 다름 | 화면 스펙에서 재작업 | 카탈로그 대조를 완료 조건에 포함. 스냅샷 도구는 도입하지 않음 (미해결 질문 3 → 보류) |
