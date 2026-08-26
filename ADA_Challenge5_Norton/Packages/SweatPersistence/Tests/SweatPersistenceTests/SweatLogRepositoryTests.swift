import Foundation
import SwiftData
import SweatDomain
import Testing
@testable import SweatPersistence

@MainActor
@Suite("SweatLogRepository")
struct SweatLogRepositoryTests {
    @Test("같은 날짜를 다시 저장하면 한 기록을 수정한다")
    func sameDayUpserts() throws {
        let (repository, container) = try makeRepository()
        let morning = Date(timeIntervalSinceReferenceDate: 720_000_000)
        let evening = morning.addingTimeInterval(60 * 60)

        try repository.upsert(try #require(draft(date: morning, score: 2)))
        try repository.upsert(try #require(draft(date: evening, score: 5)))

        let all = try repository.all()
        #expect(all.count == 1)
        #expect(all.first?.actualScore == 5)
        #expect(all.first?.selectedTags == [.wetClothes])
        _ = container
    }

    @Test("최근 N일 조회는 오래된 기록을 제외하고 날짜순으로 반환한다")
    func recentLogs() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let (repository, container) = try makeRepository(calendar: calendar)
        let today = Date(timeIntervalSince1970: 1_800_000_000)

        for offset in [-8, -6, -1, 0] {
            let date = try #require(calendar.date(byAdding: .day, value: offset, to: today))
            try repository.upsert(try #require(draft(date: date, score: 3)))
        }

        let recent = try repository.recent(days: 7, through: today)
        #expect(recent.count == 3)
        #expect(recent.map(\.date) == recent.map(\.date).sorted())
        _ = container
    }

    @Test("저장 모델을 보정 표본으로 변환한다")
    func convertsToCalibrationSample() throws {
        let (repository, container) = try makeRepository()
        let log = try repository.upsert(try #require(draft(date: Date(), score: 4, outdoorMinutes: 2)))

        let sample = try #require(log.calibrationSample)
        #expect(sample.predictedStage == 3)
        #expect(sample.actualScore == 4)
        #expect(sample.relativeHumidity == 80)
        #expect(log.routeOutdoorMinutes == 2)
        _ = container
    }

    private func makeRepository(
        calendar: Calendar = .current
    ) throws -> (SweatLogRepository, ModelContainer) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SweatLog.self, configurations: configuration)
        return (SweatLogRepository(context: container.mainContext, calendar: calendar), container)
    }

    private func draft(
        date: Date,
        score: Int,
        outdoorMinutes: Int? = nil
    ) -> SweatLogDraft? {
        SweatLogDraft(
            date: date,
            predictedStage: 3,
            actualScore: score,
            tags: [.wetClothes],
            apparentTemperature: 34,
            relativeHumidity: 80,
            windSpeed: 1.2,
            routeOutdoorMinutes: outdoorMinutes
        )
    }
}
