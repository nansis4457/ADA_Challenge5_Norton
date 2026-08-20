import Foundation
import SweatDomain

/// 날씨를 가져오는 곳.
///
/// 저장소가 이 프로토콜에만 의존하므로, 테스트는 실제 네트워크나 계정 설정 없이
/// 실패 경로까지 전부 검증할 수 있다. 나중에 기상청 실황을 얹을 때도 여기에
/// 구현을 하나 더 붙이면 된다.
public protocol WeatherSourcing: Sendable {
    /// 해당 좌표의 현재 날씨.
    func currentObservation(at coordinate: Coordinate) async throws -> WeatherObservation
}
