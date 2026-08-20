import Foundation
import SweatDomain

/// 기기에 저장되는 사용자 설정.
///
/// 스칼라 몇 개뿐이라 키-값 저장을 쓴다. 날짜별로 쌓이고 집계가 필요한
/// 기록(`SweatLog`, 005)만 데이터베이스에 둔다.
///
/// - Important: 저장되는 구조다. 필드를 지우거나 이름을 바꾸면 기존 값을 읽지 못한다.
///   추가는 안전하다 — 디코딩 시 기본값이 채워진다.
public struct UserProfile: Codable, Sendable, Equatable {

    // MARK: 온보딩에서 정하는 값

    public var sensitivity: Sensitivity
    public var transport: Transport
    public var outdoorDuration: OutdoorDuration
    public var wantsNotification: Bool
    public var hasCompletedOnboarding: Bool

    // MARK: 기록에서 학습되는 값 (005)

    /// 자가 기록으로 학습된 개인 보정 (℃).
    public var calibrationOffset: Double
    /// 고습도 구간 추가 보정.
    public var humidityBoost: Double

    /// 아침 알림 시각 (0~23시).
    public var notificationHour: Int

    /// 아무것도 고르지 않은 상태의 기본값.
    ///
    /// 온보딩 각 단계는 이 값이 이미 선택된 채로 시작한다.
    public static let `default` = UserProfile(
        sensitivity: .normal,
        transport: .subway,
        outdoorDuration: .twentyToForty,
        wantsNotification: false,
        hasCompletedOnboarding: false,
        calibrationOffset: 0,
        humidityBoost: 0,
        notificationHour: 7
    )

    public init(
        sensitivity: Sensitivity,
        transport: Transport,
        outdoorDuration: OutdoorDuration,
        wantsNotification: Bool,
        hasCompletedOnboarding: Bool,
        calibrationOffset: Double,
        humidityBoost: Double,
        notificationHour: Int
    ) {
        self.sensitivity = sensitivity
        self.transport = transport
        self.outdoorDuration = outdoorDuration
        self.wantsNotification = wantsNotification
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.calibrationOffset = calibrationOffset
        self.humidityBoost = humidityBoost
        self.notificationHour = notificationHour
    }

    /// 필드가 늘어나도 기존 저장값을 읽을 수 있도록 하나씩 기본값으로 채운다.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Self.default
        sensitivity = try c.decodeIfPresent(Sensitivity.self, forKey: .sensitivity) ?? d.sensitivity
        transport = try c.decodeIfPresent(Transport.self, forKey: .transport) ?? d.transport
        outdoorDuration = try c.decodeIfPresent(OutdoorDuration.self, forKey: .outdoorDuration) ?? d.outdoorDuration
        wantsNotification = try c.decodeIfPresent(Bool.self, forKey: .wantsNotification) ?? d.wantsNotification
        hasCompletedOnboarding = try c.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? d.hasCompletedOnboarding
        calibrationOffset = try c.decodeIfPresent(Double.self, forKey: .calibrationOffset) ?? d.calibrationOffset
        humidityBoost = try c.decodeIfPresent(Double.self, forKey: .humidityBoost) ?? d.humidityBoost
        notificationHour = try c.decodeIfPresent(Int.self, forKey: .notificationHour) ?? d.notificationHour
    }
}
