import SwiftUI

/// 단일·다중 선택 필터. Figma `Chip`.
///
/// 이동수단, 시간대, 기록 태그에 쓴다.
/// 선택 여부는 호출자가 관리한다 — 이 뷰는 상태를 갖지 않는다.
public struct SweatChip: View {

    private let title: String
    private let isOn: Bool
    private let action: () -> Void

    public init(_ title: String, isOn: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isOn = isOn
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                // Figma의 `Chip/15`는 Regular지만, On 상태는 Semibold로 굵어진다.
                .sweatType(isOn ? Self.selectedType : .chip15)
                .padding(.vertical, Self.verticalPadding)
                .padding(.horizontal, Space.x4)
        }
        .buttonStyle(SweatChipStyle(isOn: isOn))
        // 선택 상태를 색과 굵기로만 전달하면 VoiceOver 사용자에게 닿지 않는다 (규칙 「접근성은 마감이 아니다」).
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    private static let selectedType = SweatTextStyle(
        figmaName: "Chip/15 (On)",
        size: SweatTextStyle.chip15.size,
        weight: .semibold,
        lineHeightRatio: SweatTextStyle.chip15.lineHeightRatio,
        tracking: SweatTextStyle.chip15.tracking
    )

    /// Figma 컴포넌트의 상하 여백. `space/*` 토큰에 없는 값이다 (`space/2`가 8).
    ///
    /// **토큰으로 낮추지 않는다.** 8로 내리면 칩이 더 얇아져 터치 영역이 나빠진다.
    /// 다른 컴포넌트의 여백은 토큰으로 정렬했지만 칩만 예외다.
    private static let verticalPadding: CGFloat = 9

    /// Apple HIG 최소 터치 타깃.
    ///
    /// 칩의 시각 높이는 약 37pt로 이 값에 미치지 못한다. 여백을 키워 높이를
    /// 맞추면 칩이 눈에 띄게 두꺼워지므로, **보이는 크기는 그대로 두고
    /// 탭 영역만** 넓힌다. 대가로 칩이 놓인 행의 높이가 7pt 늘어난다.
    static let minimumTouchTarget: CGFloat = 44
}

private struct SweatChipStyle: ButtonStyle {
    let isOn: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isOn ? Accent.deep : Ink.n900)
            .background(isOn ? Surface.accentTint : Surface.card, in: shape)
            .overlay {
                shape.strokeBorder(
                    // Off 상태의 테두리는 잉크의 24% 투명도다. 토큰에는 불투명 색만 있어
                    // 여기서 투명도를 준다. 반복되면 border/hairline 토큰을 만든다.
                    isOn ? BorderColor.accent : Ink.n900.opacity(0.24),
                    lineWidth: 1
                )
            }
            // 시각 크기를 유지한 채 탭 영역만 44pt로 넓힌다 (규칙 「접근성은 마감이 아니다」).
            // 배경과 테두리를 먼저 그린 뒤에 프레임을 늘려야 칩 자체는 커지지 않는다.
            .frame(minHeight: SweatChip.minimumTouchTarget)
            .contentShape(.rect)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.pill, style: .continuous)
    }
}

#Preview("Chip") {
    VStack(alignment: .leading, spacing: Space.x3) {
        HStack(spacing: Space.x2) {
            SweatChip("도보", isOn: false) {}
            SweatChip("지하철", isOn: true) {}
            SweatChip("버스", isOn: false) {}
            SweatChip("자전거", isOn: false) {}
        }
        HStack(spacing: Space.x2) {
            SweatChip("20분 이하", isOn: false) {}
            SweatChip("20~40분", isOn: true) {}
            SweatChip("40분 이상", isOn: false) {}
        }
    }
    .padding(Space.gutter)
    .background(Surface.page)
}
