import SwiftUI

/// 자가 기록의 1~5점 선택. Figma `Score Button`.
///
/// 5개를 `HStack(spacing: Space.x2)`로 나란히 놓고 각각 폭을 채운다.
public struct ScoreButton: View {

    private let score: Int
    private let isSelected: Bool
    private let action: () -> Void

    public init(_ score: Int, isSelected: Bool, action: @escaping () -> Void) {
        self.score = score
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(String(score))
                .sweatType(Self.numberType)
                .foregroundStyle(isSelected ? OnColor.accent : Ink.n900)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Self.verticalPadding)
        }
        .buttonStyle(SelectableSurfaceStyle(
            isSelected: isSelected,
            cornerRadius: Radius.lg,
            selectedFill: Accent.base
        ))
        // 숫자만 읽으면 무엇의 점수인지 알 수 없다.
        .accessibilityLabel("\(score)점")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// - Note: Figma의 Score Button 숫자는 텍스트 스타일에 연결되어 있지 않다.
    ///   Semibold 20 / 자간 -2%를 직접 지정한 값이라 여기서도 같은 값을 만든다.
    ///   `Stat/20 Bold`는 Bold라 굵기가 다르다. 토큰 갭으로 기록해 둔다.
    private static let numberType = SweatTextStyle(
        figmaName: "Score Button 숫자",
        size: 20, weight: .semibold, lineHeightRatio: 1.2, tracking: -0.4
    )

    /// - Note: Figma 상하 여백 18. `space/*`에 없다 (16과 22 사이).
    private static let verticalPadding: CGFloat = 18
}

#Preview("Score Button") {
    VStack(spacing: Space.x2) {
        HStack(spacing: Space.x2) {
            ForEach(1...5, id: \.self) { n in
                ScoreButton(n, isSelected: n == 4) {}
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
    .padding(Space.gutter)
    .background(Surface.page)
}
