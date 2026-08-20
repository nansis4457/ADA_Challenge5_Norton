import SwiftUI

/// 디자인 시스템 대조용 카탈로그.
///
/// - Important: **`#if DEBUG`로 감싸지 않는다.** 감싸면 SwiftUI 프리뷰 빌드가
///   깨진다. 프리뷰용 dylib를 만들 때 앱 타깃과 패키지의 컴파일 조건이 항상
///   같지는 않아, 앱은 이 타입을 참조하는데 패키지에는 심볼이 없는 상태가 된다
///   (`Undefined symbol: DesignSystem.ComponentCatalogView.init()`).
///
///   릴리스 빌드에 노출되지 않게 하는 책임은 **호출하는 쪽**에 있다.
///   앱의 `ContentView`가 `#if DEBUG`로 분기한다.
///
/// Figma `② Components` 페이지와 나란히 놓고 눈으로 비교한다.
/// 특히 다음 두 가지를 확인한다.
///
/// 1. **줄높이** — SwiftUI에는 Figma line-height에 대응하는 API가 없어
///    `size × (ratio − 1.2)`로 근사했다. 여러 줄 본문에서 차이가 드러난다.
/// 2. **터치 타깃** — Chip이 37pt로 HIG 최소치 44pt에 못 미친다.
public struct ComponentCatalogView: View {

