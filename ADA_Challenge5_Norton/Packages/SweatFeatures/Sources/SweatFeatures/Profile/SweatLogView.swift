import DesignSystem
import SwiftData
import SwiftUI
import SweatDomain
import SweatPersistence

/// Figma `11 자가 기록` — 오늘 예측과 실제 체감을 한 날짜에 저장한다.
struct SweatLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \SweatLog.date, order: .reverse) private var logs: [SweatLog]

    let home: HomeStore
    let profileStore: ProfileStore
    let profile: () -> UserProfile
    let onProfileUpdated: (UserProfile) -> Void

    @State private var score: Int?
    @State private var selectedTags: Set<SweatLogTag> = []
    @State private var routeOutdoorMinutes: Int?
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var didLoadExistingLog = false

    init(
        home: HomeStore,
        profileStore: ProfileStore,
        profile: @escaping () -> UserProfile,
        onProfileUpdated: @escaping (UserProfile) -> Void,
        routeOutdoorMinutes: Int? = nil
    ) {
        self.home = home
        self.profileStore = profileStore
        self.profile = profile
        self.onProfileUpdated = onProfileUpdated
        _routeOutdoorMinutes = State(initialValue: routeOutdoorMinutes)
    }

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

                Text(ProfileCopy.logKicker)
                    .sweatType(.overline11)
                    .foregroundStyle(Accent.deep)
                    .padding(.top, Space.x4)

                Text(ProfileCopy.logHeading)
                    .sweatType(.title29)
                    .foregroundStyle(Ink.n900)
                    .padding(.top, Space.x2)

                Text(ProfileCopy.logSub)
                    .sweatType(.body15)
                    .foregroundStyle(Ink.n600)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Space.x2)

                scorePicker
                    .padding(.top, Space.x6)

                Text(ProfileCopy.tagPrompt)
                    .sweatType(.bodyStrong16)
                    .foregroundStyle(Ink.n900)
                    .padding(.top, Space.x7)

                FlowLayout(spacing: Space.x2) {
                    ForEach(SweatLogTag.allCases, id: \.self) { tag in
                        SweatChip(ProfileCopy.tagTitle(tag), isOn: selectedTags.contains(tag)) {
                            toggle(tag)
                        }
                    }
                }
                .padding(.top, Space.x2)

                predictionCard
                    .padding(.top, Space.x7)

                if let errorMessage {
                    Text(errorMessage)
                        .sweatType(.body14)
                        .foregroundStyle(Magenta.deep)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Space.x4)
                }
            }
            .padding(.horizontal, Space.gutter)
            .padding(.top, Space.x4)
            .padding(.bottom, 100)
        }
        .background(Surface.page)
        .safeAreaInset(edge: .bottom) {
            SweatButton(ProfileCopy.saveLog, action: save)
                .disabled(!canSave || isSaving)
                .opacity(canSave && !isSaving ? 1 : 0.48)
                .padding(.horizontal, Space.gutter)
                .padding(.vertical, Space.x3)
                .background(Surface.page)
        }
        .task { loadExistingLogIfNeeded() }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    @ViewBuilder
    private var scorePicker: some View {
        VStack(spacing: Space.x2) {
            if dynamicTypeSize.isAccessibilitySize {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 58), spacing: Space.x2)],
                    spacing: Space.x2
                ) {
                    scoreButtons
                }
            } else {
                HStack(spacing: Space.x2) { scoreButtons }
            }

            HStack {
                Text(ProfileCopy.comfortable)
                Spacer()
                Text(ProfileCopy.verySweaty)
            }
            .sweatType(.caption12)
            .foregroundStyle(Ink.n400)
        }
    }

    private var scoreButtons: some View {
        ForEach(1...5, id: \.self) { value in
            ScoreButton(value, isSelected: score == value) {
                score = value
                errorMessage = nil
            }
        }
    }

    @ViewBuilder
    private var predictionCard: some View {
        VStack(alignment: .leading, spacing: Space.x2) {
            Text(ProfileCopy.todayPrediction)
                .sweatType(.caption13)
                .foregroundStyle(Ink.n500)

            if let stage = home.stage {
                Text(ProfileCopy.predictionTitle(stage: stage))
                    .sweatType(.bodyStrong16)
                    .foregroundStyle(Ink.n900)
                Text(ProfileCopy.predictionMessage(stage: stage, score: score))
                    .sweatType(.body135)
                    .foregroundStyle(Ink.n600)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(ProfileCopy.weatherUnavailableMessage())
                    .sweatType(.body135)
                    .foregroundStyle(Ink.n600)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Space.x4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Surface.accentWash,
            in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }

    private var canSave: Bool {
        score != nil && home.observation != nil && home.stage != nil
    }

    private func toggle(_ tag: SweatLogTag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
        errorMessage = nil
    }

    private func loadExistingLogIfNeeded() {
        guard !didLoadExistingLog else { return }
        didLoadExistingLog = true
        let key = SweatLogRepository.dayKey(for: Date())
        guard let existing = logs.first(where: { $0.dayKey == key }) else { return }
        score = existing.actualScore
        selectedTags = existing.selectedTags
        if routeOutdoorMinutes == nil {
            routeOutdoorMinutes = existing.routeOutdoorMinutes
        }
    }

    private func save() {
        guard !isSaving else { return }
        guard let observation = home.observation,
              let stage = home.stage,
              let score,
              let draft = SweatLogDraft(
                date: Date(),
                predictedStage: stage.rawValue,
                actualScore: score,
                tags: selectedTags,
                apparentTemperature: observation.apparentTemperature,
                relativeHumidity: observation.relativeHumidity,
                windSpeed: observation.windSpeed,
                routeOutdoorMinutes: routeOutdoorMinutes
              )
        else {
            errorMessage = ProfileCopy.weatherUnavailableMessage()
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let repository = SweatLogRepository(context: modelContext)
            let isNewDay = try repository.log(on: draft.date) == nil
            try repository.upsert(draft)

            if isNewDay {
                let samples = try repository.all().compactMap(\.calibrationSample)
                let currentProfile = profile()
                let result = CalibrationEngine.evaluate(
                    samples: samples,
                    currentCalibration: currentProfile.calibrationOffset
                )
                if result.hasEnoughSamples {
                    var updated = currentProfile
                    updated.calibrationOffset = result.nextCalibration
                    profileStore.save(updated)
                    onProfileUpdated(updated)
                }
            }

            dismiss()
        } catch {
            errorMessage = ProfileCopy.saveFailure
        }
    }
}
