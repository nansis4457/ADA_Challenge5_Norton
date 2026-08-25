import Foundation

/// 지점 좌표.
///
/// 위치 프레임워크 타입을 도메인에 들이지 않기 위한 최소 표현이다.
/// 003의 경로 계산도 같은 타입을 쓴다.
public struct Coordinate: Sendable, Codable, Equatable, Hashable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// 지구 표면의 유효한 위·경도인가.
    public var isValid: Bool {
        latitude.isFinite && longitude.isFinite
            && (-90 ... 90).contains(latitude)
            && (-180 ... 180).contains(longitude)
    }
}