    @State private var selectedChip = "지하철"
    @State private var selectedCard = 1
    @State private var score = 4
    @State private var from = "성수역 3번 출구"
    @State private var to = ""

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.x7) {
                header
                buttons
                chips
                cards
                scores
                fields
                typeSpecimen
                palette
            }
            .padding(.horizontal, Space.gutter)
            .padding(.vertical, Space.x6)
        }
        .background(Surface.page)
    }

    // MARK: -

    private var header: some View {
        VStack(alignment: .leading, spacing: Space.x1) {
            Text("DESIGN SYSTEM")
                .sweatType(.overline11)
                .foregroundStyle(Ink.n500)
            Text("컴포넌트 카탈로그")
                .sweatType(.title24Bold)
                .foregroundStyle(Ink.n900)
            Text("Figma ② Components 페이지와 나란히 놓고 확인합니다.")
                .sweatType(.body15)
                .foregroundStyle(Ink.n600)
        }
    }

    private func section<Content: View>(
        _ title: String, _ note: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Space.x3) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .sweatType(.heading19)
                    .foregroundStyle(Ink.n900)
                if let note {
                    Text(note)
                        .sweatType(.caption13)
                        .foregroundStyle(Ink.n500)
                }
            }
            content()
        }
    }

    private var buttons: some View {
        section("Button", "Primary · Dark · Ghost") {
            VStack(spacing: Space.x3) {
                SweatButton("다음") {}
                SweatButton("더위를 덜 느끼는 길로 이동해요  →", style: .dark) {}
                SweatButton("나중에 할게요", style: .ghost) {}
            }
        }
    }

    private var chips: some View {
        section("Chip", "터치 타깃 37pt — HIG 최소 44pt 미달") {
            VStack(alignment: .leading, spacing: Space.x2) {
                ForEach([["도보", "지하철", "버스", "자전거"],
                         ["20분 이하", "20~40분", "40분 이상"]], id: \.self) { row in
                    HStack(spacing: Space.x2) {
                        ForEach(row, id: \.self) { label in
                            SweatChip(label, isOn: selectedChip == label) {
                                selectedChip = label
                            }
                        }
                    }
                }
            }
        }
    }

    private var cards: some View {
        section("Selectable Card", "제목 크기가 다른 두 자리를 함께 씁니다") {
            VStack(spacing: Space.x2 + 2) {
                ForEach(Array(Self.sensitivities.enumerated()), id: \.offset) { index, option in
                    SelectableCard(
                        title: option.0, description: option.1,
                        isSelected: selectedCard == index
                    ) { selectedCard = index }
                }
                SelectableCard(
                    title: "무더위쉼터 들르기", description: "80m 앞 편의점 · 냉방 · 도보 1분",
                    titleStyle: .bodyStrong16, isSelected: true
                ) {}
            }
        }
    }

    private var scores: some View {
        section("Score Button", "자가 기록 1~5점") {
            VStack(spacing: Space.x2) {
                HStack(spacing: Space.x2) {
                    ForEach(1...5, id: \.self) { n in
                        ScoreButton(n, isSelected: score == n) { score = n }
                    }
                }
                HStack {
                    Text("쾌적했다")
                    Spacer()
                    Text("매우 땀참")
                }
                .sweatType(.caption12)
                .foregroundStyle(Ink.n400)
            }
        }
    }

    private var fields: some View {
        section("Text Field") {
            VStack(spacing: Space.x3 + 2) {
                SweatTextField("출발", text: $from)
                SweatTextField("도착", placeholder: "어디로 가세요?", text: $to)
            }
        }
    }

    private var typeSpecimen: some View {
        section("Typography", "줄높이는 근사입니다 — 여러 줄 본문을 특히 확인하세요") {
            VStack(alignment: .leading, spacing: Space.x3) {
                ForEach(Array(SweatTextStyle.all.enumerated()), id: \.offset) { _, style in
                    VStack(alignment: .leading, spacing: 1) {
                        Text(style.figmaName)
                            .sweatType(.overline11)
                            .foregroundStyle(Ink.n400)
                        Text(Self.sample(for: style))
                            .sweatType(style)
                            .foregroundStyle(Ink.n900)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var palette: some View {
        section("Color") {
            VStack(alignment: .leading, spacing: Space.x3) {
                ForEach(Self.colorGroups, id: \.0) { name, colors in
                    VStack(alignment: .leading, spacing: Space.x1) {
                        Text(name)
                            .sweatType(.caption13)
                            .foregroundStyle(Ink.n500)
                        HStack(spacing: Space.x1) {
                            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                                RoundedRectangle(cornerRadius: Radius.sm)
                                    .fill(color)
                                    .frame(height: 44)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: Radius.sm)
                                            .strokeBorder(BorderColor.subtle, lineWidth: 1)
                                    }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 표본

    private static let sensitivities = [
        ("적은 편", "더워도 땀은 잘 안 나는 편이에요"),
        ("보통", "남들과 비슷한 정도예요"),
        ("많은 편", "조금만 더워도 땀이 많이 나요"),
    ]

    /// 여러 줄 스타일에는 실제로 줄이 넘어가는 문장을 넣어야 줄높이를 볼 수 있다.
    private static func sample(for style: SweatTextStyle) -> String {
        if style.lineHeightRatio >= 1.4 {
            "같은 날씨에서도 사람마다 느끼는 정도가 달라요. 등급과 추천을 조정하는 데 쓰입니다."
        } else if style.size >= 24 {
            "오늘은 땀이 많이 날 수 있어요"
        } else {
            "체감온도 34.2℃ · 습도 78%"
        }
    }

    private static let colorGroups: [(String, [Color])] = [
        ("Surface", [Surface.page, Surface.card, Surface.accentTint, Surface.accentWash, Surface.magentaTint]),
        ("Ink", [Ink.n200, Ink.n300, Ink.n400, Ink.n500, Ink.n600, Ink.n700, Ink.n900]),
        ("Accent", [Accent.deep, Accent.base, Accent.light]),
        ("Magenta", [Magenta.deep, Magenta.base, Magenta.dark, Magenta.mid, Magenta.light]),
        ("Stage body", (1...6).map { StageColor.body($0) }),
        ("Stage top", (1...6).map { StageColor.top($0) }),
    ]
}

#Preview("카탈로그") {
    ComponentCatalogView()
}

#Preview("접근성 크기") {
    ComponentCatalogView()
        .environment(\.dynamicTypeSize, .accessibility2)
}
