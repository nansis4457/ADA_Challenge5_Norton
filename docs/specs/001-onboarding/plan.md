# [001] 온보딩 — 구현 계획

**스펙** `docs/specs/001-onboarding/spec.md`
**브랜치** `001-onboarding`
**작성** 2026-08-19

---

## 1. 접근

### 패키지 둘을 새로 만든다

`architecture.md` §4.2가 그린 6개 중 두 개를 이번에 세운다.

| 패키지 | 이유 |
|---|---|
| `SweatFeatures` | 화면이 처음 생긴다. 앱 타깃에 두면 "얇게 유지"가 첫 화면부터 무너지고, `lint-tokens.sh`의 대상 경로도 앱 타깃 전체가 된다 |
| `SweatPersistence` | 프로필 저장이 필요하다. 도메인에 넣으면 순수성이 깨지고(§헌법 I의 취지), 피처에 넣으면 005에서 옮겨야 한다 |

`UserDefaults`는 `Foundation`이라 문자로는 도메인에 넣어도 헌법 I 위반이 아니다.
그러나 도메인은 **부수효과 없이 테스트 가능해야** 한다는 게 원칙의 취지다. I/O는 밖으로 뺀다.

### 프로필은 키-값, 기록은 SwiftData

이번엔 프로필만 만든다. `SweatPersistence`가 `UserDefaults`를 감싼 `ProfileStore`를 갖는다.
005에서 SwiftData 기반 `LogStore`가 같은 패키지에 추가된다. 마이그레이션은 없다.

### 문구는 뷰 밖에 둔다

`SweatCopy`는 **단계 관련** 문구의 출처다. 온보딩 문구는 단계와 무관한 UI 텍스트이므로
`SweatFeatures`의 `OnboardingCopy`에 따로 모은다. 헌법 II는 "뷰에 문자열 리터럴 금지"이지
"모든 문구를 도메인에 넣으라"가 아니다.

String Catalog은 쓰지 않는다. 뷰의 리터럴을 자동 추출하는 방식이라
뷰에 리터럴을 두도록 **부추긴다.** 현지화가 실제 요구가 되면 그때 이 enum을 감싼다.

### 홈이 없으므로 자리표시자를 둔다

R4(민감도가 등급 계산에 반영된다)를 눈으로 확인하려면 결과를 보여줄 화면이 필요한데
홈은 002다. 온보딩 완료 후 **계산된 단계와 문구만 표시하는 임시 화면**을 둔다.
002가 이 화면을 대체한다.

### 검토했지만 택하지 않은 것

- **앱 타깃에 화면 두기** — 지금은 편하지만 001~005 내내 앱 타깃이 비대해진다
- **온보딩 중간 저장** — 3단계짜리 흐름에 재개 로직을 넣을 이유가 없다 (스펙 §3)
- **String Catalog** — 위 참조

---

## 2. 헌법 점검

| 원칙 | 해당 | 준수 방법 |
|---|---|---|
| I. 도메인 순수성 | ✅ | `Transport`·`OutdoorDuration`은 순수 enum. 저장은 `SweatPersistence`가 맡는다 |
| II. 로직/문구 분리 | ✅ | `OnboardingCopy`. 뷰에 리터럴 없음 — T060 린트가 검사 |
| III. UX Writing | ✅ | 온보딩 문구에도 000의 금지 패턴 테스트를 적용 |
| IV. 습도·풍속 | — | 해당 없음 |
| V. 경계값 단일 출처 | — | 해당 없음 |
| VI. 기록 기반 보정 | ⬜ | 005. `calibrationOffset` 자리만 프로필에 만든다 |
| VII. 추정치 표기 | — | 해당 없음 |
| VIII. 디자인 토큰 | ✅ | `lint-tokens.sh` 대상에 `SweatFeatures` 추가 |
| IX. 접근성 | ✅ | 선택 상태·Dynamic Type. Chip 프레임 44pt는 000 결정을 여기서 적용 |
| X. Swift 6 | ✅ | 새 패키지 둘 다 언어 모드 6. `SweatFeatures`는 MainActor 기본 |
| XI. 스펙 우선 | ✅ | 이 문서 |

**위반 없음.**

---

## 3. 구조

```
Packages/
├── SweatDomain/Sources/SweatDomain/
│   ├── Transport.swift              도보 · 지하철 · 버스 · 자전거
│   └── OutdoorDuration.swift        20분 이하 · 20~40분 · 40분 이상
├── SweatPersistence/                신설
│   ├── Package.swift                의존: SweatDomain
│   └── Sources/SweatPersistence/
│       ├── UserProfile.swift        Codable 스칼라 묶음
│       └── ProfileStore.swift       UserDefaults 래퍼
└── SweatFeatures/                   신설
    ├── Package.swift                의존: SweatDomain · SweatPersistence · DesignSystem
    └── Sources/SweatFeatures/
        ├── RootView.swift           온보딩 ↔ 홈 분기
        ├── Onboarding/
        │   ├── OnboardingFlow.swift 3단계 진행 · 편집 모드
        │   ├── SensitivityStep.swift
        │   ├── TransportStep.swift
        │   ├── NotificationStep.swift
        │   ├── OnboardingCopy.swift
        │   └── NotificationPermission.swift
        └── Home/
            └── StagePlaceholderView.swift   002가 대체
```

