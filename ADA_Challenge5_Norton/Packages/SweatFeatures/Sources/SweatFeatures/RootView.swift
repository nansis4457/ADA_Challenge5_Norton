import SwiftUI
import SweatPersistence
import WeatherData

/// 앱의 첫 화면을 정한다.
///
/// 온보딩을 마쳤는지에 따라 갈린다. 마치기 전에 앱을 껐다 켜면 처음부터 다시 한다 —
/// 3단계짜리 흐름에 중간 저장을 넣을 이유가 없다.
public struct RootView: View {

    private enum Screen: Equatable {
        case onboarding(OnboardingFlow.Mode)
        case home
    }

    private let store: ProfileStore
    private let weather: WeatherRepository
    private let location: any LocationProviding
    @State private var screen: Screen
    @State private var profile: UserProfile

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
            HomeView(
                store: HomeStore(repository: weather, location: location) { profile },
                onOpenDetail: {}   // 등급 상세는 T050에서 연결한다
            )
        }
    }
}
