import Foundation

#if os(iOS)
import ActivityKit

public struct MoveActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public let fractionCompleted: Double
        public let remainingDistanceMeters: Double
        public let estimatedRemainingMinutes: Int
        public let elapsedMinutes: Int

        public init(
            fractionCompleted: Double,
            remainingDistanceMeters: Double,
            estimatedRemainingMinutes: Int,
            elapsedMinutes: Int
        ) {
            self.fractionCompleted = min(max(fractionCompleted, 0), 1)
            self.remainingDistanceMeters = max(remainingDistanceMeters, 0)
            self.estimatedRemainingMinutes = max(estimatedRemainingMinutes, 0)
            self.elapsedMinutes = max(elapsedMinutes, 0)
        }
    }

    public let sessionID: UUID
    public let originName: String
    public let destinationName: String

    public init(sessionID: UUID, originName: String, destinationName: String) {
        self.sessionID = sessionID
        self.originName = originName
        self.destinationName = destinationName
    }
}
#else
public struct MoveActivityAttributes: Codable, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public let fractionCompleted: Double
        public let remainingDistanceMeters: Double
        public let estimatedRemainingMinutes: Int
        public let elapsedMinutes: Int

        public init(
            fractionCompleted: Double,
            remainingDistanceMeters: Double,
            estimatedRemainingMinutes: Int,
            elapsedMinutes: Int
        ) {
            self.fractionCompleted = min(max(fractionCompleted, 0), 1)
            self.remainingDistanceMeters = max(remainingDistanceMeters, 0)
            self.estimatedRemainingMinutes = max(estimatedRemainingMinutes, 0)
            self.elapsedMinutes = max(elapsedMinutes, 0)
        }
    }

    public let sessionID: UUID
    public let originName: String
    public let destinationName: String

    public init(sessionID: UUID, originName: String, destinationName: String) {
        self.sessionID = sessionID
        self.originName = originName
        self.destinationName = destinationName
    }
}
#endif
