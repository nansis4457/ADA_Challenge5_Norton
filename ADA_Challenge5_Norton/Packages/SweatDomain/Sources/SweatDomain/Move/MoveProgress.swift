import Foundation

/// 관측 위치 하나에서 계산한 이동 진행 값.
public struct MoveProgress: Sendable, Codable, Equatable {
    public let sessionID: UUID
    public let routeID: UUID
    public let observedAt: Date
    public let elapsedTime: TimeInterval
    public let traveledDistanceMeters: Double
    public let remainingDistanceMeters: Double
    public let estimatedRemainingTime: TimeInterval
    public let fractionCompleted: Double

    public init?(
        sessionID: UUID,
        routeID: UUID,
        observedAt: Date,
        elapsedTime: TimeInterval,
        traveledDistanceMeters: Double,
        remainingDistanceMeters: Double,
        estimatedRemainingTime: TimeInterval,
        fractionCompleted: Double
    ) {
        guard observedAt.timeIntervalSinceReferenceDate.isFinite,
              elapsedTime.isFinite, elapsedTime >= 0,
              traveledDistanceMeters.isFinite, traveledDistanceMeters >= 0,
              remainingDistanceMeters.isFinite, remainingDistanceMeters >= 0,
              estimatedRemainingTime.isFinite, estimatedRemainingTime >= 0,
              fractionCompleted.isFinite, (0 ... 1).contains(fractionCompleted)
        else { return nil }

        self.sessionID = sessionID
        self.routeID = routeID
        self.observedAt = observedAt
        self.elapsedTime = elapsedTime
        self.traveledDistanceMeters = traveledDistanceMeters
        self.remainingDistanceMeters = remainingDistanceMeters
        self.estimatedRemainingTime = estimatedRemainingTime
        self.fractionCompleted = fractionCompleted
    }
}
