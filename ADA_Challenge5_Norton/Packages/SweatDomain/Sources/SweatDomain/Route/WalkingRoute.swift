import Foundation

/// 도보 경로에서 사용자에게 설명할 주요 구간.
public struct RouteStep: Identifiable, Sendable, Codable, Equatable, Hashable {
    public let id: UUID
    public let instruction: String
    public let distanceMeters: Double
    public let expectedTravelTime: TimeInterval
    public let path: [Coordinate]

    public init?(
        id: UUID = UUID(),
        instruction: String,
        distanceMeters: Double,
        expectedTravelTime: TimeInterval,
        path: [Coordinate]
    ) {
        guard distanceMeters.isFinite, distanceMeters >= 0,
              expectedTravelTime.isFinite, expectedTravelTime >= 0,
              path.allSatisfy(\.isValid) else { return nil }

        self.id = id
        self.instruction = instruction.trimmingCharacters(in: .whitespacesAndNewlines)
        self.distanceMeters = distanceMeters
        self.expectedTravelTime = expectedTravelTime
        self.path = path
    }
}

/// 공급자와 무관한 도보 경로 후보.
public struct WalkingRoute: Identifiable, Sendable, Codable, Equatable {
    public let id: UUID
    public let origin: RoutePlace
    public let destination: RoutePlace
    public let distanceMeters: Double
    public let expectedTravelTime: TimeInterval
    public let path: [Coordinate]
    public let steps: [RouteStep]
    public var exposure: ExposureAnalysis?

    public init?(
        id: UUID = UUID(),
        origin: RoutePlace,
        destination: RoutePlace,
        distanceMeters: Double,
        expectedTravelTime: TimeInterval,
        path: [Coordinate],
        steps: [RouteStep] = [],
        exposure: ExposureAnalysis? = nil
    ) {
        guard distanceMeters.isFinite, distanceMeters > 0,
              expectedTravelTime.isFinite, expectedTravelTime > 0,
              path.count >= 2,
              path.allSatisfy(\.isValid) else { return nil }

        self.id = id
        self.origin = origin
        self.destination = destination
        self.distanceMeters = distanceMeters
        self.expectedTravelTime = expectedTravelTime
        self.path = path
        self.steps = steps
        self.exposure = exposure
    }
}
