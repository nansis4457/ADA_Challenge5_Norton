import SwiftUI
import DesignSystem

/// 3단계 — 위치 권한 사전 안내.
///
/// 화면에 들어온 것만으로는 시스템 권한을 묻지 않는다. 사용자가 이유를 읽고
/// `위치 사용 허용하기`를 누른 순간에만 요청한다.
struct LocationStep: View {
    let flow: OnboardingFlow

    var body: some View {
        OnboardingStepScaffold(
            step: OnboardingCopy.Location.step,
            heading: OnboardingCopy.Location.heading,
            sub: OnboardingCopy.Location.sub
        ) {
            VStack(alignment: .leading, spacing: 0) {
                Divider().overlay(Ink.n900.opacity(0.16))

                Text(OnboardingCopy.Location.usageLabel)
                    .sweatType(.overline11)
                    .foregroundStyle(Ink.n500)
                    .padding(.top, Space.x4)

                usageCard
                    .padding(.top, Space.x1 + 2)
            }
        } actions: {
            VStack(spacing: Space.x2 + 2) {
                SweatButton(OnboardingCopy.Location.allow) {
                    Task { await flow.allowLocation() }
                }
                .disabled(flow.isRequestingLocation)

                SweatButton(OnboardingCopy.later, style: .ghost) {
                    flow.skipLocation()
                }
                .disabled(flow.isRequestingLocation)
            }
        }
    }

    private var usageCard: some View {
        VStack(alignment: .leading, spacing: Space.x1) {
            Text(OnboardingCopy.Location.usageTitle)
                .sweatType(.bodyStrong16)
                .foregroundStyle(Ink.n900)
            Text(OnboardingCopy.Location.usageBody)
                .sweatType(.body14)
                .foregroundStyle(Ink.n600)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.x4)
        .background(Surface.card, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
