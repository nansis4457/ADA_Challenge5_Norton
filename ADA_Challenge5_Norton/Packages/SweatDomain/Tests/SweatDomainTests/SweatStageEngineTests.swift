import Testing
@testable import SweatDomain

@Suite("SweatStageEngine — 단계 산출")
struct SweatStageEngineTests {

    /// 프로토타입의 기본 상태값.
    ///
    /// - Note: `34.2℃ → 3단계`는 **체감온도 산식이 검증되기 전까지 가정**이다.
    ///   산식 검증 결과가 다르면 이 값이 아니라 산식을 신뢰한다.
    ///   `docs/architecture.md` §5.4 참조.
    @Test("민감도가 단계를 밀어낸다", arguments: [
        (34.2, Sensitivity.normal, 3),
        (34.2, .high,   4),   // +1.2 → 35.4
        (34.2, .low,    3),   // -1.2 → 33.0 (하한 포함)
        (33.5, .low,    2),   // -1.2 → 32.3
        (27.0, .high,   2),   // +1.2 → 28.2, 28 이상이므로 2단계로 올라간다
    ])
    func sensitivityShiftsStage(temperature: Double, sensitivity: Sensitivity, expected: Int) {
        let stage = SweatStageEngine.stage(apparentTemperature: temperature, sensitivity: sensitivity)
        #expect(stage.rawValue == expected)
    }

    @Test("민감도 오프셋 값")
    func offsets() {
        #expect(Sensitivity.low.offset == -1.2)
        #expect(Sensitivity.normal.offset == 0)
        #expect(Sensitivity.high.offset == 1.2)
        #expect(Sensitivity.allCases.count == 3)
    }

    @Test("rawValue는 영속화용으로 안정적이어야 한다")
    func rawValuesAreStable() {
        #expect(Sensitivity.low.rawValue == "low")
        #expect(Sensitivity.normal.rawValue == "normal")
        #expect(Sensitivity.high.rawValue == "high")
    }

    // MARK: - 보정값

    @Test("보정값은 ±calibrationLimit 로 잘린다 (규칙 「기록이 예측을 고친다」)")
    func calibrationIsClamped() {
        let limit = SweatStageEngine.calibrationLimit

        #expect(
            SweatStageEngine.stage(apparentTemperature: 30, sensitivity: .normal, calibration: 999)
            == SweatStageEngine.stage(apparentTemperature: 30, sensitivity: .normal, calibration: limit)
        )
        #expect(
            SweatStageEngine.stage(apparentTemperature: 40, sensitivity: .normal, calibration: -999)
            == SweatStageEngine.stage(apparentTemperature: 40, sensitivity: .normal, calibration: -limit)
        )
    }

    @Test("보정값 기본값은 0 — 아무것도 바꾸지 않는다")
    func calibrationDefaultsToZero() {
        for stage in SweatStage.allCases {
            let t = stage.range.lowerBound.isFinite ? stage.range.lowerBound : 0
            #expect(
                SweatStageEngine.stage(apparentTemperature: t, sensitivity: .normal)
                == SweatStageEngine.stage(apparentTemperature: t, sensitivity: .normal, calibration: 0)
            )
        }
    }

    @Test("민감도와 보정은 더해진다")
    func sensitivityAndCalibrationCompose() {
        let withBoth = SweatStageEngine.stage(
            apparentTemperature: 32.0, sensitivity: .high, calibration: 1.0)   // 32 + 1.2 + 1.0 = 34.2
        #expect(withBoth == .three)
    }

    // MARK: - T033 극단 입력

    @Test("극단 입력에도 크래시하지 않는다", arguments: [
        Double.nan, .infinity, -.infinity, -273.15, 1_000, -1_000,
        .greatestFiniteMagnitude, -.greatestFiniteMagnitude,
    ])
    func extremeTemperatures(temperature: Double) {
        for sensitivity in Sensitivity.allCases {
            let stage = SweatStageEngine.stage(apparentTemperature: temperature, sensitivity: sensitivity)
            #expect(SweatStage.allCases.contains(stage))
        }
    }

    @Test("NaN은 가장 낮은 단계로 떨어진다")
    func nanFallsToLowest() {
        #expect(SweatStageEngine.stage(apparentTemperature: .nan, sensitivity: .high) == .one)
    }

    @Test("무한대는 양 끝 단계")
    func infinities() {
        #expect(SweatStageEngine.stage(apparentTemperature: .infinity, sensitivity: .low) == .six)
        #expect(SweatStageEngine.stage(apparentTemperature: -.infinity, sensitivity: .high) == .one)
    }

    @Test("극단 보정값에도 결과는 유효한 단계")
    func extremeCalibration() {
        for calibration in [Double.nan, .infinity, -.infinity, 1e9, -1e9] {
            let stage = SweatStageEngine.stage(
                apparentTemperature: 34.2, sensitivity: .normal, calibration: calibration)
            #expect(SweatStage.allCases.contains(stage))
        }
    }
}
