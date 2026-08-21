import Foundation

/// 한 시각의 예보.
public struct HourlyForecast: Sendable, Codable, Equatable {
    public let date: Date
    public let temperature: Double
    public let relativeHumidity: Double

    public init(date: Date, temperature: Double, relativeHumidity: Double) {
        self.date = date
        self.temperature = temperature
        self.relativeHumidity = relativeHumidity
    }

    /// 기상청 산식으로 계산한 체감온도.
    public var apparentTemperature: Double {
        ApparentTemperature.summer(temperature: temperature, relativeHumidity: relativeHumidity)
    }
}

/// 하루의 예보.
///
/// 화면은 최저~최고 범위 막대와 그날의 단계를 보여준다.
/// 단계는 **그날 가장 힘든 때**를 기준으로 한다 — 하루 중 언제가 문제인지 알려주는 게
/// 이 앱의 목적이고, 평균을 내면 그 정보가 사라진다.
public struct DailyForecast: Sendable, Codable, Equatable {
    public let date: Date
    public let lowTemperature: Double
    public let highTemperature: Double

    /// 그날 최고 체감온도 (℃).
    ///
    /// 시간별 예보가 있으면 그중 최댓값이다. 없으면 근사한 값이며
    /// 그 경우 `isApparentHighEstimated`가 `true`다.
    public let apparentHigh: Double

    /// `apparentHigh`가 시간별 값이 아니라 근사인가.
    ///
    /// 시간별 예보는 며칠까지만 제공되므로 먼 날짜는 근사할 수밖에 없다.
    /// 화면에서 이 값을 근거로 표기를 달리할 수 있다 (「추정치는 추정치로」).
    public let isApparentHighEstimated: Bool

    public init(
        date: Date,
        lowTemperature: Double,
        highTemperature: Double,
        apparentHigh: Double,
        isApparentHighEstimated: Bool
    ) {
        self.date = date
        self.lowTemperature = lowTemperature
        self.highTemperature = highTemperature
        self.apparentHigh = apparentHigh
        self.isApparentHighEstimated = isApparentHighEstimated
    }
}

/// 시간별 예보에서 하루의 최고 체감온도를 뽑는다.
public enum DailyApparentHigh {

    /// 같은 날짜에 속하는 시간별 예보 중 체감온도 최댓값.
    ///
    /// - Returns: 해당 날짜의 시간별 예보가 하나도 없으면 `nil`.
    public static func fromHourly(
        _ hourly: [HourlyForecast],
        on day: Date,
        calendar: Calendar = .current
    ) -> Double? {
        hourly
            .filter { calendar.isDate($0.date, inSameDayAs: day) }
            .map(\.apparentTemperature)
            .max()
    }

    /// 시간별 예보가 없을 때의 근사.
    ///
    /// 최고기온과 **최저습도**를 짝지어 계산한다. 둘 다 대개 한낮에 나타나므로
    /// 최대습도(주로 새벽, 기온이 낮을 때)를 쓰는 것보다 실제에 가깝다.
    ///
    /// **근사다.** 실제 최고 체감온도가 나타나는 시각의 습도와는 다를 수 있다.
    public static func estimate(highTemperature: Double, minimumHumidity: Double) -> Double {
        ApparentTemperature.summer(
            temperature: highTemperature,
            relativeHumidity: minimumHumidity
        )
    }
}
