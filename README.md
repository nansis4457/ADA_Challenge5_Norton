# ADA_Challenge5_Norton

**땀 관리 날씨 앱** — 기상청 관측값으로 오늘의 땀 체감 등급을 산출하고,
실내·그늘 위주 도보 경로를 안내한 뒤, 자가 기록으로 다음 예측을 보정하는 iOS 앱.

Apple Developer Academy @ POSTECH · Challenge 5

---

## 무엇을 하는 앱인가

```
관측 → 등급 예측 → 경로 추천 → 이동 중 개입 → 자가 기록 → 기준 보정
```

체감온도를 **땀을 느끼거나 땀으로 불편할 가능성**으로 번역해 6단계로 보여주고,
그 등급에 맞는 행동과 경로를 추천한다. 땀의 양을 예측하지는 않는다.

---

## 문서

이 프로젝트는 **Spec-Driven Development**로 진행한다.
코드를 쓰기 전에 [`docs/`](docs/)를 읽는다.

| 문서 | |
|---|---|
| [`docs/README.md`](docs/README.md) | 문서 인덱스 · 작업 흐름 |
| [`docs/constitution.md`](docs/constitution.md) | 프로젝트 헌법 — **매번 확인** |
| [`docs/architecture.md`](docs/architecture.md) | 프레임워크 · 데이터 흐름 · 리스크 |
| [`docs/design-source.md`](docs/design-source.md) | Figma ↔ 코드 매핑 |
| [`docs/git-workflow.md`](docs/git-workflow.md) | 커밋 · PR 규칙 |
| [`docs/specs/`](docs/specs/) | 기능 스펙 |

도메인 원본 — [`땀_날씨앱_구간화_UI_멘트_개발가이드.md`](땀_날씨앱_구간화_UI_멘트_개발가이드.md)

---

## 개발 환경

| | |
|---|---|
| Xcode | 26.x |
| Swift | 6.0 (strict concurrency `complete`) |
| 최소 지원 | iOS 26.5 |
| UI | SwiftUI, Portrait 고정 |

```bash
xcodebuild -project ADA_Challenge5_Norton/ADA_Challenge5_Norton.xcodeproj \
  -scheme ADA_Challenge5_Norton \
  -destination 'generic/platform=iOS Simulator' build
```

기상청 API 인증키는 `Secrets.xcconfig`에 둔다. 저장소에 커밋하지 않는다.

---

## 디자인

https://www.figma.com/design/QKHhjWJNfvj1zcwThW29rz/Challenge5?node-id=30-24

`③ App UI` 페이지의 12개 화면이 구현 기준이다.
