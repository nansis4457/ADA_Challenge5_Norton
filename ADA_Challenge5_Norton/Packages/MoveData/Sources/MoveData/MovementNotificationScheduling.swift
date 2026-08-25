import Foundation

public enum MovementNotificationAuthorization: Sendable, Equatable {
    case notDetermined
    case denied
    case authorized
}

public enum WaterReminderScheduleResult: Sendable, Equatable {
    case scheduled
    case denied
}

public protocol MovementNotificationScheduling {
    func scheduleWaterReminder(for sessionID: UUID) async throws -> WaterReminderScheduleResult
    func cancelWaterReminder(for sessionID: UUID)
}

/// 시스템 알림 센터를 작은 값 경계로 감싼다.
public protocol UserNotificationCenterClient {
    func authorizationStatus() async -> MovementNotificationAuthorization
    func requestAuthorization() async throws -> Bool
    func add(
        identifier: String,
        title: String,
        body: String,
        after delay: TimeInterval
    ) async throws
    func removePending(identifiers: [String])
}

public enum MovementNotificationCopy {
    public static let waterTitle = "물 한 잔 어떠세요?"
    public static let waterBody = "이동 중이라면 잠깐 물을 마시고 상태를 확인해보세요."
}
