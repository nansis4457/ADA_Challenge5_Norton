# DesignSystem

Figma `Sweat App` 변수 컬렉션과 텍스트 스타일의 **코드 미러**.

**Figma가 단일 출처다.** 값이 어긋나면 Figma가 맞다.
토큰을 바꿀 때는 ① Figma 수정 → ② 이 표 수정 → ③ 코드 수정 순서로 간다.

디자인 원본 — https://www.figma.com/design/QKHhjWJNfvj1zcwThW29rz/Challenge5?node-id=30-22

---

## 쓰는 법

```swift
import DesignSystem

Text("오늘은 땀이 많이 날 수 있어요")
    .sweatType(.hero31)
    .foregroundStyle(Ink.n900)
    .padding(Space.x4)
    .background(Surface.card, in: .rect(cornerRadius: Radius.lg))
```

뷰 코드에 색상·폰트 리터럴을 쓰지 않는다 (헌법 VIII).
`Color(hex:)`는 이 패키지의 토큰 정의에서만 호출한다.

---

## 컬러 — 35개

| Figma | Hex | Swift |
|---|---|---|
| `accent/base` | `#0088B0` | `Accent.base` |
| `accent/deep` | `#006786` | `Accent.deep` |
| `accent/light` | `#38A6CF` | `Accent.light` |
| `bg/accent-tint` | `#E9F8FF` | `Surface.accentTint` |
| `bg/accent-wash` | `#F0F8FB` | `Surface.accentWash` |
| `bg/magenta-tint` | `#FFF1F4` | `Surface.magentaTint` |
| `bg/page` | `#F3F2F2` | `Surface.page` |
| `bg/surface` | `#FFFFFF` | `Surface.card` |
| `border/accent` | `#0088B0` | `BorderColor.accent` |
| `border/subtle` | `#D0CCCB` | `BorderColor.subtle` |
| `ink/200` | `#E2E0E0` | `Ink.n200` |
| `ink/300` | `#D7D3D3` | `Ink.n300` |
| `ink/400` | `#9B9797` | `Ink.n400` |
| `ink/500` | `#7D7979` | `Ink.n500` |
| `ink/600` | `#605D5D` | `Ink.n600` |
| `ink/700` | `#444141` | `Ink.n700` |
| `ink/900` | `#201E1D` | `Ink.n900` |
| `magenta/base` | `#D6006C` | `Magenta.base` |
| `magenta/dark` | `#D82071` | `Magenta.dark` |
| `magenta/deep` | `#AA0B56` | `Magenta.deep` |
| `magenta/light` | `#FF90B1` | `Magenta.light` |
| `magenta/mid` | `#FF458E` | `Magenta.mid` |
| `on/accent` | `#FFFFFF` | `OnColor.accent` |
| `stage/1-body` | `#E9F8FF` | `StageColor.body(1)` |
| `stage/1-top` | `#CBEEFF` | `StageColor.top(1)` |
| `stage/2-body` | `#CBEEFF` | `StageColor.body(2)` |
| `stage/2-top` | `#99E0FF` | `StageColor.top(2)` |
| `stage/3-body` | `#FFDEE6` | `StageColor.body(3)` |
| `stage/3-top` | `#FFC0D0` | `StageColor.top(3)` |
| `stage/4-body` | `#FFC0D0` | `StageColor.body(4)` |
| `stage/4-top` | `#FF90B1` | `StageColor.top(4)` |
| `stage/5-body` | `#FF90B1` | `StageColor.body(5)` |
| `stage/5-top` | `#FF458E` | `StageColor.top(5)` |
| `stage/6-body` | `#FF458E` | `StageColor.body(6)` |
| `stage/6-top` | `#D82071` | `StageColor.top(6)` |

### 이름이 다른 것

| Figma | Swift | 이유 |
|---|---|---|
| `bg/surface` | `Surface.card` | `Surface.surface`가 어색해서. 흰 면(카드·입력·시트)에 쓴다 |
| `border/*` | `BorderColor.*` | SwiftUI의 `Border`와 이름이 겹친다 |
| `ink/900` | `Ink.n900` | Swift 식별자는 숫자로 시작할 수 없다 |
| `stage/N-body` | `StageColor.body(N)` | 단계가 런타임 값이라 함수로 받는다 |

---

## 간격 · 반경 — 13개

