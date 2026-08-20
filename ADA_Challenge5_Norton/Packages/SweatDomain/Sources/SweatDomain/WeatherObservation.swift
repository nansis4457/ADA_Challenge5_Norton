import Foundation

/// 날씨 값이 어디서 왔는지.
///
/// 값마다 출처를 들고 다닌다. 소스가 하나뿐인 지금은 과해 보이지만,
/// **출처 표기가 법적 요건**이고 나중에 소스를 더할 때 화면을 고치지 않기 위해서다.
public enum WeatherSource: String, Sendable, Codable, CaseIterable {
    case appleWeather
}

/// 한 시점의 날씨.
///
/// - Important: 이름을 `Observation`으로 두면 **Apple의 `Observation` 모듈을 가린다.**
///   `@Observable` 매크로가 확장될 때 `Observation.Observable`을 참조하는데,
///   같은 이름의 타입이 있으면 모듈 대신 그 타입으로 해석되어
///   다른 패키지의 `@Observable`이 컴파일되지 않는다.
///   패키지 단위 빌드에서는 드러나지 않고 앱을 링크할 때 터진다.
///
/// 체감온도는 저장하지 않고 **계산한다.** 소스가 주는 체감온도는 산식이 달라
/// 쓰지 않는다 — 그러면 단계 기준이 둘이 된다.
public struct WeatherObservation: Sendable, Codable, Equatable {

    /// 기온 (℃)
    public let temperature: Double
    /// 상대습도 (%)
    public let relativeHumidity: Double
    /// 풍속 (m/s). 체감온도에는 **들어가지 않는다** — 설명과 추천에만 쓴다.
    public let windSpeed: Double
    /// 이 값이 관측·예측된 시각
    public let observedAt: Date
    public let source: WeatherSource

    public init(
        temperature: Double,
        relativeHumidity: Double,
        windSpeed: Double,
        observedAt: Date,
        source: WeatherSource
    ) {
        self.temperature = temperature
        self.relativeHumidity = relativeHumidity
        self.windSpeed = windSpeed
        self.observedAt = observedAt
        self.source = source
    }

    /// 기상청 산식으로 계산한 체감온도 (℃).
    public var apparentTemperature: Double {
        ApparentTemperature.summer(
            temperature: temperature,
            relativeHumidity: relativeHumidity
        )
    }

    /// 관측 시각으로부터 흐른 시간.
    ///
    /// 화면의 `n분 전` 배지가 이 값을 쓴다. 오래된 값을 최신인 척 보여주지 않는다.
    public func age(at now: Date = Date()) -> TimeInterval {
        max(0, now.timeIntervalSince(observedAt))
    }
}
