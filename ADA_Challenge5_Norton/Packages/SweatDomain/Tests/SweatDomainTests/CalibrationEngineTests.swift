import Foundation
import Testing
@testable import SweatDomain

@Suite("CalibrationEngine")
struct CalibrationEngineTests {
    @Test("고습도 기록이 4건이면 보정하지 않는다")
    func fourSamplesDoNotAdjust() throws {
        let samples = try (0..<4).map { try #require(sample(day: $0, predicted: 3, actual: 4)) }

        let result = CalibrationEngine.evaluate(samples: samples, currentCalibration: 0.4)

        #expect(result.eligibleSampleCount == 4)
        #expect(result.remainingSampleCount == 1)
        #expect(result.nextCalibration == 0.4)
        #expect(!result.hasEnoughSamples)
    }

    @Test("고습도 기록이 5건이면 평균 오차를 EMA로 반영한다")
    func fiveSamplesAdjust() throws {
        let samples = try (0..<5).map { try #require(sample(day: $0, predicted: 3, actual: 4)) }

        let result = CalibrationEngine.evaluate(samples: samples, currentCalibration: 0)

        #expect(result.eligibleSampleCount == 5)
        #expect(result.higherThanPredictionCount == 5)
        #expect(result.meanStageDifference == 1)
        #expect(result.nextCalibration == 0.25)
        #expect(result.didAdjust)
    }

    @Test("보정값은 위아래 1.5도 안에 머문다", arguments: [
        (predicted: 1, actual: 5, current: 1.4, expected: 1.5),
        (predicted: 5, actual: 1, current: -1.4, expected: -1.5),
    ])
    func calibrationIsClamped(
        predicted: Int,
        actual: Int,
        current: Double,
        expected: Double
    ) throws {
        let samples = try (0..<5).map {
            try #require(sample(day: $0, predicted: predicted, actual: actual))
        }

        let result = CalibrationEngine.evaluate(samples: samples, currentCalibration: current)

        #expect(result.nextCalibration == expected)
    }

    @Test("습도 70퍼센트 미만 기록은 학습 표본에서 제외한다")
    func lowHumidityIsExcluded() throws {
        let lowHumidity = try (0..<5).map {
            try #require(sample(day: $0, predicted: 2, actual: 5, humidity: 69.9))
        }
        let highHumidity = try #require(sample(day: 5, predicted: 3, actual: 4, humidity: 70))

        let result = CalibrationEngine.evaluate(
            samples: lowHumidity + [highHumidity],
            currentCalibration: 0
        )

        #expect(result.eligibleSampleCount == 1)
        #expect(result.meanStageDifference == 1)
        #expect(result.nextCalibration == 0)
    }

    private func sample(
        day: Int,
        predicted: Int,
        actual: Int,
        humidity: Double = 80
    ) -> CalibrationSample? {
        CalibrationSample(
            date: Date(timeIntervalSinceReferenceDate: Double(day * 86_400)),
            predictedStage: predicted,
            actualScore: actual,
            relativeHumidity: humidity
        )
    }
}
