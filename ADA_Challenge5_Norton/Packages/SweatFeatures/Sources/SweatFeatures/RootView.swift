import SwiftUI
import SweatPersistence
import WeatherData
import SweatDomain

/// 앱의 첫 화면을 정한다.
///
/// 온보딩을 마쳤는지에 따라 갈린다. 마치기 전에 앱을 껐다 켜면 처음부터 다시 한다 —
/// 3단계짜리 흐름에 중간 저장을 넣을 이유가 없다.
public struct RootView: View {

    private enum Screen: Equatable {
        case onboarding(OnboardingFlow.Mode)
        case home
    }

    /// 홈과 상세가 같은 저장소를 봐야 두 화면의 단계가 어긋나지 않는다.
    @State private var home: HomeStore?

    /// 상세로 넘길 값.
    ///
    /// 화면 전환 시점에 값을 **들고 간다.** 목적지에서 옵셔널을 꺼내 쓰면
    /// 아직 준비되지 않았을 때 빈 화면이 나온다.
    private struct DetailPayload: Identifiable, Hashable {
        let observation: WeatherObservation
        let stage: SweatStage
        var id: Date { observation.observedAt }
    }

    private let store: ProfileStore
    private let weather: WeatherRepository
    private let location: any LocationProviding
    @State private var screen: Screen
    @State private var profile: UserProfile
    @State private var detail: DetailPayload?

    public init(
        store: ProfileStore = ProfileStore(),
        weather: WeatherRepository = WeatherRepository(source: WeatherKitSource()),
        location: any LocationProviding = SystemLocationProvider()
    ) {
        self.store = store
        self.weather = weather
        self.location = location
        let loaded = store.load()
        _profile = State(initialValue: loaded)
        _screen = State(initialValue: loaded.hasCompletedOnboarding ? .home : .onboarding(.initial))
    }

    public var body: some View {
        switch screen {
        case .onboarding(let mode):
            OnboardingView(flow: OnboardingFlow(store: store, mode: mode) {
                profile = store.load()
                screen = .home
            })
            // 모드가 바뀌면 흐름을 새로 만든다. 같은 인스턴스를 재사용하면 이전 단계가 남는다.
            .id(mode)

        case .home:
            let store = home ?? HomeStore(repository: weather, location: location) { profile }
            NavigationStack {
                HomeView(store: store, onOpenDetail: {
                    // 값이 있을 때만 넘어간다. 없으면 아무 일도 하지 않는다.
                    guard let observation = store.observation, let stage = store.stage else { return }
                    detail = DetailPayload(observation: observation, stage: stage)
                })
                .navigationDestination(item: $detail) { payload in
                    StageDetailView(
                        observation: payload.observation,
                        stage: payload.stage,
                        attribution: store.attribution
                    ) {
                        detail = nil
                    }
                    // 화면이 자체 뒤로가기를 갖고 있어 시스템 바를 숨긴다.
                    #if os(iOS)
                    .toolbar(.hidden, for: .navigationBar)
                    #endif
                }
            }
            .onAppear { if home == nil { home = store } }
        }
    }
}
