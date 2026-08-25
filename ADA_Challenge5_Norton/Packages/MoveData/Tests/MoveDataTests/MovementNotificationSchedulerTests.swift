import Foundation
import Testing
@testable import MoveData

@Suite("이동 알림")
struct MovementNotificationSchedulerTests {
    @Test("허용 상태에서는 10분 뒤 같은 세션 식별자로 한 번 예약한다")
    func schedulesOneReminder() async throws {
        let center = FakeNotificationCenter(status: .authorized)
        let scheduler = SystemMovementNotificationScheduler(center: center)
        let sessionID = UUID()

        #expect(try await scheduler.scheduleWaterReminder(for: sessionID) == .scheduled)
        #expect(center.added.count == 1)
        #expect(center.added.first?.identifier == SystemMovementNotificationScheduler.identifier(for: sessionID))
        #expect(center.added.first?.delay == 600)
        #expect(center.removed == [[SystemMovementNotificationScheduler.identifier(for: sessionID)]])
    }

    @Test("미결정이면 한 번 요청하고 거부 시 예약하지 않는다")
    func deniedRequestDoesNotSchedule() async throws {
        let center = FakeNotificationCenter(status: .notDetermined, requestResult: false)
        let scheduler = SystemMovementNotificationScheduler(center: center)

        #expect(try await scheduler.scheduleWaterReminder(for: UUID()) == .denied)
        #expect(center.requestCalls == 1)
        #expect(center.added.isEmpty)
    }

    @Test("종료 시 해당 세션 알림만 취소한다")
    func cancelsSessionReminder() {
        let center = FakeNotificationCenter(status: .authorized)
        let scheduler = SystemMovementNotificationScheduler(center: center)
        let sessionID = UUID()

        scheduler.cancelWaterReminder(for: sessionID)

        #expect(center.removed == [[SystemMovementNotificationScheduler.identifier(for: sessionID)]])
    }
}

@MainActor
private final class FakeNotificationCenter: UserNotificationCenterClient {
    struct Added: Equatable {
        let identifier: String
        let title: String
        let body: String
        let delay: TimeInterval
    }

    let status: MovementNotificationAuthorization
    let requestResult: Bool
    private(set) var requestCalls = 0
    private(set) var added: [Added] = []
    private(set) var removed: [[String]] = []

    init(status: MovementNotificationAuthorization, requestResult: Bool = true) {
        self.status = status
        self.requestResult = requestResult
    }

    func authorizationStatus() async -> MovementNotificationAuthorization { status }

    func requestAuthorization() async throws -> Bool {
        requestCalls += 1
        return requestResult
    }

    func add(
        identifier: String,
        title: String,
        body: String,
        after delay: TimeInterval
    ) async throws {
        added.append(Added(identifier: identifier, title: title, body: body, delay: delay))
    }

    func removePending(identifiers: [String]) {
        removed.append(identifiers)
    }
}
