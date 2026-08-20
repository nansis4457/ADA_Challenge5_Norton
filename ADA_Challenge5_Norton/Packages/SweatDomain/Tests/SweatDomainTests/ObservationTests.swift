import Foundation
import Testing
@testable import SweatDomain

@Suite("Observation · ForecastLevel")
struct ObservationTests {

    private func make(temp: Double, humidity: Double, wind: Double = 1.1,
                      minutesAgo: Double = 0) -> Observation {
        Observation(
            temperature: temp,
            relativeHumidity: humidity,
            windSpeed: wind,
            observedAt: Date().addingTimeInterval(-minutesAgo * 60),
            source: .appleWeather
        )
    }

    @Test("체감온도는 저장하지 않고 계산한다")
    func apparentTemperatureIsComputed() {
        let observation = make(temp: 31.5, humidity: 78)
        let direct = ApparentTemperature.summer(temperature: 31.5, relativeHumidity: 78)
        #expect(observation.apparentTemperature == direct)
    }

    @Test("풍속은 체감온도에 영향을 주지 않는다")
    func windDoesNotAffectApparentTemperature() {
        let calm = make(temp: 31.5, humidity: 78, wind: 0)
        let windy = make(temp: 31.5, humidity: 78, wind: 12)
        #expect(calm.apparentTemperature == windy.apparentTemperature)
    }

    @Test("경과 시간은 음수가 되지 않는다")
    func ageIsNeverNegative() {
        let future = make(temp: 30, humidity: 60, minutesAgo: -10)
        #expect(future.age() == 0, "미래 시각이 들어와도 음수를 돌려주지 않는다")
    }

    @Test("경과 시간이 분 단위로 맞는다")
    func ageInMinutes() {
        let observation = make(temp: 30, humidity: 60, minutesAgo: 45)
        #expect(abs(observation.age() - 2700) < 2)
    }

    @Test("저장 후 다시 읽어도 값이 같다")
    func codableRoundTrip() throws {
        let original = make(temp: 31.5, humidity: 78)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Observation.self, from: data)
        #expect(decoded == original)
    }

    // MARK: 예보 구간

    @Test("단계가 표시용 4구간으로 묶인다", arguments: [
        (SweatStage.one, ForecastLevel.comfortable),
        (.two, .moderate),
        (.three, .sweaty),
        (.four, .hot),
        (.five, .hot),
        (.six, .hot),
    ])
    func stageMapsToLevel(stage: SweatStage, expected: ForecastLevel) {
        #expect(ForecastLevel(stage) == expected)
    }

    @Test("네 구간 모두 실제로 쓰인다")
    func allLevelsReachable() {
        let mapped = Set(SweatStage.allCases.map(ForecastLevel.init))
        #expect(mapped.count == ForecastLevel.allCases.count, "쓰이지 않는 구간이 있습니다")
    }

    @Test("구간 순서가 단계 순서를 뒤집지 않는다")
    func levelOrderFollowsStageOrder() {
        let levels = SweatStage.allCases.map(ForecastLevel.init)
        #expect(levels == levels.sorted(), "단계가 오를 때 구간이 내려가면 안 된다")
    }
}
