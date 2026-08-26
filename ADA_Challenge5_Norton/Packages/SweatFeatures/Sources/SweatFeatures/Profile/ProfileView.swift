import DesignSystem
import SwiftData
import SwiftUI
import SweatDomain
import SweatPersistence
import WeatherData

/// 마이 탭의 내비게이션과 설정 편집 시트를 소유한다.
struct ProfileFlowView: View {
    private enum Destination: Hashable {
        case moveLog(id: UUID, outdoorMinutes: Int?)
    }

    private let home: HomeStore
    private let store: ProfileStore
    private let location: any LocationProviding
    private let profile: () -> UserProfile
    private let onProfileUpdated: (UserProfile) -> Void
    @Binding private var completedMove: MoveCompletion?
    @State private var path: [Destination] = []
    @State private var editingStep: OnboardingFlow.Step?

    init(
        home: HomeStore,
        store: ProfileStore,
        location: any LocationProviding,
        profile: @escaping () -> UserProfile,
        completedMove: Binding<MoveCompletion?>,
        onProfileUpdated: @escaping (UserProfile) -> Void
    ) {
        self.home = home
        self.store = store
        self.location = location
        self.profile = profile
        self._completedMove = completedMove
        self.onProfileUpdated = onProfileUpdated
    }

    var body: some View {
        NavigationStack(path: $path) {
            ProfileView(
                home: home,
                store: store,
                profile: profile,
                onProfileUpdated: onProfileUpdated
            ) { step in
                editingStep = step
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .moveLog(_, let outdoorMinutes):
                    SweatLogView(
                        home: home,
                        profileStore: store,
                        profile: profile,
                        onProfileUpdated: onProfileUpdated,
                        routeOutdoorMinutes: outdoorMinutes
                    )
                }
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
        .sheet(item: $editingStep) { step in
            OnboardingView(flow: OnboardingFlow(
                store: store,
                mode: .editing(step),
                location: location
            ) {
                onProfileUpdated(store.load())
                editingStep = nil
            })
            .id(step)
        }
        .onAppear { openCompletedMoveIfNeeded() }
        .onChange(of: completedMove) { _, _ in openCompletedMoveIfNeeded() }
    }

    private func openCompletedMoveIfNeeded() {
        guard let completion = completedMove else { return }
        path = [.moveLog(
            id: completion.id,
            outdoorMinutes: MoveLogHandoff.outdoorMinutes(from: completion)
        )]
        completedMove = nil
    }
}

/// 이동 완료 값 중 005가 실제로 저장할 수 있는 집계만 변환한다.
enum MoveLogHandoff {
    static func outdoorMinutes(from completion: MoveCompletion) -> Int? {
        completion.observedOutdoorTime.map { Int($0 / 60) }
    }
}

/// Figma `10 마이페이지`를 실제 프로필과 기록으로 채운 화면.
struct ProfileView: View {
    @Query(sort: \SweatLog.date, order: .reverse) private var logs: [SweatLog]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let home: HomeStore
    let store: ProfileStore
    let profile: () -> UserProfile
    let onProfileUpdated: (UserProfile) -> Void
    let onEdit: (OnboardingFlow.Step) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(ProfileCopy.title)
                    .sweatType(.title24Bold)
                    .foregroundStyle(Ink.n900)

                profileCard
                    .padding(.top, Space.x5)

                statisticsCard
                    .padding(.top, Space.x3)

                sectionTitle(ProfileCopy.managementSection)
                    .padding(.top, Space.x7)

                managementCard
                    .padding(.top, Space.x3)

                sectionTitle(ProfileCopy.settingsSection)
                    .padding(.top, Space.x7)

