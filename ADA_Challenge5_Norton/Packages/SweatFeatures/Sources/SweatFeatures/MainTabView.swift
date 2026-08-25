import DesignSystem
import SwiftUI
import SweatDomain

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
    private let home: HomeStore
    private let moveRuntime: MoveBackgroundRuntime

    init(
        home: HomeStore,
        moveRuntime: MoveBackgroundRuntime = .shared
    ) {
        self.home = home
        self.moveRuntime = moveRuntime
        moveRuntime.resumeIfNeeded()
        _selectedTab = State(initialValue: moveRuntime.hasActiveMove ? .map : .home)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(MainTabCopy.home, systemImage: "house", value: AppTab.home) {
                homeTab
            }
            Tab(MainTabCopy.map, systemImage: "map", value: AppTab.map) {
                RouteFlowView(
                    stage: { home.stage ?? .one },
                    moveRuntime: moveRuntime
                )
            }
            Tab(MainTabCopy.me, systemImage: "person", value: AppTab.me) {
                NavigationStack {
                    ContentUnavailableView(
                        MainTabCopy.mePendingTitle,
                        systemImage: "person",
                        description: Text(MainTabCopy.mePendingBody)
                    )
                    .background(Surface.page)
                }
            }
        }
        .tint(Accent.base)
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
    static let mePendingTitle = "마이 기능을 준비하고 있어요"
    static let mePendingBody = "자가 기록과 리포트는 다음 단계에서 연결할게요."
}
