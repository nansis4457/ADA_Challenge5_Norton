import Foundation
import SweatDomain

public enum WalkingRouteError: Error, Sendable, Equatable {
    case unavailable
    case noRoute
}

@MainActor
public protocol WalkingRouteProviding: AnyObject {
    func routes(
        from origin: RoutePlace,
        to destination: RoutePlace,
        departingAt departureDate: Date
    ) async throws -> [WalkingRoute]
}
