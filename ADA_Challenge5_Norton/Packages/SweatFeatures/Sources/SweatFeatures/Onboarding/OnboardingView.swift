import SwiftUI

/// 온보딩 세 단계를 감싼다.
public struct OnboardingView: View {
    @State private var flow: OnboardingFlow

    public init(flow: OnboardingFlow) {
        _flow = State(initialValue: flow)
    }

    public var body: some View {
        switch flow.step {
        case .sensitivity:  SensitivityStep(flow: flow)
        case .movement:     MovementStep(flow: flow)
        case .notification: NotificationStep(flow: flow)
        }
    }
}