| Figma | 값 | Swift |
|---|---|---|
| `radius/lg` | `12` | `Radius.lg` |
| `radius/md` | `10` | `Radius.md` |
| `radius/pill` | `999` | `Radius.pill` |
| `radius/sm` | `2` | `Radius.sm` |
| `radius/xl` | `14` | `Radius.xl` |
| `screen/gutter` | `22` | `Space.gutter` |
| `space/1` | `4` | `Space.x1` |
| `space/2` | `8` | `Space.x2` |
| `space/3` | `12` | `Space.x3` |
| `space/4` | `16` | `Space.x4` |
| `space/5` | `22` | `Space.x5` |
| `space/6` | `26` | `Space.x6` |
| `space/7` | `32` | `Space.x7` |

`space/5`와 `screen/gutter`는 값이 같지만(22) 역할이 다르다.
전자는 일반 간격, 후자는 화면 좌우 여백이다. 화면 여백이 바뀌어도 간격은 그대로여야 한다.

---

## 텍스트 스타일 — 29개

모두 SF Pro. 한글은 시스템이 Apple SD Gothic Neo로 대체하므로 커스텀 폰트를 등록하지 않는다.

| Figma | 굵기 | 크기 | 줄높이 | 자간 | Swift (`.sweatType(…)`) |
|---|---|---|---|---|---|
| `Hero/31` | Semibold | 31 | 128% | -2% | `.hero31` |
| `Title/30` | Semibold | 30 | 125% | -2% | `.title30` |
| `Title/29` | Semibold | 29 | 130% | -2% | `.title29` |
| `Title/28` | Semibold | 28 | 130% | -2% | `.title28` |
| `Title/27` | Semibold | 27 | 130% | -2% | `.title27` |
| `Heading/19` | Semibold | 19 | 135% | -2% | `.heading19` |
| `Stat/22` | Semibold | 22 | 125% | -2% | `.stat22` |
| `Stat/18` | Semibold | 18 | 130% | -2% | `.stat18` |
| `Option/17` | Semibold | 17 | 130% | -2% | `.option17` |
| `Input/17` | Regular | 17 | 130% | -2% | `.input17` |
| `Button/16` | Semibold | 16 | 125% | -2% | `.button16` |
| `Body Strong/16` | Semibold | 16 | 140% | -2% | `.bodyStrong16` |
| `Body/15` | Regular | 15 | 160% | -2% | `.body15` |
| `Body Strong/15` | Semibold | 15 | 145% | -2% | `.bodyStrong15` |
| `Chip/15` | Regular | 15 | 130% | -2% | `.chip15` |
| `Body/14` | Regular | 14 | 155% | -2% | `.body14` |
| `Caption/13` | Regular | 13 | 160% | -2% | `.caption13` |
| `Caption/12` | Regular | 12 | 140% | -2% | `.caption12` |
| `Tab/10.5` | Medium | 10.5 | 120% | 0% | `.tab105` |
| `Overline/11` | Regular | 11 | 130% | 14% | `.overline11` |
| `Title/24 Bold` | Bold | 24 | 120% | -3% | `.title24Bold` |
| `Title/22 Bold` | Bold | 22 | 120% | -2% | `.title22Bold` |
| `Stat/20 Bold` | Bold | 20 | 120% | -2% | `.stat20Bold` |
| `Section/15` | Semibold | 15 | 130% | -2% | `.section15` |
| `List/16` | Medium | 16 | 130% | -2% | `.list16` |
| `List/12.5` | Regular | 12.5 | 130% | -2% | `.list125` |
| `Body/13.5` | Regular | 13.5 | 140% | -2% | `.body135` |
| `Forecast/16` | Semibold | 16 | 125% | -2% | `.forecast16` |
| `Label/14 Medium` | Medium | 14 | 130% | -2% | `.label14Medium` |

### 줄높이에 대한 주의

SwiftUI에는 Figma의 line-height에 정확히 대응하는 API가 없다.
`lineSpacing`은 줄 사이에 **추가로** 넣는 여백이라, 폰트가 이미 가진 줄 높이
(SF Pro 기준 대략 `size × 1.2`)를 빼서 근사한다.

```swift
lineSpacing = max(0, size * (lineHeightRatio - 1.2))
```

`lineSpacing`은 한 `Text` **안의 줄 사이**에만 들어간다. 한 줄짜리 텍스트에는
효과가 없어 Figma보다 상자가 작다 (Selectable Card 기준 77.9pt 대 70.7pt).

**의도된 차이다.** SwiftUI 기본 조판을 따르기로 결정했다 (2026-08-19).
Figma의 프레임 높이는 참고값이며 구현 목표가 아니다.
화면을 만들 때 간격(`Space.*`)과 순서를 맞추고, 높이는 콘텐츠가 정하게 둔다.

### 자간

Figma는 자간을 폰트 크기의 %로 준다. 코드에서는 pt로 환산해 넣는다.

```
tracking(pt) = size × (자간% / 100)
예) Body/15 의 -2%  →  15 × -0.02 = -0.3pt
```
