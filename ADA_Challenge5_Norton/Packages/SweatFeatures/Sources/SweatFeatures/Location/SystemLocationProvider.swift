import CoreLocation
import SweatDomain

/// 시스템에서 현재 위치를 받아온다.
///
/// 첫 좌표 하나만 필요하므로 받는 즉시 흐름을 끝낸다. 계속 추적하지 않는다 —
/// 홈 화면은 지금 어디인지만 알면 되고, 이동 추적은 004의 일이다.
public struct SystemLocationProvider: LocationProviding {

    public init() {}

    public func currentLocation() async -> LocationOutcome {
        do {
            for try await update in CLLocationUpdate.liveUpdates(.default) {
                if update.authorizationDenied || update.authorizationDeniedGlobally {
                    return .denied
                }
                if update.authorizationRestricted || update.locationUnavailable {
                    return .unavailable
                }
                if let location = update.location {
                    return .located(Coordinate(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    ))
                }
            }
            // 스트림이 좌표 없이 끝났다.
            return .unavailable
        } catch {
            return .unavailable
        }
    }
}
