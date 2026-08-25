import Foundation

/// 이동 종료 뒤 005 자가 기록 기능으로 넘기는 집계 값.
///
/// 원시 위치 이력은 보관하지 않는다. 분석하지 못한 실외 시간은 `nil`로 남긴다.
public struct MoveCompletion: Identifiable, Sendable, Codable, Equatable {
    public let id: UUID
    public let sessionID: UUID
    public let routeID: UUID
    public let startedAt: Date
    public let endedAt: Date
    public let elapsedTime: TimeInterval
    public let traveledDistanceMeters: Double
    public let fractionCompleted: Double
    public let observedOutdoorTime: TimeInterval?

    public init?(
        id: UUID = UUID(),
        sessionID: UUID,
        routeID: UUID,
        startedAt: Date,
        endedAt: Date,
        traveledDistanceMeters: Double,
        fractionCompleted: Double,
        observedOutdoorTime: TimeInterval? = nil
    ) {
        let elapsedTime = endedAt.timeIntervalSince(startedAt)
        guard startedAt.timeIntervalSinceReferenceDate.isFinite,
              endedAt.timeIntervalSinceReferenceDate.isFinite,
              elapsedTime.isFinite, elapsedTime >= 0,
              traveledDistanceMeters.isFinite, traveledDistanceMeters >= 0,
              fractionCompleted.isFinite, (0 ... 1).contains(fractionCompleted),
              observedOutdoorTime.map({ $0.isFinite && $0 >= 0 && $0 <= elapsedTime }) ?? true
        else { return nil }

        self.id = id
        self.sessionID = sessionID
        self.routeID = routeID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.elapsedTime = elapsedTime
        self.traveledDistanceMeters = traveledDistanceMeters
        self.fractionCompleted = fractionCompleted
        self.observedOutdoorTime = observedOutdoorTime
    }
}
