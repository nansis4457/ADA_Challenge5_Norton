import Foundation
import Testing
@testable import SweatDomain

@Suite("체감온도 산식")
struct ApparentTemperatureTests {

    /// 검증 시점(2026-08-20)에 계산한 값을 고정한다.
    ///
    /// 산식이 바뀌면 이 테스트가 먼저 깨진다. 그때 값을 고치기 전에
    /// **왜 바뀌었는지**부터 확인해야 한다. 화면의 모든 숫자가 여기서 나온다.
    @Test("기준 케이스 — 디자인 화면의 기온·습도", arguments: [
        // 기온, 습도, 기대 체감온도(소수 둘째 자리)
        (31.5, 78.0, 33.472),
        (28.0, 60.0, 28.447),
        (35.0, 50.0, 34.458),
        (25.0, 40.0, 23.764),
        (38.0, 70.0, 39.456),
        (20.0, 30.0, 18.199),
    ])
    func referenceCases(temperature: Double, humidity: Double, expected: Double) {
        let value = ApparentTemperature.summer(temperature: temperature, relativeHumidity: humidity)
        #expect(abs(value - expected) < 0.005, "\(temperature)℃/\(humidity)% → \(value)")
    }

    /// 디자인이 34.2℃로 적고 있었으나 실제 계산은 33.5℃다.
    /// 프로토타입이 기온·습도·체감을 각각 따로 하드코딩한 결과였다.
    /// **단계는 3단계로 같아** 지금까지의 전제는 유지된다.
    @Test("디자인 수치와의 차이는 단계를 바꾸지 않는다")
    func designMismatchDoesNotChangeStage() {
        let computed = ApparentTemperature.summer(temperature: 31.5, relativeHumidity: 78)
        #expect(abs(computed - 34.2) > 0.5, "디자인의 34.2℃와는 실제로 다르다")
        #expect(SweatStage.containing(computed) == .three)
        #expect(SweatStage.containing(34.2) == .three, "그래도 단계는 같다")
    }

    // MARK: 습구온도

    @Test("습구온도는 기온보다 높지 않다", arguments: [
        (20.0, 30.0), (25.0, 50.0), (31.5, 78.0), (35.0, 90.0), (40.0, 20.0),
    ])
    func wetBulbNeverExceedsAir(temperature: Double, humidity: Double) {
        let tw = ApparentTemperature.wetBulb(temperature: temperature, relativeHumidity: humidity)
        #expect(tw <= temperature + 0.01, "습구온도 \(tw) > 기온 \(temperature)")
    }

    @Test("습도 100%에서 습구온도는 기온에 근접한다")
    func saturatedAirWetBulbApproachesAir() {
        let tw = ApparentTemperature.wetBulb(temperature: 30, relativeHumidity: 100)
        #expect(abs(tw - 30) < 1.0, "포화 상태에서는 습구온도가 기온에 가까워야 한다: \(tw)")
    }

    // MARK: 단조성

    @Test("같은 기온에서 습도가 높을수록 체감온도가 높다")
    func humidityIncreasesApparentTemperature() {
        let values = [30.0, 50.0, 70.0, 90.0].map {
            ApparentTemperature.summer(temperature: 32, relativeHumidity: $0)
        }
        #expect(values == values.sorted(), "습도가 오르면 체감온도도 올라야 한다: \(values)")
    }

    @Test("같은 습도에서 기온이 높을수록 체감온도가 높다")
    func temperatureIncreasesApparentTemperature() {
        let values = [26.0, 30.0, 34.0, 38.0].map {
            ApparentTemperature.summer(temperature: $0, relativeHumidity: 70)
        }
        #expect(values == values.sorted())
    }

    // MARK: 극단 입력

    @Test("NaN 입력은 NaN을 돌려주고 크래시하지 않는다")
    func nanInput() {
        #expect(ApparentTemperature.summer(temperature: .nan, relativeHumidity: 50).isNaN)
        #expect(ApparentTemperature.summer(temperature: 30, relativeHumidity: .nan).isNaN)
        #expect(ApparentTemperature.wetBulb(temperature: .infinity, relativeHumidity: 50).isNaN)
    }

    @Test("범위 밖 습도는 0~100으로 잘린다")
    func humidityIsClamped() {
        let over = ApparentTemperature.summer(temperature: 30, relativeHumidity: 150)
        let at100 = ApparentTemperature.summer(temperature: 30, relativeHumidity: 100)
        #expect(abs(over - at100) < 0.001)

        let under = ApparentTemperature.summer(temperature: 30, relativeHumidity: -20)
        let at0 = ApparentTemperature.summer(temperature: 30, relativeHumidity: 0)
        #expect(abs(under - at0) < 0.001)
    }

    @Test("극단 기온에서도 유한한 값을 돌려준다", arguments: [-50.0, 0.0, 60.0, 100.0])
    func extremeTemperatures(temperature: Double) {
        let value = ApparentTemperature.summer(temperature: temperature, relativeHumidity: 50)
        #expect(value.isFinite)
    }

    // MARK: 규칙 「습도·풍속은 등급을 바꾸지 않는다」

    /// 풍속은 여름철 산식에 **들어가지 않는다.** 시그니처에 자리조차 없다.
    /// 등급 상세가 풍속을 기여 요인으로 보여주더라도 그것은 설명이지 계산이 아니다.
    @Test("산식은 기온과 습도만 받는다")
    func formulaTakesOnlyTemperatureAndHumidity() {
        let a = ApparentTemperature.summer(temperature: 31.5, relativeHumidity: 78)
        let b = ApparentTemperature.summer(temperature: 31.5, relativeHumidity: 78)
        #expect(a == b, "같은 입력이면 항상 같은 값 — 다른 변수가 끼어들 여지가 없다")
    }
}
