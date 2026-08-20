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
                .sweatType(.stat20)
                .foregroundStyle(isSelected ? OnColor.accent : Ink.n900)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Space.x4)
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
