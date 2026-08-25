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
                hourlyRowLabels
                ForEach(Array(visible.enumerated()), id: \.element.date) { index, hour in
                    cell(hour, isCurrent: index == 0)
                }
            }
            .padding(.leading, Space.gutter)
            .padding(.trailing, Space.gutter)
        }
    }

    /// 각 값의 의미를 스크롤하기 전에 읽을 수 있는 고정 폭 행 제목.
    ///
    /// 높이는 시간 칸의 네 행과 맞춰 `땀 단계`·`기온`·`습도`가 같은 기준선에 놓인다.
    private var hourlyRowLabels: some View {
        VStack(spacing: 6) {
            Color.clear.frame(height: 20)
            hourlyRowLabel(HomeCopy.Forecast.stageColumn, height: 34)
            hourlyRowLabel(HomeCopy.Forecast.temperatureColumn, height: 20)
            hourlyRowLabel(HomeCopy.Forecast.humidityColumn, height: 18)
        }
        .frame(width: 52)
        .padding(.vertical, 6)
        .accessibilityHidden(true)
    }

    private func hourlyRowLabel(_ value: String, height: CGFloat) -> some View {
        Text(value)
            .sweatType(.overline11)
            .foregroundStyle(Ink.n600)
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height,
                   alignment: .leading)
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

    private func cell(_ hour: HourlyForecast, isCurrent: Bool) -> some View {
        VStack(spacing: 6) {
            Text(time(hour.date))
                .sweatType(.list125)
                .foregroundStyle(Ink.n600)
                .frame(height: 20)
            WeatherFace(level: level(hour).rawValue)
            Text(temperature(hour))
                .sweatType(.forecast16)
                .foregroundStyle(Ink.n900)
                .frame(height: 20)
            Text("\(Int(hour.relativeHumidity))%")
                .sweatType(.caption13)
                .foregroundStyle(Ink.n600)
                .frame(height: 18)
        }
        .frame(width: 62)
        .padding(.vertical, 6)
        .background(isCurrent ? Surface.accentWash : Color.clear,
                    in: RoundedRectangle(cornerRadius: Radius.lg))
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
        VStack(alignment: .leading, spacing: 0) {
            Text(HomeCopy.Forecast.weekly)
                .sweatType(.section15)
                .foregroundStyle(Ink.n900)
                .padding(.bottom, Space.x2)

            columnLabels
                .padding(.bottom, 6)

            VStack(spacing: 2) {
                ForEach(visible, id: \.date) { day in row(day) }
            }

            // 시간별 예보가 닿지 않는 날이 섞여 있으면 밝힌다 (「추정치는 추정치로」).
            if visible.contains(where: \.isApparentHighEstimated) {
                Text(HomeCopy.Forecast.estimatedNote)
                    .sweatType(.caption12)
                    .foregroundStyle(Ink.n400)
                    .padding(.top, Space.x3)
            }
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.x4)
        .overlay(alignment: .top) {
            Rectangle().fill(Ink.n900.opacity(0.14)).frame(height: 0.5)
                .padding(.horizontal, -Space.gutter)
        }
    }

    /// 주간 행의 각 수치가 무엇을 뜻하는지 설명한다.
    private var columnLabels: some View {
        HStack(spacing: 10) {
            columnLabel(HomeCopy.Forecast.dateColumn)
                .frame(width: 34, alignment: .leading)
            columnLabel(HomeCopy.Forecast.stageColumn)
                .frame(width: 88, alignment: .leading)
            columnLabel(HomeCopy.Forecast.temperatureRangeColumn)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 0) {
                columnLabel(HomeCopy.Forecast.lowColumn)
                Spacer(minLength: 0)
                columnLabel(HomeCopy.Forecast.highColumn)
            }
            .frame(width: 64)
        }
        .accessibilityHidden(true)
    }

    private func columnLabel(_ value: String) -> some View {
        Text(value)
            .sweatType(.overline11)
            .foregroundStyle(Ink.n400)
    }

    private func row(_ day: DailyForecast) -> some View {
        let stage = profile.stage(forApparent: day.apparentHigh)
        let level = ForecastLevel(stage)
        let isToday = Calendar.current.isDateInToday(day.date)
        return HStack(spacing: Space.x2 + 2) {
            Text(weekday(day.date)).sweatType(.label14Medium)
                .foregroundStyle(isToday ? Ink.n900 : Ink.n600)
                .frame(width: 34, alignment: .leading)
            WeatherFace(level: level.rawValue, size: 22)
            Text(HomeCopy.Forecast.levelName(level))
                .sweatType(.list125)
                .foregroundStyle(StageRole.ink(stage.rawValue))
                .frame(width: 56, alignment: .leading)
            RangeBar(range: day.lowTemperature...day.highTemperature, bounds: bounds,
                     color: StageRole.outline(stage.rawValue))
            HStack(spacing: 5) {
                Text("\(Int(day.lowTemperature))°")
                    .sweatType(.caption13)
                    .foregroundStyle(Ink.n400)
                Text("\(Int(day.highTemperature))°")
                    .sweatType(.caption13)
                    .fontWeight(.semibold)
                    .foregroundStyle(Ink.n900)
            }
            .frame(width: 64, alignment: .trailing)
        }
        .padding(.vertical, 7)
        .background {
            if isToday {
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(Surface.accentWash)
                    .padding(.horizontal, -6)
            }
        }
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
