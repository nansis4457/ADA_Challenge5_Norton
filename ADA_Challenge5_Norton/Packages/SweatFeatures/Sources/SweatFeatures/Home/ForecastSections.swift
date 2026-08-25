import SwiftUI
import DesignSystem
import SweatDomain

/// 시간별 예보 (R5).
///
/// 접근성 글자 크기에서는 가로 그리드가 무너진다. 세로 목록으로 바꾼다 (R13).
struct HourlyForecastSection: View {
    let hourly: [HourlyForecast]
    let profile: HomeStore
    @Environment(\.dynamicTypeSize) private var typeSize

    private var visible: [HourlyForecast] { Array(hourly.prefix(10)) }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.x3) {
            Text(HomeCopy.Forecast.hourly)
                .sweatType(.section15)
                .foregroundStyle(Ink.n900)
                .padding(.horizontal, Space.gutter)

            if typeSize.isAccessibilitySize {
                verticalList
            } else {
                horizontalGrid
            }
        }
        .padding(.top, Space.x4)
        .overlay(alignment: .top) {
            Rectangle().fill(Ink.n900.opacity(0.14)).frame(height: 0.5)
        }
    }

    private var horizontalGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(visible, id: \.date) { hour in
                    cell(hour)
                }
            }
            .padding(.horizontal, Space.gutter)
        }
    }

    /// 접근성 크기에서는 한 줄에 하나씩.
    private var verticalList: some View {
        VStack(spacing: Space.x2) {
            ForEach(visible, id: \.date) { hour in
                HStack(spacing: Space.x3) {
                    Text(time(hour.date)).sweatType(.list125).foregroundStyle(Ink.n600)
                    WeatherFace(level: level(hour).rawValue, size: 28)
                    Text(temperature(hour)).sweatType(.forecast16).foregroundStyle(Ink.n900)
                    Spacer()
                    Text("\(Int(hour.relativeHumidity))%")
                        .sweatType(.caption13).foregroundStyle(Ink.n600)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.horizontal, Space.gutter)
    }

    private func cell(_ hour: HourlyForecast) -> some View {
        VStack(spacing: Space.x1) {
            Text(time(hour.date)).sweatType(.list125).foregroundStyle(Ink.n600)
            WeatherFace(level: level(hour).rawValue)
            Text(temperature(hour)).sweatType(.forecast16).foregroundStyle(Ink.n900)
            Text("\(Int(hour.relativeHumidity))%").sweatType(.caption13).foregroundStyle(Ink.n600)
        }
        .frame(width: 62)
        .padding(.vertical, Space.x1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(time(hour.date)), \(HomeCopy.Forecast.levelName(level(hour))), \(temperature(hour))")
    }

    private func level(_ hour: HourlyForecast) -> ForecastLevel {
        ForecastLevel(profile.stage(forApparent: hour.apparentTemperature))
    }
    private func time(_ date: Date) -> String {
        HomeCopy.Format.hour(date)
    }
    private func temperature(_ hour: HourlyForecast) -> String {
        "\(hour.temperature.formatted(.number.precision(.fractionLength(1))))°"
    }
}

/// 주간 예보 (R6).
struct WeeklyForecastSection: View {
    let daily: [DailyForecast]
    let profile: HomeStore

    private var visible: [DailyForecast] { Array(daily.prefix(7)) }

    /// 막대의 좌우 끝을 정하는 전체 범위.
    private var bounds: ClosedRange<Double> {
        let lows = visible.map(\.lowTemperature)
        let highs = visible.map(\.highTemperature)
        guard let low = lows.min(), let high = highs.max(), high > low else { return 0...1 }
        return low...high
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.x3) {
            Text(HomeCopy.Forecast.weekly)
                .sweatType(.section15)
                .foregroundStyle(Ink.n900)

            VStack(spacing: 2) {
                ForEach(visible, id: \.date) { day in row(day) }
            }

            // 시간별 예보가 닿지 않는 날이 섞여 있으면 밝힌다 (「추정치는 추정치로」).
            if visible.contains(where: \.isApparentHighEstimated) {
                Text(HomeCopy.Forecast.estimatedNote)
                    .sweatType(.caption12)
                    .foregroundStyle(Ink.n400)
            }
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.x4)
        .overlay(alignment: .top) {
            Rectangle().fill(Ink.n900.opacity(0.14)).frame(height: 0.5)
                .padding(.horizontal, -Space.gutter)
        }
    }

    private func row(_ day: DailyForecast) -> some View {
        let stage = profile.stage(forApparent: day.apparentHigh)
        let level = ForecastLevel(stage)
        return HStack(spacing: Space.x2 + 2) {
            Text(weekday(day.date)).sweatType(.label14Medium)
                .foregroundStyle(Ink.n600).frame(width: 34, alignment: .leading)
            WeatherFace(level: level.rawValue, size: 22)
            Text(HomeCopy.Forecast.levelName(level))
                .sweatType(.list125)
                .foregroundStyle(StageRole.ink(stage.rawValue))
                .frame(width: 56, alignment: .leading)
            RangeBar(range: day.lowTemperature...day.highTemperature, bounds: bounds,
                     color: StageRole.outline(stage.rawValue))
            Text("\(Int(day.lowTemperature))° \(Int(day.highTemperature))°")
                .sweatType(.caption13).foregroundStyle(Ink.n600)
                .frame(width: 64, alignment: .trailing)
        }
        .padding(.vertical, 7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(HomeCopy.Forecast.dayLabel(weekday(day.date), level,
                                                       low: Int(day.lowTemperature),
                                                       high: Int(day.highTemperature)))
    }

    private func weekday(_ date: Date) -> String {
        Calendar.current.isDateInToday(date)
            ? HomeCopy.Forecast.today
            : HomeCopy.Format.weekday(date)
    }
}

/// 최저~최고 온도를 전체 범위 안에 놓는 막대.
struct RangeBar: View {
    let range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let span = bounds.upperBound - bounds.lowerBound
            let start = (range.lowerBound - bounds.lowerBound) / span
            let width = (range.upperBound - range.lowerBound) / span
            Capsule().fill(Ink.n200)
                .overlay(alignment: .leading) {
                    Capsule().fill(color)
                        .frame(width: max(4, geometry.size.width * width))
                        .offset(x: geometry.size.width * start)
                }
        }
        .frame(height: 5)
    }
}
