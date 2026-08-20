import Foundation
import WeatherKit
import CoreLocation
import SweatDomain

/// WeatherKit에서 현재 날씨를 가져온다.
///
/// **체감온도는 받아오지 않는다.** WeatherKit도 `apparentTemperature`를 주지만
/// 산식이 달라 쓰면 단계 기준이 둘이 된다. 기온과 습도만 받아 우리가 계산한다.
public struct WeatherKitSource: WeatherSourcing {

    private let service: WeatherService

    public init(service: WeatherService = .shared) {
        self.service = service
    }

    public func currentObservation(at coordinate: Coordinate) async throws -> WeatherObservation {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let current = try await service.weather(for: location).currentWeather
        return Self.observation(from: current)
    }

    /// WeatherKit 값을 도메인 형태로 옮긴다.
    ///
    /// - Note: `humidity`는 **0~1 비율**이다. 기상청 산식은 상대습도를 %로 받으므로
    ///   100을 곱해야 한다. 이걸 놓치면 습도가 78%가 아니라 0.78%로 들어가
    ///   체감온도가 통째로 어긋난다.
    static func observation(from current: CurrentWeather) -> WeatherObservation {
        WeatherObservation(
            temperature: current.temperature.converted(to: .celsius).value,
            relativeHumidity: current.humidity * 100,
            windSpeed: current.wind.speed.converted(to: .metersPerSecond).value,
            observedAt: current.date,
            source: .appleWeather
        )
    }
}
