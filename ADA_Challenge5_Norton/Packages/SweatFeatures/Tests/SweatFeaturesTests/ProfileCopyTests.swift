import Foundation
import SweatDomain
import SweatPersistence
import Testing
@testable import SweatFeatures

@MainActor
@Suite("ProfileCopy")
struct ProfileCopyTests {
    @Test("기록이 없으면 평균과 차이를 꾸며내지 않는다")
    func emptyStatistics() {
        #expect(ProfileCopy.averageScoreValue([]) == "—")
        #expect(ProfileCopy.differenceValue([]) == "—")
    }

    @Test("실제 기록의 평균과 예측 차이를 소수 한 자리로 표시한다")
    func formatsStatistics() {
        let logs = [
            log(day: 0, predicted: 3, actual: 4),
            log(day: 1, predicted: 2, actual: 3),
        ]

        #expect(ProfileCopy.averageScoreValue(logs) == "3.5")
        #expect(ProfileCopy.differenceValue(logs) == "+1.0")
    }

    @Test("표본이 부족하면 남은 기록 수를 설명한다")
    func explainsRemainingSamples() throws {
        let samples = try (0..<3).map { index in
            try #require(CalibrationSample(
                date: Date(timeIntervalSinceReferenceDate: Double(index)),
                predictedStage: 3,
                actualScore: 4,
                relativeHumidity: 80
            ))
        }
        let result = CalibrationEngine.evaluate(samples: samples, currentCalibration: 0)

        #expect(ProfileCopy.reportBody(result: result, profile: .default).contains("2건 더 필요"))
    }

    @Test("이동 완료는 관측된 실외 시간만 분으로 전달한다")
    func moveCompletionHandoff() throws {
        let startedAt = Date(timeIntervalSinceReferenceDate: 1_000)
        let completion = try #require(MoveCompletion(
            sessionID: UUID(),
            routeID: UUID(),
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(300),
            traveledDistanceMeters: 500,
            fractionCompleted: 1,
            observedOutdoorTime: 125
        ))
        let unavailable = try #require(MoveCompletion(
            sessionID: UUID(),
            routeID: UUID(),
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(300),
            traveledDistanceMeters: 500,
            fractionCompleted: 1
        ))

        #expect(MoveLogHandoff.outdoorMinutes(from: completion) == 2)
        #expect(MoveLogHandoff.outdoorMinutes(from: unavailable) == nil)
    }

    private func log(day: Int, predicted: Int, actual: Int) -> SweatLog {
        SweatLog(
            dayKey: String(day),
            date: Date(timeIntervalSinceReferenceDate: Double(day * 86_400)),
            predictedStage: predicted,
            actualScore: actual,
            tags: [],
            apparentTemperature: 34,
            relativeHumidity: 80,
            windSpeed: 1,
            routeOutdoorMinutes: nil
        )
    }
}
