import Foundation
import SweatDomain

public enum MovementEvent: Sendable, Equatable {
    case location(Coordinate, observedAt: Date, horizontalAccuracy: Double)
    case stationary(observedAt: Date)
    case unavailable(observedAt: Date)
    case authorizationDenied
}

public enum MovementTrackingError: Error, Sendable, Equatable {
    case unavailable
}

/// 활성 이동 동안 위치 이벤트를 제공한다.
public protocol MovementTracking: AnyObject {
    func updates() -> AsyncThrowingStream<MovementEvent, any Error>
    func stop()
}

/// 테스트·미리보기에서만 사용하는 고정 이벤트 공급자.
public final class FixtureMovementTracker: MovementTracking {
    private let events: [MovementEvent]
    private(set) public var didStop = false

    public init(events: [MovementEvent]) {
        self.events = events
    }

    public func updates() -> AsyncThrowingStream<MovementEvent, any Error> {
        AsyncThrowingStream { continuation in
            for event in events { continuation.yield(event) }
            continuation.finish()
        }
    }

    public func stop() {
        didStop = true
    }
}
