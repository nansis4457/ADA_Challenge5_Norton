import Foundation
import UserNotifications

public final class SystemMovementNotificationScheduler: MovementNotificationScheduling {
    public static let waterReminderDelay: TimeInterval = 10 * 60

    private let center: any UserNotificationCenterClient

    public init(center: any UserNotificationCenterClient = SystemUserNotificationCenterClient()) {
        self.center = center
    }

    public func scheduleWaterReminder(for sessionID: UUID) async throws -> WaterReminderScheduleResult {
        let authorization = await center.authorizationStatus()
        let isAllowed: Bool
        switch authorization {
        case .authorized:
            isAllowed = true
        case .denied:
            isAllowed = false
        case .notDetermined:
            isAllowed = try await center.requestAuthorization()
        }

        guard isAllowed else { return .denied }
        let identifier = Self.identifier(for: sessionID)
        center.removePending(identifiers: [identifier])
        try await center.add(
            identifier: identifier,
            title: MovementNotificationCopy.waterTitle,
            body: MovementNotificationCopy.waterBody,
            after: Self.waterReminderDelay
        )
        return .scheduled
    }

    public func cancelWaterReminder(for sessionID: UUID) {
        center.removePending(identifiers: [Self.identifier(for: sessionID)])
    }

    public static func identifier(for sessionID: UUID) -> String {
        "move.water.\(sessionID.uuidString)"
    }
}

public final class SystemUserNotificationCenterClient: UserNotificationCenterClient {
    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func authorizationStatus() async -> MovementNotificationAuthorization {
        let settings = await center.notificationSettings()
        return switch settings.authorizationStatus {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .authorized, .provisional, .ephemeral: .authorized
        @unknown default: .denied
        }
    }

    public func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    public func add(
        identifier: String,
        title: String,
        body: String,
        after delay: TimeInterval
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await center.add(request)
    }

    public func removePending(identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
