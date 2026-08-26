import Foundation
import SwiftData
import SweatDomain

/// 하루의 예측과 실제 체감을 함께 저장하는 기록.
///
/// `dayKey`가 날짜별 유일성을 보장한다. 같은 날 다시 저장하면 저장소가 이 모델을 갱신한다.
@Model
public final class SweatLog {
    @Attribute(.unique) public var dayKey: String
    public var date: Date
    public var predictedStage: Int
    public var actualScore: Int
    public var tags: [String]
    public var apparentTemperature: Double
    public var relativeHumidity: Double
    public var windSpeed: Double
    public var routeOutdoorMinutes: Int?

    public init(
        dayKey: String,
        date: Date,
        predictedStage: Int,
        actualScore: Int,
        tags: [String],
        apparentTemperature: Double,
        relativeHumidity: Double,
        windSpeed: Double,
        routeOutdoorMinutes: Int?
    ) {
        self.dayKey = dayKey
        self.date = date
        self.predictedStage = predictedStage
        self.actualScore = actualScore
        self.tags = tags
        self.apparentTemperature = apparentTemperature
        self.relativeHumidity = relativeHumidity
        self.windSpeed = windSpeed
        self.routeOutdoorMinutes = routeOutdoorMinutes
    }

    public var selectedTags: Set<SweatLogTag> {
        Set(tags.compactMap(SweatLogTag.init(rawValue:)))
    }

    public var calibrationSample: CalibrationSample? {
        CalibrationSample(
            date: date,
            predictedStage: predictedStage,
            actualScore: actualScore,
            relativeHumidity: relativeHumidity
        )
    }
}

/// 화면이 저장소로 넘기는 검증된 기록 값.
public struct SweatLogDraft: Sendable, Equatable {
    public let date: Date
    public let predictedStage: Int
    public let actualScore: Int
    public let tags: Set<SweatLogTag>
    public let apparentTemperature: Double
    public let relativeHumidity: Double
    public let windSpeed: Double
    public let routeOutdoorMinutes: Int?

    public init?(
        date: Date,
        predictedStage: Int,
        actualScore: Int,
        tags: Set<SweatLogTag>,
        apparentTemperature: Double,
        relativeHumidity: Double,
        windSpeed: Double,
        routeOutdoorMinutes: Int? = nil
    ) {
        guard (1...6).contains(predictedStage),
              (1...5).contains(actualScore),
              apparentTemperature.isFinite,
              relativeHumidity.isFinite,
              (0...100).contains(relativeHumidity),
              windSpeed.isFinite,
              windSpeed >= 0,
              routeOutdoorMinutes.map({ $0 >= 0 }) ?? true
        else { return nil }

        self.date = date
        self.predictedStage = predictedStage
        self.actualScore = actualScore
        self.tags = tags
        self.apparentTemperature = apparentTemperature
        self.relativeHumidity = relativeHumidity
        self.windSpeed = windSpeed
        self.routeOutdoorMinutes = routeOutdoorMinutes
    }
}
