import SwiftUI

/// 제목과 설명을 가진 선택형 카드. Figma `Selectable Card`.
///
/// 온보딩의 땀 민감도 선택과 이동 중 행동 유도 카드가 같은 컴포넌트를 쓴다.
/// 두 자리의 제목 크기가 달라 `titleStyle`로 받는다.
public struct SelectableCard: View {

    private let title: String
    private let description: String
    private let titleStyle: SweatTextStyle
    private let isSelected: Bool
    private let action: () -> Void

    /// - Parameter titleStyle: 온보딩은 `.option17`, 이동 중 행동 카드는 `.bodyStrong16`.
    public init(
        title: String,
        description: String,
        titleStyle: SweatTextStyle = .option17,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.titleStyle = titleStyle
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .sweatType(titleStyle)
                    .foregroundStyle(Ink.n900)
                Text(description)
                    .sweatType(.caption13)
                    .foregroundStyle(Ink.n600)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .padding(Space.x4)
        }
        .buttonStyle(SelectableSurfaceStyle(isSelected: isSelected, cornerRadius: Radius.lg))
        // 제목과 설명을 따로 읽으면 맥락이 끊긴다. 하나의 선택지로 묶는다 (헌법 IX).
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// 선택 여부에 따라 면과 테두리가 바뀌는 표면. 카드·점수 버튼이 공유한다.
struct SelectableSurfaceStyle: ButtonStyle {
    let isSelected: Bool
    let cornerRadius: CGFloat
    var selectedFill: Color = Surface.accentTint
    var unselectedFill: Color = Surface.card

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(isSelected ? selectedFill : unselectedFill, in: shape)
            .overlay {
                shape.strokeBorder(
                    // Off 테두리는 잉크의 20% 투명도. Chip(24%)과 값이 달라 토큰으로 묶지 않았다.
                    isSelected ? BorderColor.accent : Ink.n900.opacity(0.20),
                    lineWidth: 1
                )
            }
            .contentShape(shape)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }
}

#Preview("Selectable Card") {
    VStack(spacing: Space.x2 + 2) {
        SelectableCard(title: "적은 편", description: "더워도 땀은 잘 안 나는 편이에요",
                       isSelected: false) {}
        SelectableCard(title: "보통", description: "남들과 비슷한 정도예요",
                       isSelected: true) {}
        SelectableCard(title: "무더위쉼터 들르기", description: "80m 앞 편의점 · 냉방 · 도보 1분",
                       titleStyle: .bodyStrong16, isSelected: true) {}
    }
    .padding(Space.gutter)
    .background(Surface.page)
}
