#if DEBUG
import Foundation
import SweatDomain
import WeatherData

/// 수동 검증용 날씨 주입 (T092).
///
/// 6단계와 실패 화면은 실제 날씨로는 볼 수 없다. 8월 한국이 6단계가 되기를
/// 기다릴 수 없고, 시뮬레이터의 네트워크를 마음대로 끊을 수도 없다.
/// 그래서 **Debug 빌드에서만** 실행 인자로 값을 밀어 넣는다.
///
///     xcrun simctl launch <udid> <bundle-id> -stub-temperature 39 -stub-humidity 70
///     xcrun simctl launch <udid> <bundle-id> -stub-failure
///
/// 출처 표기는 지어내지 않는다. 법적 요건이라 실제 `WeatherKitSource`에서 받아온다.
struct WeatherHarness: WeatherSourcing {

    let temperature: Double
    let relativeHumidity: Double
    let windSpeed: Double
    /// 항상 실패한다. 오프라인·장애 화면(R10, R11)을 보기 위한 모드.
    let alwaysFails: Bool

    private let real = WeatherKitSource()

    struct Failure: Error {}

    /// 실행 인자에 주입 지시가 있으면 만든다. 없으면 `nil`.
    static func fromLaunchArguments(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> WeatherHarness? {
        func value(_ name: String) -> Double? {
            guard let index = arguments.firstIndex(of: name), index + 1 < arguments.count else { return nil }
            return Double(arguments[index + 1])
        }
        let fails = arguments.contains("-stub-failure")
        guard fails || value("-stub-temperature") != nil else { return nil }

        return WeatherHarness(
            temperature: value("-stub-temperature") ?? 30,
            relativeHumidity: value("-stub-humidity") ?? 70,
            windSpeed: value("-stub-wind") ?? 1.1,
            alwaysFails: fails
        )
    }

    func currentObservation(at coordinate: Coordinate) async throws -> WeatherObservation {
        if alwaysFails { throw Failure() }
        return WeatherObservation(
            temperature: temperature,
            relativeHumidity: relativeHumidity,
            windSpeed: windSpeed,
            observedAt: Date(),
            source: .appleWeather
        )
    }

    func forecast(at coordinate: Coordinate) async throws -> WeatherForecast {
        if alwaysFails { throw Failure() }

        let now = Date()
        let calendar = Calendar.current
        // 낮에 오르고 밤에 내려가는 하루를 흉내 낸다. 단계가 시간마다 달라져야
        // 예보 칸의 표정이 제대로 갈리는지 볼 수 있다.
        let hourly = (0..<24).map { offset in
            HourlyForecast(
                date: calendar.date(byAdding: .hour, value: offset, to: now) ?? now,
                temperature: temperature - Double(offset % 8) * 0.9,
                relativeHumidity: relativeHumidity
            )
        }
        let daily = (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: now) ?? now
            let high = temperature - Double(offset)
            return DailyForecast(
                date: date,
                lowTemperature: high - 6,
                highTemperature: high,
                apparentHigh: ApparentTemperature.summer(temperature: high, relativeHumidity: relativeHumidity),
                isApparentHighEstimated: offset > 2
            )
        }
        return WeatherForecast(hourly: hourly, daily: daily, fetchedAt: now)
    }

    func attribution() async throws -> WeatherAttributionInfo {
        try await real.attribution()
    }
}
#endif
