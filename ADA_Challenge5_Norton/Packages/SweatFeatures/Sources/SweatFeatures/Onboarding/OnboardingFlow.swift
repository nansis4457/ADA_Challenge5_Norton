import SwiftUI
import SweatDomain
import SweatPersistence

/// 온보딩 진행 상태.
///
/// 두 가지 방식으로 들어온다.
/// - **최초 실행** — 1단계부터 4단계까지 순서대로, 끝나면 홈으로
/// - **편집** — 마이페이지에서 특정 단계 하나만, 저장하면 즉시 돌아간다
@Observable
public final class OnboardingFlow {

    public enum Step: Int, CaseIterable {
        case sensitivity = 0
        case movement
        case location
        case notification
    }

    public enum Mode: Hashable {
        /// 최초 실행. 4단계를 순서대로 거친다.
        case initial
        /// 마이페이지에서 값 하나를 고치러 들어왔다.
        case editing(Step)
    }

    public private(set) var profile: UserProfile
    public private(set) var step: Step
    public private(set) var isRequestingLocation = false
    public let mode: Mode

    private let store: ProfileStore
    private let location: any LocationProviding
    private let onFinish: () -> Void

    public init(
        store: ProfileStore,
        mode: Mode = .initial,
        location: any LocationProviding = SystemLocationProvider(),
        onFinish: @escaping () -> Void
    ) {
        self.store = store
        self.mode = mode
        self.location = location
        self.profile = store.load()
        self.onFinish = onFinish
        self.step = if case .editing(let target) = mode { target } else { .sensitivity }
    }

    // MARK: 표시 규칙

    /// 편집으로 들어왔을 때만 뒤로가기가 보인다.
    public var showsBackButton: Bool { mode != .initial }

    /// 편집에서는 한 단계만 고치고 나가므로 CTA가 `저장`이다.
    public var primaryActionTitle: String {
        mode == .initial ? OnboardingCopy.next : OnboardingCopy.save
    }

    /// 최초 온보딩에는 탭 바가 없다.
    public var showsTabBar: Bool { mode != .initial }

    // MARK: 선택

    public func select(_ value: Sensitivity) { profile.sensitivity = value }
    public func select(_ value: Transport) { profile.transport = value }
    public func select(_ value: OutdoorDuration) { profile.outdoorDuration = value }

    // MARK: 진행

    /// 다음 단계로. 편집 모드면 저장하고 즉시 끝낸다.
    public func advance() {
        guard mode == .initial else { return finish() }
        guard let next = Step(rawValue: step.rawValue + 1) else { return finish() }
        step = next
    }

    /// 안내 CTA를 누른 뒤에만 시스템 위치 권한을 요청한다.
    ///
    /// 허용·거부·사용 불가 모두 정상 결과다. 어느 경우든 알림 단계로 진행한다.
    public func allowLocation() async {
        guard !isRequestingLocation else { return }
        isRequestingLocation = true
        profile.usesCurrentLocation = true
        _ = await location.currentLocation()
        isRequestingLocation = false
        advance()
    }

    /// 시스템 권한을 묻지 않고 지역 선택 대안을 사용한다.
    public func skipLocation() {
        profile.usesCurrentLocation = false
        advance()
    }

    /// 알림을 허용하고 온보딩을 끝낸다.
    ///
    /// 권한 결과와 무관하게 온보딩은 완료된다. 거부했다고 앱을 못 쓰게 할 이유가 없다.
    public func allowNotifications() async {
        profile.wantsNotification = await NotificationPermission.request()
        finish()
    }

    /// 권한을 묻지 않고 끝낸다.
    public func skipNotifications() {
        profile.wantsNotification = false
        finish()
    }

    /// 편집을 취소하고 돌아간다. 저장하지 않는다.
    public func cancel() {
        profile = store.load()
        onFinish()
    }

    private func finish() {
        if mode == .initial { profile.hasCompletedOnboarding = true }
        store.save(profile)
        onFinish()
    }
}
