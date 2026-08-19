# [000] 파운데이션 — 구현 계획

**스펙** `docs/specs/000-foundation/spec.md`
**브랜치** `000-foundation`
**작성** 2026-08-19

---

## 1. 접근

**패키지는 2개로 시작한다** — `SweatDomain`, `DesignSystem`.

`architecture.md` §4.2는 최종 6개 구성을 그리고 있지만, 이번 스펙에서 실제로 쓰이는 건 둘뿐이다.
`WeatherData`·`RouteData`·`SweatPersistence`·`SweatFeatures`는 002·003·005에서 처음 필요해진다.
빈 패키지를 미리 만들면 매니페스트 4개를 유지보수하면서 얻는 게 없다. 필요할 때 추가한다.
최종 구성은 그대로 유효하므로 아키텍처 문서는 고치지 않는다.

**토큰은 코드로 손수 쓴다. 빌드타임 코드젠을 넣지 않는다.**
Figma 변수는 자주 바뀌지 않고, 코드젠을 넣으면 툴체인 의존이 하나 늘어난다.
대신 `DesignSystem/README.md`에 Figma 변수명 ↔ Swift 심볼 매핑 표를 두고,
토큰이 바뀌면 표와 코드를 함께 고치는 것을 규칙으로 한다.

**컬러는 에셋 카탈로그가 아니라 코드 상수로 둔다.**
현재 디자인에 다크 모드가 없다. 에셋 카탈로그는 라이트/다크 두 벌이 있을 때 값을 하고,
지금은 패키지에서 `Bundle.module` 경유가 필요해지는 비용만 생긴다.
다크 모드를 도입하면 그때 카탈로그로 옮긴다.

**검토했지만 택하지 않은 것**
- Figma MCP로 토큰을 매번 읽어 생성 — 재현성이 낮고 네트워크에 의존한다
- SwiftGen/R.swift 도입 — 토큰 48개에 도구를 얹을 규모가 아니다
- 컴포넌트 19종 전부 구현 — 쓰이지 않는 컴포넌트는 검증할 화면이 없어 스펙만 커진다 (R8은 5종)

---

## 2. 헌법 점검

| 원칙 | 해당 | 준수 방법 |
|---|---|---|
| I. 도메인 순수성 | ✅ | `SweatDomain/Package.swift`의 `dependencies: []`. T032에서 매니페스트 검사 테스트 |
| II. 로직/문구 분리 | ✅ | 카피는 `SweatCopy`가 `SweatStage`에서 파생시킨다. 뷰는 카피를 주입받는다 |
| III. UX Writing | ✅ | T035에서 전 카피를 순회하며 금지 패턴 정규식 검사 |
| IV. 습도·풍속 | ✅ | `SweatStageEngine.stage(_:)` 시그니처에 습도·풍속을 **받지 않는다.** 구조적으로 불가능하게 만든다 |
| V. 경계값 단일 출처 | ✅ | `SweatStage.range`만이 경계를 안다. T032에서 리터럴 산재 검사 |
| VI. 기록 기반 보정 | ⬜ | 005에서. 이번엔 `calibration` 파라미터 자리만 만든다 |
| VII. 추정치 표기 | ⬜ | 003에서 |
| VIII. 디자인 토큰 | ✅ | 컴포넌트 5종이 토큰만 사용. T060에서 리터럴 검출 스크립트 |
| IX. 접근성 | ✅ | 컴포넌트마다 `accessibilityLabel`·Dynamic Type. T050~T054에 포함 |
| X. Swift 6 | ✅ | T010에서 `SWIFT_VERSION = 6.0`. 경고 0이 완료 조건 |
| XI. 스펙 우선 | ✅ | 이 문서가 그 증거 |

**위반 없음.**

---

## 3. 구조

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

## 4. 데이터 흐름

```
체감온도(℃) ─┐
민감도       ─┼─→ SweatStageEngine ─→ SweatStage ─→ SweatCopy ─→ 뷰
보정값       ─┘                          │
                                          └─→ Palette.stage(n) ─→ 마스코트 색
```

습도·풍속은 이 경로에 **들어오지 않는다** (헌법 IV). 002에서 설명 문구를 만들 때
`SweatCopy`와 나란히 놓이는 별도 타입(`EnvironmentNote`)으로 처리한다.

---

## 5. 액터 격리 방침

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

> ⚠️ **T011에서 확인할 것** — 로컬 SPM 패키지는 Xcode 프로젝트의 타깃 빌드 설정을
> 상속하지 않으므로, `SweatDomain`은 별도 조치 없이 nonisolated가 기본일 가능성이 높다.
> **추정하지 말고 T020에서 패키지를 만든 직후 빌드 로그의 `-default-isolation` 유무로 확인한다.**
> 만약 MainActor가 새어 들어오면, 매니페스트의 `swiftSettings`로 끄거나
> 모든 공개 타입에 `nonisolated`를 명시하는 방식으로 대체한다.

---

## 6. 외부 의존

| 의존 | 용도 | 실패 시 |
|---|---|---|
| 없음 | — | — |

이번 스펙은 네트워크·권한·서드파티 의존이 0이다. 그래서 전부 단위 테스트로 검증 가능하다.

---

## 7. 테스트 계획

| 대상 | 방식 | 케이스 |
|---|---|---|
| `SweatStageEngine` | 단위 (파라미터) | 경계값 10개: 27.9 / 28.0 / 32.9 / 33.0 / 34.9 / 35.0 / 35.9 / 36.0 / 42.9 / 43.0 |
| 민감도 오프셋 | 단위 | 동일 온도 × 3민감도 → 예상 단계 |
| 헌법 IV 회귀 | 단위 | 시그니처에 습도·풍속이 없음을 컴파일로 보장 + 문서화 테스트 |
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

허용 예외 — 5·6단계 안전 안내는 단정형을 허용한다 (헌법 III).
테스트는 안전 문구 필드를 별도로 취급한다.

### 체감온도 산식

**이번 스펙에서 산식을 구현하지 않는다.** 입력은 체감온도(℃)이고, 그 값을 만드는 책임은 002다.
스펙의 미해결 질문 1(산식 계수 검증)은 이 브랜치를 막지 않는다.

---

## 8. 리스크

| 리스크 | 영향 | 대응 |
|---|---|---|
| Swift 6 전환 시 경고 폭발 | 일정 지연 | 현재 소스가 템플릿 2파일뿐이라 실질 위험 낮음. 패키지 추가 **전에** 전환한다 |
| 패키지별 기본 격리 설정 실패 | 도메인이 MainActor에 묶임 | `nonisolated` 명시로 대체 (§5) |
| Figma 토큰 48개 수동 전사 오류 | 색이 미묘하게 다름 | 매핑 표에 hex를 함께 적고, 카탈로그 화면을 Figma와 나란히 대조 |
| 컴포넌트가 Figma와 미세하게 다름 | 화면 스펙에서 재작업 | 카탈로그 대조를 완료 조건에 포함. 스냅샷 도구는 도입하지 않음 (미해결 질문 3 → 보류) |