                settingsCard
                    .padding(.top, Space.x3)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.top, Space.x6)
            .padding(.bottom, Space.x7)
        }
        .background(Surface.page)
    }

    private var profileCard: some View {
        Button { onEdit(.sensitivity) } label: {
            HStack(spacing: Space.x4) {
                ZStack {
                    Circle().fill(Surface.accentTint)
                    Text(ProfileCopy.avatarInitial)
                        .sweatType(.stat20Bold)
                        .foregroundStyle(Accent.deep)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: Space.x1) {
                    Text(ProfileCopy.profileName)
                        .sweatType(.bodyStrong16)
                        .foregroundStyle(Ink.n900)
                    Text(ProfileCopy.profileMeta(profile()))
                        .sweatType(.list125)
                        .foregroundStyle(Ink.n500)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: Space.x2)

                Image(systemName: ProfileSymbol.chevron)
                    .foregroundStyle(Ink.n500)
                    .accessibilityHidden(true)
            }
            .padding(Space.x4)
            .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
            .background(Surface.card, in: cardShape)
            .contentShape(cardShape)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var statisticsCard: some View {
        let content = Group {
            ProfileStatistic(
                value: ProfileCopy.recordedDaysValue(logs.count),
                label: ProfileCopy.recordedDays
            )
            ProfileStatistic(
                value: ProfileCopy.averageScoreValue(logs),
                label: ProfileCopy.averageScore
            )
            ProfileStatistic(
                value: ProfileCopy.differenceValue(logs),
                label: ProfileCopy.predictionDifference
            )
        }

        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Space.x4) { content }
                .statisticCardStyle()
        } else {
            HStack(alignment: .top, spacing: Space.x2) { content }
                .statisticCardStyle()
        }
    }

    private var managementCard: some View {
        VStack(spacing: 0) {
            NavigationLink {
                SweatLogView(
                    home: home,
                    profileStore: store,
                    profile: profile,
                    onProfileUpdated: onProfileUpdated
                )
            } label: {
                ProfileMenuRow(
                    title: ProfileCopy.logToday,
                    subtitle: ProfileCopy.todayStatus(hasLog: todayLog != nil)
                )
            }

            rowDivider

            NavigationLink {
                CalibrationReportView(profile: profile)
            } label: {
                ProfileMenuRow(title: ProfileCopy.history, subtitle: ProfileCopy.historyDescription)
            }

            rowDivider

            Button { onEdit(.sensitivity) } label: {
                ProfileMenuRow(
                    title: ProfileCopy.editSensitivity,
                    subtitle: ProfileCopy.sensitivityValue(profile().sensitivity)
                )
            }
            .buttonStyle(.plain)

            rowDivider

            Button { onEdit(.movement) } label: {
                ProfileMenuRow(
                    title: ProfileCopy.editMovement,
                    subtitle: ProfileCopy.movementValue(profile())
                )
            }
            .buttonStyle(.plain)

            rowDivider

            if let observation = home.observation, let stage = home.stage {
                NavigationLink {
                    ProfileStageDetailView(
                        observation: observation,
                        stage: stage,
                        attribution: home.attribution
                    )
                } label: {
                    ProfileMenuRow(
                        title: ProfileCopy.stageGuide,
                        subtitle: ProfileCopy.stageGuideDescription
                    )
                }
            } else {
                ProfileMenuRow(
                    title: ProfileCopy.stageGuide,
                    subtitle: ProfileCopy.weatherNeeded,
                    showsChevron: false
                )
            }
        }
        .background(Surface.card, in: cardShape)
        .clipShape(cardShape)
    }

    private var settingsCard: some View {
        VStack(spacing: 0) {
            Button { onEdit(.notification) } label: {
                ProfileMenuRow(
                    title: ProfileCopy.notification,
                    subtitle: ProfileCopy.notificationValue(profile())
                )
            }
            .buttonStyle(.plain)

            rowDivider

            Button { onEdit(.location) } label: {
                ProfileMenuRow(
                    title: ProfileCopy.location,
                    subtitle: ProfileCopy.locationValue(
                        profile: profile(),
                        placeName: home.placeName,
                        region: home.region
                    )
                )
            }
            .buttonStyle(.plain)

            rowDivider

            ProfileMenuRow(
                title: ProfileCopy.dataSource,
                subtitle: ProfileCopy.dataSourceValue(home.attribution?.serviceName),
                showsChevron: false
            )
        }
        .background(Surface.card, in: cardShape)
        .clipShape(cardShape)
    }

    private var todayLog: SweatLog? {
        let key = SweatLogRepository.dayKey(for: Date())
        return logs.first { $0.dayKey == key }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .sweatType(.section15)
            .foregroundStyle(Ink.n900)
    }

    private var rowDivider: some View {
        Divider()
            .overlay(BorderColor.subtle)
            .padding(.leading, Space.x4)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
    }
}

private struct ProfileStatistic: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: Space.x1) {
            Text(value)
                .sweatType(.stat20)
                .foregroundStyle(Ink.n900)
            Text(label)
                .sweatType(.caption12)
                .foregroundStyle(Ink.n500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private extension View {
    func statisticCardStyle() -> some View {
        self
            .padding(Space.x4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Surface.card,
                in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
            )
    }
}

private struct ProfileMenuRow: View {
    let title: String
    let subtitle: String
    var showsChevron = true

    var body: some View {
        HStack(spacing: Space.x3) {
            VStack(alignment: .leading, spacing: Space.x1) {
                Text(title)
                    .sweatType(.list16)
                    .foregroundStyle(Ink.n900)
                Text(subtitle)
                    .sweatType(.list125)
                    .foregroundStyle(Ink.n500)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Space.x2)
            if showsChevron {
                Image(systemName: ProfileSymbol.chevron)
                    .foregroundStyle(Ink.n500)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, Space.x4)
        .padding(.vertical, Space.x3)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

private struct ProfileStageDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let observation: WeatherObservation
    let stage: SweatStage
    let attribution: WeatherAttributionInfo?

    var body: some View {
        StageDetailView(
            observation: observation,
            stage: stage,
            attribution: attribution
        ) {
            dismiss()
        }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }
}

private enum ProfileSymbol {
    static let chevron = "chevron.right"
}
