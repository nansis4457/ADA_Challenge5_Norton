# [000] 파운데이션 — 태스크

**계획** `docs/specs/000-foundation/plan.md`
**브랜치** `000-foundation`

> 태스크 하나 = 커밋 하나. `[P]`는 병렬 가능(서로 다른 파일, 의존 없음).
> git 명령은 사람이 실행한다 (`docs/git-workflow.md` §0).

---

## 준비

- [x] T001 브랜치 `000-foundation` 생성
- [ ] T002 spec 상태를 Approved로 갱신, plan·tasks 커밋
      `docs(spec): 000 파운데이션 계획 및 태스크 확정`

## Swift 6 전환 — 패키지 추가 전에 먼저

- [ ] T010 `SWIFT_VERSION` 5.0 → 6.0, 빌드 경고 0 확인 **(R1)**
      `chore: Swift 6 언어 모드로 전환`
- [ ] T011 기본 액터 격리 방침 적용 — 앱·DesignSystem은 MainActor, SweatDomain은 nonisolated
      계획 §5의 확인 사항을 툴체인으로 검증하고, 결과를 plan.md에 반영한다
      `chore: 타깃별 기본 액터 격리 설정`

## 패키지 골격

- [ ] T020 `Packages/SweatDomain` 생성 + 프로젝트에 로컬 패키지로 링크 **(R2)**
      `chore(domain): SweatDomain 패키지 추가`
- [ ] T021 `Packages/DesignSystem` 생성 + 링크
      `chore(design-system): DesignSystem 패키지 추가`

## 도메인

- [ ] T030 `SweatStage` — 1~6단계, 경계 범위, 상태 라벨. **경계값은 여기에만 존재한다** **(R5)**
      `feat(domain): 땀 불편 6단계 정의 추가`
- [ ] T031 [P] `Sensitivity` + `SweatStageEngine.stage(apparentTemp:sensitivity:calibration:)` **(R3)**
      시그니처에 습도·풍속을 받지 않는다 **(R4)**
      `feat(domain): 체감온도 기반 단계 산출 엔진 추가`
- [ ] T032 [P] 경계값 전수 테스트 + 경계 리터럴 산재 검사 + 매니페스트 의존성 검사 **(R2, R3, R5)**
      `test(domain): 단계 경계값 및 도메인 순수성 검증`
- [ ] T033 [P] 극단값·민감도 조합 테스트
      `test(domain): 민감도 오프셋과 극단 입력 검증`
- [ ] T034 `SweatCopy` — 6단계 메인 멘트 + 추천 행동 (개발가이드 §2·§5) **(R9)**
      `feat(domain): 단계별 멘트와 추천 행동 카피 추가`
- [ ] T035 UX Writing 금지 패턴 린트 테스트 **(R10)**
      `test(domain): UX Writing 금지 표현 린트 추가`

## 디자인 토큰

- [ ] T040 `Color+Hex` + `Palette` 48색 **(R6)**
      `design(design-system): Figma 컬러 토큰 48개 추가`
- [ ] T041 [P] `SweatType` 텍스트 스타일 29개 **(R7)**
      자간은 `.tracking(-0.02 * size)`로 환산
      `design(design-system): 텍스트 스타일 29개 추가`
- [ ] T042 [P] `Layout` — Space · Radius
      `design(design-system): 스페이싱·라디우스 토큰 추가`
- [ ] T043 `DesignSystem/README.md` 매핑 표 (Figma 변수명 · hex · Swift 심볼)
      `docs(design-system): 토큰 매핑 표 추가`

## 컴포넌트 5종 — 각각 접근성 포함 (R8, IX)

- [ ] T050 `SweatButton` (Primary / Dark / Ghost)
      `design(design-system): Button 컴포넌트 추가`
- [ ] T051 [P] `SweatChip` (Off / On) — 선택 상태를 `accessibilityAddTraits(.isSelected)`로
      `design(design-system): Chip 컴포넌트 추가`
- [ ] T052 [P] `SelectableCard` (Off / On)
      `design(design-system): Selectable Card 컴포넌트 추가`
- [ ] T053 [P] `ScoreButton` (Off / On)
      `design(design-system): Score Button 컴포넌트 추가`
- [ ] T054 [P] `SweatTextField`
      `design(design-system): Text Field 컴포넌트 추가`
- [ ] T055 `ComponentCatalogView` + Preview — Figma 대조용
      `design(design-system): 컴포넌트 카탈로그 화면 추가`

## 린트

- [ ] T060 `Scripts/lint-tokens.sh` — 색상·폰트 리터럴 검출 (헌법 VIII)
      대상 경로는 Features가 생기는 001부터 확장한다
      `chore: 디자인 토큰 리터럴 검출 스크립트 추가`

## 마무리

- [ ] T090 헌법 점검 표 최종 확인 (plan.md §2)
- [ ] T091 빌드 경고 0 · 테스트 전체 통과
- [ ] T092 `docs/specs/README.md`의 000 상태를 Implemented로 갱신
- [ ] T093 PR 생성 — `docs/git-workflow.md` §3 템플릿

---

## 의존 관계

```
T010 → T011 → T020 ─→ T030 → T031 → T032
                │              └─→ T034 → T035
                └─ T021 ─→ T040 ─→ T050~T055
                            T041 ─┘
                            T042 ─┘
```

T010(Swift 6 전환)이 **가장 먼저**다. 패키지를 만든 뒤에 전환하면
매니페스트 3개에서 동시에 마이그레이션 오류를 처리해야 한다.

---

## 진행

| 날짜 | 완료 | 비고 |
|---|---|---|
| 2026-08-19 | T001 | |
