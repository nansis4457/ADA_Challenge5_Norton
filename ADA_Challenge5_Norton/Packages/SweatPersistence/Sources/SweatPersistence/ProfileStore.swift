import Foundation

/// 사용자 설정 저장소.
///
/// 저장 실패나 손상된 데이터로 앱이 멈추지 않는다. 읽지 못하면 기본값으로 시작한다.
/// 설정 몇 개 때문에 앱이 죽는 것보다 낫다.
///
/// - Note: `UserDefaults`는 Swift 6에서 `Sendable`이 아니지만 Apple 문서상
///   스레드 안전하다. 이 타입은 그 위에 상태를 더하지 않으므로 `@unchecked`가
///   안전하다. 상태를 추가하게 되면 이 판단을 다시 해야 한다.
public struct ProfileStore: @unchecked Sendable {

    private let defaults: UserDefaults
    private static let key = "sweat.userProfile"

    /// - Parameter defaults: 테스트에서는 별도 suite를 넘겨 실제 설정을 건드리지 않는다.
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// 저장된 설정. 없거나 읽지 못하면 기본값.
    public func load() -> UserProfile {
        guard let data = defaults.data(forKey: Self.key) else { return .default }
        do {
            return try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            // 손상된 데이터를 그대로 두면 매 실행 실패한다. 지우고 기본값으로 간다.
            defaults.removeObject(forKey: Self.key)
            return .default
        }
    }

    public func save(_ profile: UserProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: Self.key)
    }

    /// 테스트·디버그용 초기화.
    public func reset() {
        defaults.removeObject(forKey: Self.key)
    }
}
