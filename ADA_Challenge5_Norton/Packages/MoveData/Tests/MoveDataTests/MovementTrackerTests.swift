import Foundation
import SweatDomain
import Testing
@testable import MoveData

@Suite("이동 위치 공급자")
struct MovementTrackerTests {
    @Test("고정 공급자는 이벤트 순서를 유지하고 종료를 기록한다")
    func fixtureEventsAndStop() async throws {
        let date = Date(timeIntervalSinceReferenceDate: 1)
        let coordinate = Coordinate(latitude: 37.5, longitude: 127)
        let tracker = FixtureMovementTracker(events: [
            .location(coordinate, observedAt: date, horizontalAccuracy: 3),
            .stationary(observedAt: date),
        ])
        var received: [MovementEvent] = []

        for try await event in tracker.updates() { received.append(event) }
        tracker.stop()

        #expect(received.count == 2)
        #expect(received.first == .location(coordinate, observedAt: date, horizontalAccuracy: 3))
        #expect(tracker.didStop)
    }
}
