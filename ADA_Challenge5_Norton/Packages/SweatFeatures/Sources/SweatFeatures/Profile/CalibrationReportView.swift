import Charts
import DesignSystem
import SwiftData
import SwiftUI
import SweatDomain
import SweatPersistence

/// Figma `12 지수 개선` — 최근 7일 예측과 실제 기록, 보정 근거를 보여준다.
struct CalibrationReportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \SweatLog.date, order: .reverse) private var logs: [SweatLog]

    let profile: () -> UserProfile

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button { dismiss() } label: {
                    Text(ProfileCopy.backToProfile)
                        .sweatType(.body14)
                        .foregroundStyle(Accent.deep)
                        .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                        .contentShape(.rect)
                }

                Text(ProfileCopy.reportPeriod)
                    .sweatType(.overline11)
                    .foregroundStyle(Accent.deep)
                    .padding(.top, Space.x4)

                Text(ProfileCopy.reportHeading)
                    .sweatType(.title28)
                    .foregroundStyle(Ink.n900)
                    .padding(.top, Space.x2)

                Text(ProfileCopy.reportLegend)
                    .sweatType(.body15)
                    .foregroundStyle(Ink.n600)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Space.x2)

                chartSection
                    .padding(.top, Space.x6)

                Text(ProfileCopy.reportHeading(result: result, profile: profile()))
                    .sweatType(.title22Bold)
                    .foregroundStyle(Ink.n900)
                    .padding(.top, Space.x7)

                Text(ProfileCopy.reportBody(result: result, profile: profile()))
                    .sweatType(.body15)
                    .foregroundStyle(Ink.n600)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Space.x2)

                insightCard
                    .padding(.top, Space.x5)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.top, Space.x4)
            .padding(.bottom, 100)
        }
        .background(Surface.page)
        .safeAreaInset(edge: .bottom) {
            SweatButton(ProfileCopy.confirm) { dismiss() }
                .padding(.horizontal, Space.gutter)
                .padding(.vertical, Space.x3)
                .background(Surface.page)
        }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    @ViewBuilder
    private var chartSection: some View {
        if recentLogs.isEmpty {
            VStack(alignment: .leading, spacing: Space.x2) {
                Text(ProfileCopy.noRecentRecords)
                    .sweatType(.bodyStrong16)
                    .foregroundStyle(Ink.n900)
                Text(ProfileCopy.noRecentRecordsBody)
                    .sweatType(.body135)
                    .foregroundStyle(Ink.n600)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Space.x4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Surface.card, in: reportShape)
        } else {
            VStack(alignment: .leading, spacing: Space.x3) {
                HStack(spacing: Space.x4) {
                    ChartLegend(color: Ink.n300, title: ProfileCopy.predicted)
                    ChartLegend(color: Accent.base, title: ProfileCopy.actual)
                }

                Chart {
                    ForEach(recentLogs) { log in
                        BarMark(
                            x: .value(ProfileCopy.reportPeriod, ProfileCopy.chartDay(log.date)),
                            y: .value(ProfileCopy.stageUnit, log.predictedStage)
                        )
                        .foregroundStyle(Ink.n300)
                        .position(by: .value(ProfileCopy.reportLegend, ProfileCopy.predicted))

                        BarMark(
                            x: .value(ProfileCopy.reportPeriod, ProfileCopy.chartDay(log.date)),
                            y: .value(ProfileCopy.scoreUnit, log.actualScore)
                        )
                        .foregroundStyle(Accent.base)
                        .position(by: .value(ProfileCopy.reportLegend, ProfileCopy.actual))
                    }
                }
                .chartYScale(domain: 0...SweatStage.allCases.count)
                .chartLegend(.hidden)
                .frame(height: 220)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(ProfileCopy.chartSummary(recentLogs))
            }
            .padding(Space.x4)
            .background(Surface.card, in: reportShape)
        }
    }

    @ViewBuilder
    private var insightCard: some View {
        let content = Group {
            ReportInsight(
                value: ProfileCopy.eligibleCount(result.eligibleSampleCount),
                label: ProfileCopy.eligibleSamples
            )
            ReportInsight(
                value: ProfileCopy.higherCount(result.higherThanPredictionCount),
                label: ProfileCopy.higherSamples
            )
        }

        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Space.x4) { content }
                .reportInsightStyle()
        } else {
            HStack(alignment: .top, spacing: Space.x4) { content }
                .reportInsightStyle()
        }
    }

    private var recentLogs: [SweatLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        return logs
            .filter { $0.date >= start && $0.date < end }
            .sorted { $0.date < $1.date }
    }

    private var result: CalibrationResult {
        CalibrationEngine.evaluate(
            samples: logs.compactMap(\.calibrationSample),
            currentCalibration: profile().calibrationOffset
        )
    }

    private var reportShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
    }
}

private struct ChartLegend: View {
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: Space.x2) {
            RoundedRectangle(cornerRadius: Radius.sm)
                .fill(color)
                .frame(width: 14, height: 14)
                .accessibilityHidden(true)
            Text(title)
                .sweatType(.caption12)
                .foregroundStyle(Ink.n600)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ReportInsight: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: Space.x1) {
            Text(value)
                .sweatType(.stat20Bold)
                .foregroundStyle(Ink.n900)
            Text(label)
                .sweatType(.body135)
                .foregroundStyle(Ink.n600)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private extension View {
    func reportInsightStyle() -> some View {
        self
            .padding(Space.x4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Surface.accentWash,
                in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
            )
    }
}
