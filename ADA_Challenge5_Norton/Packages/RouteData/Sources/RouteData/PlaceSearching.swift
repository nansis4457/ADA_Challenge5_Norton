import SweatDomain

/// 장소가 확정되기 전 자동완성 후보.
public struct PlaceSuggestion: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String

    public init(id: String, title: String, subtitle: String = "") {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }
}

public enum PlaceSearchError: Error, Sendable, Equatable {
    case unavailable
    case suggestionExpired
    case noResolvedPlace
}

/// 검색 문자열을 후보로 만들고, 선택한 후보를 좌표가 있는 장소로 확정한다.
@MainActor
public protocol PlaceSearching: AnyObject {
    func suggestions(for query: String, near coordinate: Coordinate?) async throws -> [PlaceSuggestion]
    func resolve(_ suggestion: PlaceSuggestion) async throws -> RoutePlace
    func cancel()
}
