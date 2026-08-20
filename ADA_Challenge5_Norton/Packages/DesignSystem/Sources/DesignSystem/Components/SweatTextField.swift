import SwiftUI

/// 라벨이 붙은 입력 필드. Figma `Text Field`.
///
/// 경로 화면의 출발·도착 입력에 쓴다.
/// Figma는 값이 채워진 모습만 보여주지만, 실제 화면에서는 편집이 필요하므로
/// 값을 바인딩으로 받는다.
public struct SweatTextField: View {

    private let label: String
    private let placeholder: String
    @Binding private var text: String

    public init(_ label: String, placeholder: String = "", text: Binding<String>) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .sweatType(.overline11)
                .foregroundStyle(Ink.n500)

            TextField(placeholder, text: $text)
                .sweatType(.input17)
                .foregroundStyle(Ink.n900)
                .tint(Accent.base)
                .textFieldStyle(.plain)
                .padding(.vertical, Self.verticalPadding)
                .padding(.horizontal, Self.horizontalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Surface.card,
                    in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                )
                // 라벨이 시각적으로만 붙어 있으면 VoiceOver는 값만 읽는다 (규칙 「접근성은 마감이 아니다」).
                .accessibilityLabel(label)
        }
    }

    /// - Note: Figma 여백 14 / 15. 둘 다 `space/*`에 없다 (12과 16 사이).
    private static let verticalPadding: CGFloat = 14
    private static let horizontalPadding: CGFloat = 15
}

#Preview("Text Field") {
    @Previewable @State var from = "성수역 3번 출구"
    @Previewable @State var to = "한양대 정문"

    VStack(spacing: Space.x3 + 2) {
        SweatTextField("출발", text: $from)
        SweatTextField("도착", text: $to)
        SweatTextField("경유지", placeholder: "선택 사항", text: .constant(""))
    }
    .padding(Space.gutter)
    .background(Surface.page)
}
