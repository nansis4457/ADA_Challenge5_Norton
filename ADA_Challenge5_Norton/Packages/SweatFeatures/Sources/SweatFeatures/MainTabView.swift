import DesignSystem
import SwiftUI
import SweatDomain
import SweatPersistence

/// 온보딩 이후의 세 탭. 각 탭은 자신의 내비게이션 흐름을 가진다.
struct MainTabView: View {
    private enum AppTab: Hashable {
        case home
        case map
        case me
    }

    private struct DetailPayload: Identifiable, Hashable {
        let observation: WeatherObservation
        let stage: SweatStage
        var id: Date { observation.observedAt }
    }

    @State private var selectedTab: AppTab = .home
    @State private var detail: DetailPayload?
    @State private var completedMove: MoveCompletion?
    private let home: HomeStore
    private let moveRuntime: MoveBackgroundRuntime
    private let profileStore: ProfileStore
    private let location: any LocationProviding
    private let profile: () -> UserProfile
    private let onProfileUpdated: (UserProfile) -> Void

    init(
        home: HomeStore,
        moveRuntime: MoveBackgroundRuntime = .shared,
        profileStore: ProfileStore,
        location: any LocationProviding,
        profile: @escaping () -> UserProfile,
        onProfileUpdated: @escaping (UserProfile) -> Void
    ) {
        self.home = home
        self.moveRuntime = moveRuntime
        self.profileStore = profileStore
        self.location = location
        self.profile = profile
        self.onProfileUpdated = onProfileUpdated
        moveRuntime.resumeIfNeeded()
        #if DEBUG
        // 수동 시뮬레이터 검증에서 긴 홈 스크롤 없이 마이 화면부터 확인한다.
        let opensProfile = ProcessInfo.processInfo.arguments.contains("-open-profile")
        _selectedTab = State(initialValue: opensProfile ? .me : (moveRuntime.hasActiveMove ? .map : .home))
        #else
        _selectedTab = State(initialValue: moveRuntime.hasActiveMove ? .map : .home)
        #endif
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(MainTabCopy.home, systemImage: "house", value: AppTab.home) {
                homeTab
            }
            Tab(MainTabCopy.map, systemImage: "map", value: AppTab.map) {
                RouteFlowView(
                    stage: { home.stage ?? .one },
                    location: location,
                    automaticallyUsesCurrentLocation: profile().usesCurrentLocation,
                    moveRuntime: moveRuntime
                ) { completion in
                    completedMove = completion
                    selectedTab = .me
                }
            }
            Tab(MainTabCopy.me, systemImage: "person", value: AppTab.me) {
                ProfileFlowView(
                    home: home,
                    store: profileStore,
                    location: location,
                    profile: profile,
                    completedMove: $completedMove,
                    onProfileUpdated: onProfileUpdated
                )
            }
        }
        .tint(Accent.base)
        // 마이 탭에서 바로 기록을 열어도 오늘 예측이 준비돼 있어야 한다.
        .task { await home.load() }
    }

    private var homeTab: some View {
        NavigationStack {
            HomeView(store: home, onOpenDetail: openDetail)
                .navigationDestination(item: $detail) { payload in
                    StageDetailView(
                        observation: payload.observation,
                        stage: payload.stage,
                        attribution: home.attribution
                    ) {
                        detail = nil
                    }
                    #if os(iOS)
                    .toolbar(.hidden, for: .navigationBar)
                    #endif
                }
        }
    }

    private func openDetail() {
        guard let observation = home.observation, let stage = home.stage else { return }
        detail = DetailPayload(observation: observation, stage: stage)
    }
}

enum MainTabCopy {
    static let home = "홈"
    static let map = "지도"
    static let me = "마이"
}
