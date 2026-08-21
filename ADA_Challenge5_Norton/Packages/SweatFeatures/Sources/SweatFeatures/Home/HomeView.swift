import SwiftUI
import DesignSystem
import SweatDomain

/// 홈 — 오늘의 땀 단계.
public struct HomeView: View {

    @State private var store: HomeStore
    private let onOpenDetail: () -> Void

    public init(store: HomeStore, onOpenDetail: @escaping () -> Void) {
        _store = State(initialValue: store)
        self.onOpenDetail = onOpenDetail
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                switch store.phase {
                case .loading:
                    ProgressView().padding(.top, Space.x7 * 2)
                case .needsRegion(let reason):
                    RegionPicker(reason: reason) { region in
                        Task { await store.select(region) }
                    }
                    .padding(.top, Space.x7)
                case .failed:
                    FailureNotice { Task { await store.load() } }
                        .padding(.top, Space.x7)
                case .ready:
                    content
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, Space.x7)
        }
        .frame(maxWidth: .infinity)
        .background(Surface.page)
        .task { await store.load() }
    }

    @ViewBuilder
    private var content: some View {
        if let observation = store.observation, let stage = store.stage, let copy = store.copy {
            VStack(spacing: 0) {
                header(observation)
                ObservationRow(observation: observation)
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.x2)

                SweatCharacter(stage: stage.rawValue)
                    .padding(.top, Space.x4)

                Text(copy.headline)
                    .sweatType(.hero31)
                    .foregroundStyle(Ink.n900)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.x4)
                    // 마스코트는 장식이라 숨겼다. 단계는 여기서 말로 전달한다.
                    .accessibilityLabel("\(stage.rawValue)단계, \(copy.state). \(copy.headline)")

                detailLink

                if let forecast = store.forecast {
                    HourlyForecastSection(hourly: forecast.hourly, profile: store)
                        .padding(.top, Space.x6)
                    WeeklyForecastSection(daily: forecast.daily, profile: store)
                        .padding(.top, Space.x5)
                }

                if let attribution = store.attribution {
                    AttributionBlock(info: attribution)
                        .padding(.top, Space.x6)
                        .padding(.horizontal, Space.gutter)
                }
            }
        }
    }

    private func header(_ observation: WeatherObservation) -> some View {
        VStack(spacing: 2) {
            if let region = store.region {
                Text(HomeCopy.Location.name(region))
                    .sweatType(.bodyStrong16)
                    .foregroundStyle(Ink.n900)
            }
            HStack(spacing: Space.x1) {
                Text(HomeCopy.observedAt(HomeCopy.Format.time(observation.observedAt)))
                if let minutes = store.minutesSinceObservation, minutes >= 30 {
                    // 오래된 값을 최신인 척 보여주지 않는다.
                    Text("· \(HomeCopy.staleBadge(minutes: minutes))")
                        .foregroundStyle(Magenta.deep)
                }
            }
            .sweatType(.caption12)
            .foregroundStyle(Ink.n400)
        }
        .padding(.top, Space.x4)
    }

    private var detailLink: some View {
        HStack {
            Spacer()
            Button(action: onOpenDetail) {
                Text(HomeCopy.detailLink)
                    .sweatType(.label14Medium)
                    .foregroundStyle(Accent.base)
            }
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.x2)
    }
}

/// 기온·습도·체감 세 칸.
struct ObservationRow: View {
    let observation: WeatherObservation

    var body: some View {
        HStack(spacing: 0) {
            cell(HomeCopy.Observation.temperature,
                 "\(observation.temperature.formatted(.number.precision(.fractionLength(1))))℃",
                 Ink.n900)
            divider
            cell(HomeCopy.Observation.humidity,
                 "\(Int(observation.relativeHumidity))%", Ink.n900)
            divider
            cell(HomeCopy.Observation.apparent,
                 "\(observation.apparentTemperature.formatted(.number.precision(.fractionLength(1))))℃",
                 Magenta.deep)
        }
    }

    private var divider: some View {
        Rectangle().fill(Ink.n900.opacity(0.14)).frame(width: 1, height: 34)
    }

    private func cell(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label).sweatType(.overline11).foregroundStyle(Ink.n400)
            Text(value).sweatType(.stat18).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
