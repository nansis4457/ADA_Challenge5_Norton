import Foundation
import SwiftData
import SweatDomain

/// `SweatLog`의 날짜별 저장과 조회를 한 곳에서 담당한다.
@MainActor
public struct SweatLogRepository {
    private let context: ModelContext
    private let calendar: Calendar

    public init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    /// 같은 날짜 기록이 있으면 수정하고, 없으면 새로 만든다.
    @discardableResult
    public func upsert(_ draft: SweatLogDraft) throws -> SweatLog {
        let key = Self.dayKey(for: draft.date, calendar: calendar)
        let descriptor = FetchDescriptor<SweatLog>(
            predicate: #Predicate { $0.dayKey == key }
        )

        let log: SweatLog
        if let existing = try context.fetch(descriptor).first {
            log = existing
            apply(draft, to: log)
        } else {
            log = SweatLog(
                dayKey: key,
                date: draft.date,
                predictedStage: draft.predictedStage,
                actualScore: draft.actualScore,
                tags: draft.tags.map(\.rawValue).sorted(),
                apparentTemperature: draft.apparentTemperature,
                relativeHumidity: draft.relativeHumidity,
                windSpeed: draft.windSpeed,
                routeOutdoorMinutes: draft.routeOutdoorMinutes
            )
            context.insert(log)
        }

        try context.save()
        return log
    }

    public func log(on date: Date) throws -> SweatLog? {
        let key = Self.dayKey(for: date, calendar: calendar)
        let descriptor = FetchDescriptor<SweatLog>(
            predicate: #Predicate { $0.dayKey == key }
        )
        return try context.fetch(descriptor).first
    }

    public func all() throws -> [SweatLog] {
        let descriptor = FetchDescriptor<SweatLog>(
            sortBy: [SortDescriptor(\SweatLog.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public func recent(days: Int, through date: Date = Date()) throws -> [SweatLog] {
        guard days > 0 else { return [] }
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: date)) ?? date
        let descriptor = FetchDescriptor<SweatLog>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\SweatLog.date)]
        )
        return try context.fetch(descriptor)
    }

    public static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.era, .year, .month, .day], from: date)
        return [parts.era, parts.year, parts.month, parts.day]
            .map { String($0 ?? 0) }
            .joined(separator: "-")
    }

    private func apply(_ draft: SweatLogDraft, to log: SweatLog) {
        log.date = draft.date
        log.predictedStage = draft.predictedStage
        log.actualScore = draft.actualScore
        log.tags = draft.tags.map(\.rawValue).sorted()
        log.apparentTemperature = draft.apparentTemperature
        log.relativeHumidity = draft.relativeHumidity
        log.windSpeed = draft.windSpeed
        log.routeOutdoorMinutes = draft.routeOutdoorMinutes
    }
}
