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

    public func forecast(at coordinate: Coordinate) async throws -> WeatherForecast {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let weather = try await service.weather(for: location)
        let hourly = weather.hourlyForecast.map(Self.hourly(from:))
        let daily = weather.dailyForecast.map { Self.daily(from: $0, hourly: hourly) }
        return WeatherForecast(hourly: hourly, daily: daily, fetchedAt: Date())
    }

    public func attribution() async throws -> WeatherAttributionInfo {
        let source = try await service.attribution
        return WeatherAttributionInfo(
            serviceName: source.serviceName,
            legalText: source.legalAttributionText,
            legalPageURL: source.legalPageURL,
            markLightURL: source.combinedMarkLightURL,
            markDarkURL: source.combinedMarkDarkURL
        )
    }

    static func hourly(from hour: HourWeather) -> HourlyForecast {
        HourlyForecast(
            date: hour.date,
            temperature: hour.temperature.converted(to: .celsius).value,
            relativeHumidity: hour.humidity * 100
        )
    }

    /// 하루 예보를 도메인 형태로.
    ///
    /// 단계는 **그날 최고 체감온도**로 정한다. 시간별 예보에 그 날짜가 있으면
    /// 거기서 최댓값을 뽑고, 없으면 근사한다.
    ///
    /// - Note: `DayWeather`에는 습도 대푯값이 없고 최대·최소만 있다. 최댓값은 주로
    ///   기온이 낮은 새벽에 나타나므로, 근사에는 **최저습도**를 쓴다. 최고기온과
    ///   대개 같은 시간대다.
    static func daily(from day: DayWeather, hourly: [HourlyForecast]) -> DailyForecast {
        let high = day.highTemperature.converted(to: .celsius).value
        let low = day.lowTemperature.converted(to: .celsius).value
        let fromHourly = DailyApparentHigh.fromHourly(hourly, on: day.date)
        return DailyForecast(
            date: day.date,
            lowTemperature: low,
            highTemperature: high,
            apparentHigh: fromHourly ?? DailyApparentHigh.estimate(
                highTemperature: high,
                minimumHumidity: day.minimumHumidity * 100
            ),
            isApparentHighEstimated: fromHourly == nil
        )
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
