import SwiftUI
import DesignSystem
import SweatDomain

/// 1단계 — 땀 민감도.
struct SensitivityStep: View {
    let flow: OnboardingFlow

    var body: some View {
        OnboardingStepScaffold(
            step: OnboardingCopy.Sensitivity.step,
            heading: OnboardingCopy.Sensitivity.heading,
            sub: OnboardingCopy.Sensitivity.sub,
            showsBack: flow.showsBackButton,
            onBack: flow.cancel
        ) {
            VStack(spacing: Space.x2 + 2) {
                ForEach(Sensitivity.allCases, id: \.self) { option in
                    SelectableCard(
                        title: OnboardingCopy.Sensitivity.title(option),
                        description: OnboardingCopy.Sensitivity.description(option),
                        isSelected: flow.profile.sensitivity == option
                    ) { flow.select(option) }
                }
            }
        } actions: {
            SweatButton(flow.primaryActionTitle) { flow.advance() }
        }
    }
}
