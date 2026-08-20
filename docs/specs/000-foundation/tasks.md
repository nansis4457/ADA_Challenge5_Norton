# [000] 파운데이션 — 태스크

**계획** `docs/specs/000-foundation/spec.md`
**브랜치** `000-foundation`

> 태스크 하나 = 커밋 하나. `[P]`는 병렬 가능(서로 다른 파일, 의존 없음).
> git 명령은 사람이 실행한다 (`docs/git-workflow.md` §0).

---

## 준비

- [x] T001 브랜치 `000-foundation` 생성
- [x] T002 spec 상태를 Approved로 갱신, plan·tasks 커밋
      `docs(spec): 000 파운데이션 계획 및 태스크 확정`

## Swift 6 전환 — 패키지 추가 전에 먼저

- [x] T010 `SWIFT_VERSION` 5.0 → 6.0, 빌드 경고 0 확인 **(R1)**
      `chore: Swift 6 언어 모드로 전환`
- [x] T011 기본 액터 격리 방침 적용 — 앱·DesignSystem은 MainActor, SweatDomain은 nonisolated
      계획 §5의 확인 사항을 툴체인으로 검증하고, 결과를 스펙의 구현 계획에 반영한다
      `chore: 타깃별 기본 액터 격리 설정`

## 패키지 골격

- [x] T020 `Packages/SweatDomain` 생성 + 프로젝트에 로컬 패키지로 링크 **(R2)**
      `chore(domain): SweatDomain 패키지 추가`
- [x] T021 `Packages/DesignSystem` 생성 + 링크
      `chore(design-system): DesignSystem 패키지 추가`

## 도메인

- [x] T030 `SweatStage` — 1~6단계, 경계 범위, 상태 라벨. **경계값은 여기에만 존재한다** **(R5)**
      `feat(domain): 땀 불편 6단계 정의 추가`
- [x] T031 [P] `Sensitivity` + `SweatStageEngine.stage(apparentTemp:sensitivity:calibration:)` **(R3)**
      시그니처에 습도·풍속을 받지 않는다 **(R4)**
      `feat(domain): 체감온도 기반 단계 산출 엔진 추가`
- [x] T032 [P] 경계값 전수 테스트 + 경계 리터럴 산재 검사 + 매니페스트 의존성 검사 **(R2, R3, R5)**
      `test(domain): 단계 경계값 및 도메인 순수성 검증`
- [x] T033 [P] 극단값·민감도 조합 테스트
      `test(domain): 민감도 오프셋과 극단 입력 검증`
- [x] T034 `SweatCopy` — 6단계 메인 멘트 + 추천 행동 (개발가이드 §2·§5) **(R9)**
      `feat(domain): 단계별 멘트와 추천 행동 카피 추가`
- [x] T035 UX Writing 금지 패턴 린트 테스트 **(R10)**
      `test(domain): UX Writing 금지 표현 린트 추가`

## 디자인 토큰

- [x] T040 `Color+Hex` + `Palette` 35색 **(R6)**
      `design(design-system): Figma 디자인 토큰 이식`
- [x] T041 [P] `SweatType` 텍스트 스타일 29개 **(R7)**
      자간은 `.tracking(-0.02 * size)`로 환산
      `design(design-system): 텍스트 스타일 29개 추가`
- [x] T042 [P] `Layout` — Space · Radius
      `design(design-system): 스페이싱·라디우스 토큰 추가`
- [x] T043 `DesignSystem/README.md` 매핑 표 (Figma 변수명 · hex · Swift 심볼)
      `docs(design-system): 토큰 매핑 표 추가`

## 컴포넌트 5종 — 각각 접근성 포함 (R8, 「접근성은 마감이 아니다」)

- [x] T050 `SweatButton` (Primary / Dark / Ghost)
      `design(design-system): Button 컴포넌트 추가`
- [x] T051 [P] `SweatChip` (Off / On) — 선택 상태를 `accessibilityAddTraits(.isSelected)`로
      `design(design-system): Chip 컴포넌트 추가`
- [x] T052 [P] `SelectableCard` (Off / On)
      `design(design-system): Selectable Card 컴포넌트 추가`
- [x] T053 [P] `ScoreButton` (Off / On)
      `design(design-system): Score Button 컴포넌트 추가`
- [x] T054 [P] `SweatTextField`
      `design(design-system): Text Field 컴포넌트 추가`
- [x] T055 `ComponentCatalogView` + Preview — Figma 대조용
      `design(design-system): 컴포넌트 카탈로그 화면 추가`

## 린트

- [x] T060 `Scripts/lint-tokens.sh` — 색상·폰트 리터럴 검출 (규칙 「색과 글꼴은 토큰으로」)
      대상 경로는 Features가 생기는 001부터 확장한다
      `chore: 디자인 토큰 리터럴 검출 스크립트 추가`

## 마무리

- [x] T090 규칙 점검 표 최종 확인 (spec.md §2)
- [x] T091 빌드 경고 0 · 테스트 전체 통과
- [x] T092 `docs/specs/README.md`의 000 상태를 Implemented로 갱신
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
| 2026-08-19 | T010 | 클린 빌드 성공, 컴파일러 경고 0. `-swift-version 6` 실측 확인 |
| 2026-08-19 | T011 | 패키지는 타깃 설정을 상속하지 않음을 실측. DesignSystem만 MainActor 명시 |
| 2026-08-19 | T020 | `swift test` 통과 (macOS 호스트, 시뮬레이터 불필요) |
| 2026-08-19 | T021 | 앱 타깃에 두 패키지 링크, 클린 빌드 경고 0 |
| 2026-08-19 | T030 | `SweatStage` 정의. 경계값은 `boundaries` 배열 한 곳. 임시 테스트로 동작 확인 후 원복 |
| 2026-08-19 | T031 | `Sensitivity` + `SweatStageEngine`. 규칙 「습도·풍속을 단계에 두 번 세지 않는다」를 시그니처로 강제. **보정값 단위 불일치 발견 → spec 미해결 질문 추가** |
| 2026-08-19 | T032·T033 | 테스트 18개 통과. **가드가 실제로 실패하는지 위반을 심어 역검증** — 경계값 리터럴 검사가 `33.0`을 놓쳐 값 비교 방식으로 교체 |
| 2026-08-19 | T034·T035 | 6단계 문구·추천 24개 + UX Writing 린트. 역검증에서 `\b`가 한글에 안 먹는 것 발견, 패턴을 "땀 근처 수치"로 교체 |
| 2026-08-19 | T040~T043 | 컬러 35 · 숫자 13 · 스타일 29. Figma 내보내기에서 스크립트로 생성 후 양방향 대조. **R6의 "48개"는 오기 — 48은 변수 전체, 컬러는 35** |
| 2026-08-19 | T050·T051 | Button 3종 · Chip 2종. **토큰이 Dynamic Type을 안 따르던 것 발견 → `@ScaledMetric` 적용**. 시각 검증은 T055 카탈로그에서 |
| 2026-08-19 | T052~T054 | Selectable Card · Score Button · Text Field. 토큰 밖 여백이 18·14·15로 더 나옴 |
| 2026-08-19 | T055 | 카탈로그 + 시뮬레이터 실행. **줄높이 근사가 단일 행에는 무효 — 카드당 약 7pt 차이** 발견 |
| 2026-08-19 | T060 | 리터럴 린트. 오류 3종·경고 2종, 역검증 6케이스 통과 |
| 2026-08-19 | T090~T092 | 린트·테스트·Debug/Release 빌드 전부 통과. 로드맵 Implemented로 |