| 타입 | 책임 | 레이어 |
|---|---|---|
| `Transport` · `OutdoorDuration` | 안정적 코드값 + 표시용 키 | Domain |
| `UserProfile` | 저장되는 스칼라 묶음 | Persistence |
| `ProfileStore` | 읽기·쓰기·기본값·손상 복구 | Persistence |
| `OnboardingFlow` | 단계 진행, 모드(최초/편집) | Feature |
| `NotificationPermission` | 권한 요청 래퍼 | Feature |

---

## 4. 데이터 흐름

```
온보딩 선택
   ↓
UserProfile (Codable)
   ↓  ProfileStore.save
UserDefaults
   ↓  ProfileStore.load          앱 실행 시
UserProfile
   ↓
SweatStageEngine.stage(체감온도, profile.sensitivity, profile.calibrationOffset)
   ↓
SweatStage → SweatCopy → 화면
```

`transport`·`outdoorDuration`은 이번에 **저장만** 된다. 소비는 003이다.
저장해두지 않으면 003에서 다시 물어봐야 한다.

---

## 5. 모드 두 가지

`OnboardingFlow`는 진입 방식에 따라 다르게 동작한다.

| | 최초 실행 | 마이페이지에서 편집 |
|---|---|---|
| 시작 단계 | 1단계 | 지정된 단계 하나 |
| 뒤로가기 | 없음 | `← 마이페이지` |
| CTA | `다음` → 다음 단계 | `저장` → 즉시 종료 |
| 3단계(알림) | 포함 | **건너뜀** |
| 탭 바 | 없음 | 있음 |
| 끝난 뒤 | 홈 | 마이페이지 |

마이페이지가 005에 생기므로, 이번에는 **자리표시자 화면에 편집 진입 버튼**을 둬서
R8~R11을 검증한다. 005가 진짜 진입점을 연결한다.

---

## 6. 외부 의존

| 의존 | 용도 | 실패 시 |
|---|---|---|
| 알림 권한 요청 | 3단계 | 거부돼도 온보딩은 완료된다 (R6) |
| 키-값 저장 | 프로필 | 손상되면 기본값으로 시작 (§7) |

위치 권한은 002다. 이번에 건드리지 않는다.

---

## 7. 테스트 계획

| 대상 | 방식 | 케이스 |
|---|---|---|
| `Transport`·`OutdoorDuration` | 단위 | `rawValue` 고정 — 바뀌면 저장된 데이터가 깨진다 |
| `ProfileStore` | 단위 | 왕복 저장, 빈 저장소 기본값, **손상된 데이터 복구** |
| 기본값 | 단위 | 보통 · 지하철 · 20~40분 (R5) |
| 온보딩 문구 | 단위 | 000의 금지 패턴 린트를 온보딩 카피에도 적용 (R14) |
| 흐름 | 수동 | 최초/편집 두 경로, 권한 허용·거부 (R1·R2·R6~R11) |
| 접근성 | 수동 | VoiceOver 선택 상태, `AX5`에서 잘림 (R12·R13) |

`ProfileStore` 테스트는 실제 `UserDefaults`를 건드리지 않도록 **별도 suite name**을 쓴다.

### 손상 데이터

디코딩에 실패하면 기본 프로필로 시작한다. 크래시하지 않는다.
저장 포맷이 바뀔 001 이후를 대비한 최소한의 방어다.

---

## 8. 000에서 넘어온 결정 적용

| | 적용 위치 |
|---|---|
| 줄높이는 SwiftUI 기본을 따른다 | 화면 전부. Figma 높이를 목표로 삼지 않는다 |
| Chip 프레임 최소 높이 44pt | `SweatChip` 수정 (2단계에서 처음 쓰인다) |
| Button·Score·TextField 여백 토큰 정렬 | 컴포넌트 수정 + Figma 반영 |

컴포넌트 수정은 `DesignSystem` 변경이라 001 범위지만 000의 결과물을 건드린다.
**커밋을 분리해서** 무엇이 결정 적용이고 무엇이 신규 기능인지 구분한다.

---

## 9. 리스크

| 리스크 | 영향 | 대응 |
|---|---|---|
| `rawValue`를 나중에 바꾸면 저장 데이터가 깨진다 | 사용자 설정 유실 | 테스트로 고정. 변경 시 마이그레이션 필수임을 주석에 명시 |
| 마이페이지(005)가 없어 편집 경로 검증이 인위적 | 실사용과 다를 수 있음 | 자리표시자에 진입 버튼. 005에서 재검증 |
| 알림 권한은 한 번 거부하면 재현이 번거롭다 | 테스트 반복 어려움 | 시뮬레이터 데이터 초기화 절차를 tasks에 명시 |
| 패키지 둘을 한 번에 추가 | 빌드 설정 실수 | 000의 링크 절차를 그대로 따르고 빌드로 확인 |
