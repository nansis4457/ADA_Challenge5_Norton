# Git · GitHub 작업 규칙

**저장소** https://github.com/nansis4457/ADA_Challenge5_Norton
**기본 브랜치** `main`

---

## 0. 누가 실행하는가

**git 명령은 사람이 직접 실행한다.** AI 에이전트는 제안까지만 한다.

| | |
|---|---|
| 에이전트 실행 금지 | `commit` · `push` · `branch` · `checkout` · `merge` · `reset` · `rebase` · `tag` · PR 생성·머지 |
| 에이전트가 할 일 | 커밋 메시지 초안, 브랜치 이름, 실행할 명령어를 **제시**하고 기다린다 |
| 에이전트 실행 허용 | `status` · `log` · `diff` · `show` 등 읽기 전용 |

파일 편집·빌드·테스트는 에이전트가 진행해도 된다.
**저장소 히스토리에 기록을 남기는 행위만** 사람 손을 거친다.

이유 — 히스토리는 되돌리기 비싸고, 무엇을 언제 남길지는 작업자의 판단이다.

---

## 1. 브랜치 전략

SDD의 스펙 번호와 브랜치를 1:1로 묶는다. 브랜치 이름만 보고 어느 스펙 작업인지 알 수 있어야 한다.

```
main                          항상 빌드 가능. 직접 푸시 금지.
├── 000-foundation            스펙 단위 작업 브랜치
├── 002-home
└── fix/weather-cache-ttl     스펙 없는 버그 수정
```

| 접두사 | 용도 | 예시 |
|---|---|---|
| `NNN-<slug>` | 스펙 구현 (`docs/specs/NNN-*`와 동일 이름) | `002-home` |
| `fix/` | 버그 수정 | `fix/grid-conversion-seoul` |
| `chore/` | 빌드 설정·의존성·문서 | `chore/swift6-migration` |
| `docs/` | 문서만 변경 | `docs/update-constitution` |

작업 브랜치는 머지 후 삭제한다.

---

## 2. 커밋 메시지

Conventional Commits를 쓰되, **본문은 한국어**로 쓴다.

```
<type>(<scope>): <제목>

<본문 — 왜 이렇게 했는지. 무엇을 했는지는 diff가 말해준다.>

Refs: docs/specs/002-home
```

### type

| type | 의미 |
|---|---|
| `feat` | 사용자에게 보이는 기능 추가 |
| `fix` | 버그 수정 |
| `refactor` | 동작 변화 없는 구조 개선 |
| `test` | 테스트 추가·수정 |
| `docs` | 문서 |
| `chore` | 빌드·설정·의존성 |
| `design` | 디자인 토큰·컴포넌트 반영 |

### scope

패키지 또는 화면 이름을 쓴다. `domain`, `design-system`, `weather`, `route`, `home`, `move`, `log`

### 제목 규칙

- 50자 이내, 마침표 없음
- 명령형 대신 **완료형 한국어** (`추가`, `수정`, `분리`)
- 예: `feat(domain): 땀 등급 6단계 산출 엔진 추가`

### 예시

```
fix(weather): 초단기실황 40분 이전 호출 시 빈 응답 처리

기상청은 매시 40분 이후에 해당 시각 자료를 올린다. 40분 이전에
현재 시각으로 요청하면 빈 배열이 오는데, 이를 에러로 처리하고 있었다.
직전 시각으로 폴백하도록 수정.

Refs: docs/specs/002-home
```

### 하지 말 것

- `update`, `수정`, `작업중` 같은 내용 없는 제목
- 여러 관심사를 한 커밋에 섞기 — 스펙 태스크 하나가 커밋 하나다
- `xcuserdata`, `.DS_Store` 커밋 — `.gitignore`가 막고 있지만 확인할 것

---

## 3. Pull Request

### 언제 여나

작업 브랜치의 태스크가 **전부** 끝났을 때. 중간 상태로 열지 않는다.
리뷰가 필요한 설계 판단이 있으면 Draft PR로 열고 본문에 질문을 적는다.

### 제목

브랜치의 스펙 번호와 목적을 그대로. `[002] 홈 화면 · 땀 등급 표시`

### 본문 템플릿

```markdown
## 무엇을

<한 문단. 이 PR이 끝나면 사용자가 무엇을 할 수 있는가.>

## 스펙

docs/specs/002-home/spec.md

## 헌법 점검

- [ ] I. 도메인 순수성 — SweatDomain 의존성 추가 없음
- [ ] II. 로직/문구 분리 — 뷰에 문자열 리터럴 없음
- [ ] III. UX Writing — 단정 표현 없음
- [ ] VIII. 디자인 토큰 — 색상·폰트 리터럴 없음
- [ ] IX. 접근성 — VoiceOver 라벨, Dynamic Type 확인
- [ ] X. Swift 6 — 동시성 경고 0

위반이 있으면 사유를 적는다. 체크만 하고 넘어가지 않는다.

## 확인 방법

<리뷰어가 직접 눌러볼 순서. 시뮬레이터 기종·화면 이동 경로.>

## 스크린샷

<UI 변경이 있으면 필수. Figma 원본과 나란히.>

## 남은 것

<이 PR에서 의도적으로 안 한 것. 후속 이슈 번호.>
```

### 머지 규칙

- **Squash and merge**를 기본으로 한다. `main` 히스토리는 스펙 단위로 읽힌다.
- squash 커밋 메시지는 PR 제목이 아니라 §2 형식으로 다시 쓴다.
- 머지 전 조건: 빌드 성공, 테스트 통과, 헌법 점검 항목 전부 응답됨

---

## 4. 이슈

라벨 최소 집합으로 유지한다.

| 라벨 | 용도 |
|---|---|
| `spec` | 스펙 작성·개정이 필요한 건 |
| `bug` | 재현 가능한 결함 |
| `blocked` | 외부 의존(데이터·API 키·산식 검증)으로 멈춘 건 |
| `research` | 결정을 위해 조사가 필요한 건 (구간 경계값 등) |

**착수 전 미해결 과제**(체감온도 산식 검증, 공공데이터 커버리지 등)는
`docs/architecture.md` 부록 A를 이슈로 옮겨서 추적한다.

---

## 5. 커밋 전 체크리스트

```bash
# 빌드
xcodebuild -project ADA_Challenge5_Norton/ADA_Challenge5_Norton.xcodeproj \
  -scheme ADA_Challenge5_Norton -destination 'generic/platform=iOS Simulator' build

# 민감 정보가 섞이지 않았는지
git diff --cached --name-only | grep -i -E 'secret|key|xcconfig' || echo "clean"
```

인증키는 `Secrets.xcconfig`에 두고 커밋하지 않는다. `.gitignore`에 등록되어 있다.
새 팀원은 `Secrets.xcconfig.example`을 복사해서 채운다.
