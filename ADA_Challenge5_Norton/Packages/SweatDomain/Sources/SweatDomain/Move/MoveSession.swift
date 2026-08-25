import Foundation

/// 한 번에 하나만 활성화되는 이동 세션.
public struct MoveSession: Identifiable, Sendable, Codable, Equatable {
    public let id: UUID
    public let route: WalkingRoute
    public let startedAt: Date

    public init?(
        id: UUID = UUID(),
        route: WalkingRoute,
        startedAt: Date
    ) {
        guard startedAt.timeIntervalSinceReferenceDate.isFinite else { return nil }
        self.id = id
        self.route = route
        self.startedAt = startedAt
    }
}
