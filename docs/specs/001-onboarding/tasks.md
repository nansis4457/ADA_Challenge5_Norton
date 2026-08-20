# [001] 온보딩 — 태스크

**계획** `docs/specs/001-onboarding/spec.md`
**브랜치** `001-onboarding`

> 태스크 하나 = 커밋 하나. `[P]`는 병렬 가능.
> git 명령은 사람이 실행한다 (`docs/git-workflow.md` §0).

---

## 준비

- [ ] T001 브랜치 `001-onboarding` 생성 (`main` 머지 후)
- [ ] T002 spec 상태를 Approved로, plan·tasks 커밋
      `docs(spec): 001 온보딩 계획 및 태스크 확정`

## 000 결정 적용 — 신규 기능과 섞지 않는다

- [x] T010 Chip 프레임 최소 높이 44pt (시각 여백 9는 유지)
      `design(design-system): Chip 터치 타깃을 44pt로 확장`
- [ ] T011 Button 22 · Score 16 · TextField 16 여백을 토큰으로 정렬
      `design(design-system): 컴포넌트 여백을 space 토큰으로 정렬`
- [ ] T012 Figma 컴포넌트를 T010·T011에 맞춰 수정
      `design: Figma 컴포넌트 여백을 코드와 일치시킴` *(코드 변경 없음, 문서만)*

## 도메인

- [ ] T020 [P] `Transport` — 도보·지하철·버스·자전거
      `feat(domain): 이동수단 타입 추가`
- [ ] T021 [P] `OutdoorDuration` — 20분 이하·20~40분·40분 이상
      `feat(domain): 야외 이동시간 타입 추가`
- [ ] T022 `rawValue` 고정 테스트 — 바뀌면 저장 데이터가 깨진다
      `test(domain): 저장 식별자 안정성 검증`

## 영속화

- [ ] T030 `SweatPersistence` 패키지 생성 + 링크 (의존: SweatDomain)
      `chore(persistence): SweatPersistence 패키지 추가`
- [ ] T031 `UserProfile` — Codable 스칼라 묶음, 기본값 포함
      `feat(persistence): 사용자 프로필 모델 추가`
- [ ] T032 `ProfileStore` — 읽기·쓰기·기본값·손상 복구
      `feat(persistence): 키-값 프로필 저장소 추가`
- [ ] T033 저장소 테스트 — 왕복, 빈 저장소, **손상 데이터** **(R3, R5)**
      별도 suite name을 써서 실제 UserDefaults를 건드리지 않는다
      `test(persistence): 프로필 저장소 왕복 및 손상 복구 검증`

## 피처 골격

- [ ] T040 `SweatFeatures` 패키지 생성 + 링크, MainActor 기본
      `chore(features): SweatFeatures 패키지 추가`
- [ ] T041 `lint-tokens.sh` 대상에 SweatFeatures 추가 (규칙 「색과 글꼴은 토큰으로」)
      `chore: 린트 대상에 SweatFeatures 추가`
- [ ] T042 `OnboardingCopy` — 스펙 §6의 문구 전부
      `feat(onboarding): 온보딩 문구 정의 추가`
- [ ] T043 온보딩 문구에 UX Writing 린트 적용 **(R14)**
      `test(onboarding): 온보딩 문구 금지 표현 검사`

## 화면

- [ ] T050 `SensitivityStep` — 3지선다 **(R5, R12)**
      `feat(onboarding): 땀 민감도 선택 화면 추가`
- [ ] T051 `TransportStep` — 이동수단 4 + 이동시간 3 **(R5, R12)**
      `feat(onboarding): 이동 패턴 선택 화면 추가`
- [ ] T052 `NotificationStep` + 권한 요청 **(R6, R7)**
      `feat(onboarding): 알림 권한 화면 추가`
- [ ] T053 `OnboardingFlow` — 단계 진행, 최초/편집 모드 **(R8~R11)**
      `feat(onboarding): 온보딩 흐름과 편집 모드 추가`
- [ ] T054 `RootView` — 온보딩 완료 여부로 분기 **(R1, R2)**
      `feat(onboarding): 최초 실행 분기 추가`
- [ ] T055 `StagePlaceholderView` — 계산된 단계 표시 **(R4)**. 002가 대체
      편집 진입 버튼을 둬서 R8~R11을 검증한다
      `feat: 등급 확인용 임시 화면 추가`

## 마무리

- [ ] T090 접근성 확인 — VoiceOver 선택 상태, `AX5` 잘림 **(R12, R13)**
- [ ] T091 흐름 수동 검증 — 최초/편집, 권한 허용·거부
      시뮬레이터 데이터 초기화: `xcrun simctl privacy <UDID> reset all <bundle-id>`
- [ ] T092 린트·테스트·Debug/Release 빌드
- [ ] T093 규칙 점검 표 최종 확인 (spec.md §2)
- [ ] T094 `docs/specs/README.md`의 001 상태 갱신
- [ ] T095 PR 생성

---

## 의존 관계

```
T010~T012 (000 결정 적용) ─── 독립. 먼저 끝내고 섞지 않는다
                    │
T020 ─┬─ T022       │
T021 ─┘             │
  │                 │
  └─→ T030 → T031 → T032 → T033
                       │
                       └─→ T040 → T041
                              └─→ T042 → T043
                                     └─→ T050 ─┐
                                        T051 ─┼─→ T053 → T054 → T055
                                        T052 ─┘
```

**T010~T012를 먼저** 하는 이유 — 000의 결정을 적용하는 작업이라 신규 기능과
성격이 다르다. 섞으면 리뷰에서 "이 여백 변경이 온보딩 때문인가 결정 때문인가"를
가릴 수 없다.

**T041(린트 대상 추가)을 화면보다 먼저** 하는 이유 — 나중에 추가하면 이미 쌓인
리터럴을 한꺼번에 고쳐야 한다.

---

## 진행

| 날짜 | 완료 | 비고 |
|---|---|---|
| 2026-08-20 | T010 | 시각 37pt 유지, 탭 44pt. 칩 행 높이 +7pt |
