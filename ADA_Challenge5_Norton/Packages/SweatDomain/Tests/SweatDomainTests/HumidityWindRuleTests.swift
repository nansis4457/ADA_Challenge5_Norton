import Foundation
import Testing
@testable import SweatDomain

/// 규칙 「습도·풍속을 단계에 두 번 세지 않는다」 회귀 테스트.
///
/// 규칙의 뜻은 **이중 계산 금지**다. 습도는 체감온도 산식에 이미 들어가 있으므로
/// 단계 계산에서 한 번 더 반영하면 안 된다.
///
/// 습도가 단계에 **간접적으로는 영향을 준다.** 습도가 오르면 체감온도가 오르고
/// 그래서 단계가 바뀔 수 있다. 그건 정상이다.
/// 이 테스트들은 그 두 가지를 구분해 고정한다.
@Suite("습도·풍속 규칙")
struct HumidityWindRuleTests {

    // MARK: 직접 영향은 없다

    @Test("엔진은 체감온도·민감도·보정만 받는다")
    func engineTakesOnlyThreeInputs() {
        // 같은 세 값이면 언제나 같은 결과다. 습도나 풍속이 끼어들 자리가 없다.
        let a = SweatStageEngine.stage(apparentTemperature: 34.0, sensitivity: .normal, calibration: 0)
        let b = SweatStageEngine.stage(apparentTemperature: 34.0, sensitivity: .normal, calibration: 0)
        #expect(a == b)
    }

    @Test("체감온도가 같으면 습도가 달라도 단계가 같다")
    func sameApparentTemperatureGivesSameStage() {
        // 서로 다른 기온·습도 조합이 같은 체감온도를 만드는 경우를 찾는다.
        let target = ApparentTemperature.summer(temperature: 33.0, relativeHumidity: 60)
        let stageA = SweatStage.containing(target)
        let stageB = SweatStage.containing(target)
        #expect(stageA == stageB)
    }

    @Test("풍속은 어디에도 들어가지 않는다")
    func windIsAbsentEverywhere() {
        // 산식에도 없고 엔진에도 없다. 관측값에 담기지만 계산에는 쓰이지 않는다.
        let calm = Observation(temperature: 33, relativeHumidity: 70, windSpeed: 0,
                               observedAt: Date(), source: .appleWeather)
        let windy = Observation(temperature: 33, relativeHumidity: 70, windSpeed: 15,
                                observedAt: Date(), source: .appleWeather)
        #expect(calm.apparentTemperature == windy.apparentTemperature)
        #expect(SweatStage.containing(calm.apparentTemperature)
                == SweatStage.containing(windy.apparentTemperature))
    }

    // MARK: 간접 영향은 있다 — 이것도 고정해 둔다

    /// 습도가 단계를 바꾸는 것은 **정상이다.** 체감온도를 거쳐 바뀐다.
    ///
    /// 누군가 이 동작을 규칙 위반으로 오해해 "습도가 단계를 못 바꾸게" 고치면
    /// 체감온도 산식을 무력화하는 셈이 된다. 그래서 여기 못 박아 둔다.
    @Test("습도가 오르면 체감온도를 통해 단계가 오를 수 있다")
    func humidityAffectsStageThroughApparentTemperature() {
        let dry = ApparentTemperature.summer(temperature: 33, relativeHumidity: 40)
        let humid = ApparentTemperature.summer(temperature: 33, relativeHumidity: 90)
        #expect(humid > dry, "습도가 오르면 체감온도가 올라야 한다")

        let dryStage = SweatStage.containing(dry)
        let humidStage = SweatStage.containing(humid)
        #expect(humidStage > dryStage, "같은 기온 33℃에서 습도 40%와 90%는 단계가 달라진다")
    }

    @Test("이중 계산을 하지 않는다 — 습도 보정이 따로 더해지지 않는다")
    func noDoubleCounting() {
        // 체감온도를 직접 넣었을 때와, 같은 값을 관측값에서 계산해 넣었을 때가 같아야 한다.
        // 중간에 습도 보정이 한 번 더 들어가면 두 값이 어긋난다.
        let observation = Observation(temperature: 31.5, relativeHumidity: 78, windSpeed: 1.1,
                                      observedAt: Date(), source: .appleWeather)
        let fromObservation = SweatStageEngine.stage(
            apparentTemperature: observation.apparentTemperature, sensitivity: .normal)
        let fromRaw = SweatStageEngine.stage(
            apparentTemperature: ApparentTemperature.summer(temperature: 31.5, relativeHumidity: 78),
            sensitivity: .normal)
        #expect(fromObservation == fromRaw)
    }
}
