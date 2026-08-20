import SwiftUI
import DesignSystem
import SweatDomain

/// 2단계 — 이동 패턴.
struct MovementStep: View {
    let flow: OnboardingFlow

    var body: some View {
        OnboardingStepScaffold(
            step: OnboardingCopy.Movement.step,
            heading: OnboardingCopy.Movement.heading,
            sub: OnboardingCopy.Movement.sub,
            showsBack: flow.showsBackButton,
            onBack: flow.cancel
        ) {
            VStack(alignment: .leading, spacing: 0) {
                Text(OnboardingCopy.Movement.transportLabel)
                    .sweatType(.caption13)
                    .foregroundStyle(Ink.n500)

                chipRow(Transport.allCases, selected: flow.profile.transport,
                        title: OnboardingCopy.Movement.title) { flow.select($0) }
                    .padding(.top, Space.x2)

                Text(OnboardingCopy.Movement.durationLabel)
                    .sweatType(.caption13)
                    .foregroundStyle(Ink.n500)
                    .padding(.top, Space.x6)

                chipRow(OutdoorDuration.allCases, selected: flow.profile.outdoorDuration,
                        title: OnboardingCopy.Movement.title) { flow.select($0) }
                    .padding(.top, Space.x2)
            }
        } actions: {
            SweatButton(flow.primaryActionTitle) { flow.advance() }
        }
    }

    /// 칩이 접근성 크기에서 넘치지 않도록 줄바꿈되는 배치.
    private func chipRow<Value: Hashable>(
        _ values: [Value],
        selected: Value,
        title: @escaping (Value) -> String,
        select: @escaping (Value) -> Void
    ) -> some View {
        FlowLayout(spacing: Space.x2) {
            ForEach(values, id: \.self) { value in
                SweatChip(title(value), isOn: selected == value) { select(value) }
            }
        }
    }
}

/// 폭이 모자라면 다음 줄로 넘기는 배치.
///
/// 접근성 글자 크기에서 칩이 화면 밖으로 나가지 않게 한다.
struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: width, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
