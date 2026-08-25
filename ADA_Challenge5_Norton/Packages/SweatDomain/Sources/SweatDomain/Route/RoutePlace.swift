import Foundation

/// 경로의 출발지 또는 도착지로 확정된 장소.
///
/// 검색 중인 문자열과 다르게 좌표까지 있어야 한다. 지도 공급자 타입을 저장하지 않아
/// MapKit에서 네이버 지도로 바뀌어도 화면 상태는 유지된다.
public struct RoutePlace: Identifiable, Sendable, Codable, Equatable, Hashable {
    public let id: UUID
    public let name: String
    public let detail: String?
    public let coordinate: Coordinate

    public init?(
        id: UUID = UUID(),
        name: String,
        detail: String? = nil,
        coordinate: Coordinate
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, coordinate.isValid else { return nil }

        let trimmedDetail = detail?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.id = id
        self.name = trimmedName
        self.detail = trimmedDetail?.isEmpty == false ? trimmedDetail : nil
        self.coordinate = coordinate
    }
}
