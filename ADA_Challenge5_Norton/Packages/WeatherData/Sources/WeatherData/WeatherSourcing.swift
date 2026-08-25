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

    /// 시간별·주간 예보.
    ///
    /// 두 예보를 한 번에 돌려주는 이유는 **주간 단계가 시간별 값에서 나오기** 때문이다.
    /// 따로 받으면 두 요청의 시점이 어긋나 같은 날의 단계가 달라질 수 있다.
    func forecast(at coordinate: Coordinate) async throws -> WeatherForecast

    /// 화면에 표시할 출처 정보. **법적 요건이다.**
    func attribution() async throws -> WeatherAttributionInfo
}

/// 시간별과 주간을 함께 담는다.
public struct WeatherForecast: Sendable, Codable, Equatable {
    public let hourly: [HourlyForecast]
    public let daily: [DailyForecast]
    public let fetchedAt: Date

    public init(hourly: [HourlyForecast], daily: [DailyForecast], fetchedAt: Date) {
        self.hourly = hourly
        self.daily = daily
        self.fetchedAt = fetchedAt
    }
}
