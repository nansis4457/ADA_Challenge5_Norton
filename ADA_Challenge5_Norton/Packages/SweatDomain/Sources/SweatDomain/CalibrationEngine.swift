import Foundation

/// 자가 기록에서 선택할 수 있는 불편 요인.
///
/// 원시값은 저장 식별자다. 사용자에게 보이는 한글은 기능 계층의 `ProfileCopy`가 담당한다.
public enum SweatLogTag: String, CaseIterable, Codable, Sendable, Hashable {
    case didNotDry
    case wetClothes
    case noShade
    case noRestArea
}

/// 개인 보정을 계산할 때 필요한 최소 기록 값.
public struct CalibrationSample: Sendable, Equatable {
    public let date: Date
    public let predictedStage: Int
    public let actualScore: Int
    public let relativeHumidity: Double

    public init?(
        date: Date,
        predictedStage: Int,
        actualScore: Int,
        relativeHumidity: Double
    ) {
        guard (1...6).contains(predictedStage),
              (1...5).contains(actualScore),
              relativeHumidity.isFinite,
              (0...100).contains(relativeHumidity)
        else { return nil }

        self.date = date
        self.predictedStage = predictedStage
        self.actualScore = actualScore
        self.relativeHumidity = relativeHumidity
    }

    /// 양수면 실제 체감이 앱 예측보다 높았다.
    public var stageDifference: Double {
        Double(actualScore - predictedStage)
    }
}

/// 보정 계산과 사용자 설명에 함께 쓰는 결과.
public struct CalibrationResult: Sendable, Equatable {
    public let eligibleSampleCount: Int
    public let higherThanPredictionCount: Int
    public let meanStageDifference: Double?
    public let previousCalibration: Double
    public let nextCalibration: Double
    public let hasEnoughSamples: Bool

    public var remainingSampleCount: Int {
        max(0, CalibrationEngine.minimumSampleCount - eligibleSampleCount)
    }

    public var didAdjust: Bool {
        hasEnoughSamples && abs(nextCalibration - previousCalibration) > 0.000_001
    }
}

/// 자가 기록을 기존 체감온도 보정값으로 학습하는 순수 계산기.
///
/// 습도는 이미 체감온도 계산에 들어간다. 여기서는 기록의 신뢰 구간을 고르는 필터로만
/// 사용하고, 현재 단계에 습도를 다시 더하지 않는다.
public enum CalibrationEngine {
    public static let minimumSampleCount = 5
    public static let humidityThreshold = 70.0
    public static let learningRate = 0.25
    public static let calibrationRange = -1.5...1.5

    public static func evaluate(
        samples: [CalibrationSample],
        currentCalibration: Double
    ) -> CalibrationResult {
        let previous = currentCalibration.isFinite
            ? min(max(currentCalibration, calibrationRange.lowerBound), calibrationRange.upperBound)
            : 0
        let eligible = samples.filter { $0.relativeHumidity >= humidityThreshold }
        let meanDifference = eligible.isEmpty
            ? nil
            : eligible.map(\.stageDifference).reduce(0, +) / Double(eligible.count)
        let hasEnoughSamples = eligible.count >= minimumSampleCount

        let next: Double
        if hasEnoughSamples, let meanDifference {
            let learned = (1 - learningRate) * previous + learningRate * meanDifference
            next = min(max(learned, calibrationRange.lowerBound), calibrationRange.upperBound)
        } else {
            next = previous
        }

        return CalibrationResult(
            eligibleSampleCount: eligible.count,
            higherThanPredictionCount: eligible.count { $0.stageDifference > 0 },
            meanStageDifference: meanDifference,
            previousCalibration: previous,
            nextCalibration: next,
            hasEnoughSamples: hasEnoughSamples
        )
    }
}
