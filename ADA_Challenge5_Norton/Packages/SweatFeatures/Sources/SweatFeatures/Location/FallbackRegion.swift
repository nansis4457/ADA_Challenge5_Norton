import SweatDomain

/// 위치 권한 없이 쓸 수 있는 지역 목록.
///
/// 권한을 거부해도 앱이 동작해야 한다. 정식 장소 검색은 003의 경로 검색과 함께
/// 만들고, 여기서는 **고를 수 있는 최소한**만 둔다.
///
/// - Important: `id`는 저장 식별자다. 바꾸면 사용자가 고른 지역을 잃는다.
///   지역 이름은 여기 없다 — `HomeCopy`가 담당한다.
public enum FallbackRegion: String, CaseIterable, Sendable, Codable {
    case seoul
    case busan
    case daegu
    case incheon
    case gwangju
    case daejeon
    case pohang

    /// 각 지역의 대표 좌표.
    ///
    /// 시청 또는 그에 준하는 지점이다. 지역 단위 날씨를 보여주는 용도라
    /// 정밀할 필요는 없다.
    public var coordinate: Coordinate {
        switch self {
        case .seoul:   Coordinate(latitude: 37.5665, longitude: 126.9780)
        case .busan:   Coordinate(latitude: 35.1796, longitude: 129.0756)
        case .daegu:   Coordinate(latitude: 35.8714, longitude: 128.6014)
        case .incheon: Coordinate(latitude: 37.4563, longitude: 126.7052)
        case .gwangju: Coordinate(latitude: 35.1595, longitude: 126.8526)
        case .daejeon: Coordinate(latitude: 36.3504, longitude: 127.3845)
        case .pohang:  Coordinate(latitude: 36.0190, longitude: 129.3435)
        }
    }
}
