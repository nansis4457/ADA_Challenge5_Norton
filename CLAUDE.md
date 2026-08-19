# ADA_Challenge5_Norton — 땀 관리 날씨 앱

## 먼저 읽을 것

**작업을 시작하기 전에 `docs/constitution.md`를 읽는다.** 협상 불가능한 원칙 11개가 있고,
모든 스펙·구현·리뷰가 여기에 종속된다.

| 문서 | 내용 |
|---|---|
| `docs/constitution.md` | 프로젝트 헌법 — 매번 확인 |
| `docs/architecture.md` | 프레임워크 선택, 데이터 흐름, 리스크 |
| `docs/design-source.md` | Figma ↔ 코드 매핑 |
| `docs/git-workflow.md` | 커밋·PR 규칙 |
| `docs/specs/README.md` | 스펙 로드맵 |
| `땀_날씨앱_구간화_UI_멘트_개발가이드.md` | 도메인 원본 (구간·UX Writing) |

## 에이전트 작업 규칙

**git 명령은 먼저 실행하지 않는다. 제안만 한다.**

| | |
|---|---|
| 실행 금지 | `commit` · `push` · `branch` · `checkout` · `merge` · `reset` · `rebase` · `tag` · PR 생성·머지 |
| 대신 할 것 | 커밋 메시지 초안, 브랜치 이름, 실행할 명령어를 **제시**하고 기다린다 |
| 실행해도 되는 것 | `status` · `log` · `diff` · `show` 등 읽기 전용 |

파일 생성·수정·삭제, 빌드, 테스트 실행은 진행해도 된다.
git으로 기록을 남기는 순간부터는 사용자가 직접 한다.

## 이 프로젝트에서 자주 어기는 것

1. **뷰에 색상·폰트 리터럴을 쓴다** → `DesignSystem` 토큰만 쓴다 (헌법 VIII)
2. **뷰에 문자열 리터럴을 쓴다** → 카피는 도메인 계층에서 온다 (헌법 II)
3. **습도·풍속으로 단계를 올린다** → 설명·추천만 보정한다 (헌법 IV)
4. **땀의 양을 단정한다** → `~일 수 있어요` 어투 (헌법 III)
5. **추정치를 확정치처럼 표기한다** → `약 12분`, 고지 문구 (헌법 VII)

## 작업 흐름

기능 구현은 `spec.md` → `plan.md` → `tasks.md` 순서를 거친다. 자세한 건 `docs/README.md`.
버그 수정과 오탈자는 예외.

## 프로젝트

```
ADA_Challenge5_Norton/ADA_Challenge5_Norton.xcodeproj
```

| | |
|---|---|
| 최소 지원 | iOS 26.5 |
| Swift | 6.0, strict concurrency `complete` |
| UI | SwiftUI 100%, Portrait 고정 |
| 디자인 | https://www.figma.com/design/QKHhjWJNfvj1zcwThW29rz/Challenge5?node-id=30-24 |
| GitHub | https://github.com/nansis4457/ADA_Challenge5_Norton |

## 빌드

```bash
xcodebuild -project ADA_Challenge5_Norton/ADA_Challenge5_Norton.xcodeproj \
  -scheme ADA_Challenge5_Norton \
  -destination 'generic/platform=iOS Simulator' build
```

인증키는 `Secrets.xcconfig`에 둔다. 커밋하지 않는다.
