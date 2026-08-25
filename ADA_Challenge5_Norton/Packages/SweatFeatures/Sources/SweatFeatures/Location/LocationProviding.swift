import SweatDomain

/// 현재 위치를 알아낸 결과.
///
/// 거부는 **오류가 아니라 정상적인 결과**다. 사용자가 위치를 안 주기로 한 것이고
/// 앱은 그 상태에서도 동작해야 한다. 그래서 `throws` 대신 값으로 돌려준다.
public enum LocationOutcome: Sendable, Equatable {
    case located(Coordinate)
    /// 사용자가 사전 안내에서 `나중에`를 골라 시스템 권한을 아직 묻지 않았다.
    case deferred
    /// 사용자가 권한을 거부했다. 지역을 직접 고르게 한다.
    case denied
    /// 기기나 서비스 문제로 위치를 알 수 없다. 거부와 구분해 다르게 안내한다.
    case unavailable
}

/// 현재 위치를 제공한다.
///
/// 프로토콜로 두는 이유는 화면 테스트 때문이다. 시뮬레이터에서 권한 거부 상태를
/// 만들어 매번 재현하는 것보다, 거부를 돌려주는 구현을 끼우는 편이 빠르고 확실하다.
public protocol LocationProviding: Sendable {
    func currentLocation() async -> LocationOutcome
}
