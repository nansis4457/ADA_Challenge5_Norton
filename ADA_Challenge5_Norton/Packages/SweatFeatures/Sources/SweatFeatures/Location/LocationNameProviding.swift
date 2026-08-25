import CoreLocation
import Foundation
import MapKit
import SweatDomain

/// 좌표를 사용자가 알아볼 수 있는 지역명으로 바꾼다.
///
/// 위치 획득과 분리해 두면 날씨 조회는 역지오코딩 성공 여부에 의존하지 않고,
/// 테스트도 실제 네트워크 없이 이름 성공·실패를 재현할 수 있다.
public protocol LocationNameProviding: Sendable {
    func name(for coordinate: Coordinate) async -> String?
}

/// MapKit의 iOS 26 역지오코딩으로 현재 위치의 도시 이름을 가져온다.
///
/// 정확한 주소는 홈 날씨에 필요하지 않고 불필요하게 민감한 정보다. 그래서
/// `shortAddress`보다 `cityName`을 우선해 `포항시` 정도의 지역만 표시한다.
public struct SystemLocationNameProvider: LocationNameProviding {

    public init() {}

    public func name(for coordinate: Coordinate) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        request.preferredLocale = Locale(identifier: "ko_KR")

        guard let item = try? await request.mapItems.first else { return nil }
        return item.addressRepresentations?.cityName ?? item.address?.shortAddress
    }
}
