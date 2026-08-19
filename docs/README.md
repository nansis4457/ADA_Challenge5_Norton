# 문서 — Spec-Driven Development

이 폴더가 프로젝트의 **단일 출처**다. 코드와 문서가 어긋나면 문서를 먼저 고친다.

---

## 읽는 순서

| 순서 | 문서 | 언제 읽나 |
|---|---|---|
| 1 | [`constitution.md`](constitution.md) | **매번.** 협상 불가능한 원칙 11개 |
| 2 | [`architecture.md`](architecture.md) | 기술 판단이 필요할 때. 프레임워크·데이터 흐름·리스크 |
| 3 | [`design-source.md`](design-source.md) | UI를 만들 때. Figma ↔ 코드 매핑 |
| 4 | [`git-workflow.md`](git-workflow.md) | 커밋·PR 전 |
| 5 | [`specs/README.md`](specs/README.md) | 다음에 뭘 만들지 정할 때 |

도메인 원본은 저장소 루트의 `땀_날씨앱_구간화_UI_멘트_개발가이드.md`.
구간 정의와 UX Writing 원칙의 출처이며, 헌법 III·IV·V가 여기서 나왔다.

---

## 작업 흐름

```
 ① 스펙      docs/specs/NNN-<slug>/spec.md     무엇을 · 왜
      ↓                                        (프레임워크 이름 금지)
 ② 계획      docs/specs/NNN-<slug>/plan.md     어떻게
      ↓                                        (헌법 점검 표 필수)
 ③ 태스크    docs/specs/NNN-<slug>/tasks.md    커밋 단위로 분해
      ↓
 ④ 구현      브랜치 NNN-<slug>
      ↓
 ⑤ PR        헌법 점검 체크리스트 응답
```

**규칙**
- spec이 Approved 되기 전에 plan을 쓰지 않는다
- plan의 헌법 점검 표가 비어 있으면 tasks를 쓰지 않는다
- 태스크 하나 = 커밋 하나
- 버그 수정과 오탈자는 이 흐름을 건너뛴다

템플릿은 [`templates/`](templates/).

---

## 폴더 구조

```
docs/
├── README.md              ← 지금 이 문서
├── constitution.md        프로젝트 헌법
├── architecture.md        기술 설계
├── design-source.md       Figma 매핑
├── git-workflow.md        커밋 · PR 규칙
├── templates/             spec / plan / tasks 템플릿
└── specs/
    ├── README.md          로드맵
    └── NNN-<slug>/
        ├── spec.md
        ├── plan.md
        └── tasks.md
```

---

## 현재 상태

| | |
|---|---|
| 진행 중 | `000-foundation` (Draft) |
| 다음 | Swift 6 전환 → 패키지 분리 → 디자인 토큰 |
| 블로커 | 기상청 체감온도 산식 검증 (`architecture.md` §5.4) |
