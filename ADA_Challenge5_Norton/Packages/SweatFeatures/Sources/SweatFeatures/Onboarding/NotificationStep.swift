import SwiftUI
import DesignSystem

/// 3단계 — 알림 권한.
///
/// 편집 모드로는 들어오지 않는다. 권한은 시스템 설정에서 바꾸는 값이다.
struct NotificationStep: View {
    let flow: OnboardingFlow

    var body: some View {
        OnboardingStepScaffold(
            step: OnboardingCopy.Notification.step,
            heading: OnboardingCopy.Notification.heading,
            sub: OnboardingCopy.Notification.sub
        ) {
            VStack(alignment: .leading, spacing: 0) {
                Divider().overlay(Ink.n900.opacity(0.16))

                Text(OnboardingCopy.Notification.previewLabel)
                    .sweatType(.overline11)
                    .foregroundStyle(Ink.n500)
                    .padding(.top, Space.x4)

                preview
                    .padding(.top, Space.x1 + 2)
            }
        } actions: {
            VStack(spacing: Space.x2 + 2) {
                SweatButton(OnboardingCopy.Notification.allow) {
                    Task { await flow.allowNotifications() }
                }
                SweatButton(OnboardingCopy.Notification.later, style: .ghost) {
                    flow.skipNotifications()
                }
            }
        }
    }

    /// 실제로 받게 될 알림의 모양. 문구는 개발가이드 §7에서 온다.
    private var preview: some View {
        VStack(alignment: .leading, spacing: Space.x1) {
            Text(OnboardingCopy.Notification.previewTitle)
                .sweatType(.bodyStrong16)
                .foregroundStyle(Ink.n900)
            Text(OnboardingCopy.Notification.previewBody)
                .sweatType(.body14)
                .foregroundStyle(Ink.n600)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.x4)
        .background(Surface.card, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        // 알림 하나로 읽히게 묶는다. 제목과 본문을 따로 읽으면 맥락이 끊긴다.
        .accessibilityElement(children: .combine)
    }
}
