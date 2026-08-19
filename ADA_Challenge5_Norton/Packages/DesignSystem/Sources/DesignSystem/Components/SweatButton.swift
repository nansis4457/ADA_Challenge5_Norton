import SwiftUI

/// 화면 하단의 주요 액션 버튼. Figma `Button`.
///
/// 세 스타일 모두 좌우 여백을 채우는 전체폭 버튼이다.
/// 폭은 부모가 정한다 — 화면에서 `Space.gutter`만큼 좌우 여백을 준다.
public struct SweatButton: View {

    public enum Style: Sendable, CaseIterable {
        /// 진행·확인. Figma `Style=Primary`
        case primary
        /// 홈의 추천 행동처럼 강조가 더 필요한 자리. Figma `Style=Dark`
        case dark
        /// 보조 선택지. Figma `Style=Ghost`
        case ghost

        var background: Color? {
            switch self {
            case .primary: Accent.base
            case .dark:    Ink.n900
            case .ghost:   nil
            }
        }

        var foreground: Color {
            switch self {
            case .primary, .dark: OnColor.accent
            case .ghost:          Ink.n600
            }
        }
    }

    private let title: String
    private let style: Style
    private let action: () -> Void

    public init(_ title: String, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .sweatType(.button16)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Space.x4)
                .padding(.horizontal, Self.horizontalPadding)
        }
        .buttonStyle(SweatButtonStyle(style: style))
    }

    /// - Note: Figma 컴포넌트의 좌우 여백은 20이며 `space/*` 토큰에 없는 값이다.
    ///   전체폭·중앙정렬이라 시각적 영향은 사실상 없지만, 토큰 갭으로 남겨둔다.
    ///   Figma를 22(`space/5`)로 맞추거나 토큰을 추가하면 이 상수는 사라진다.
    private static let horizontalPadding: CGFloat = 20
}

private struct SweatButtonStyle: ButtonStyle {
    let style: SweatButton.Style

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(style.foreground)
            .background {
                if let background = style.background {
                    RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                        .fill(background)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
            // Figma에는 눌림 상태가 없다. iOS에서 반응 없는 버튼은 고장으로 읽히므로
            // 표준적인 최소한의 피드백만 넣는다.
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview("Button") {
    VStack(spacing: Space.x3) {
        SweatButton("다음") {}
        SweatButton("더위를 덜 느끼는 길로 이동해요  →", style: .dark) {}
        SweatButton("나중에 할게요", style: .ghost) {}
    }
    .padding(Space.gutter)
    .background(Surface.page)
}
