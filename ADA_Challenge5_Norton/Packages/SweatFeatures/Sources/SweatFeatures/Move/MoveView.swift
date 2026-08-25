import DesignSystem
import SwiftUI
import SweatDomain

struct MoveView: View {
    @Bindable var store: MoveStore
    let onFinished: (MoveCompletion) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                heading
                    .padding(.top, Space.x4 + 2)
                progress
                    .padding(.top, Space.x5)
                actions
                    .padding(.top, Space.x6)
                issues
                    .padding(.top, Space.x3)
                finishButton
                    .padding(.top, Space.x7 - Space.x1)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.top, Space.x2 + 2)
            .padding(.bottom, Space.x7)
        }
        .background(Surface.page)
        .navigationBarBackButtonHidden(true)
        .task { store.start() }
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                kicker
                Spacer(minLength: Space.x2)
                progressLine
            }
            VStack(alignment: .leading, spacing: Space.x1) {
                kicker
                progressLine
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var kicker: some View {
        Text(MoveCopy.kicker)
            .sweatType(.overline11)
            .foregroundStyle(Ink.n600)
    }

    private var progressLine: some View {
        Text(MoveCopy.progressLine(store.progress))
            .sweatType(.caption13)
            .foregroundStyle(Ink.n600)
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: Space.x2) {
            if let estimate = store.recommendations.aheadExposure {
                Text(MoveCopy.exposureHeading)
                    .sweatType(.title29)
                    .foregroundStyle(Ink.n900)
                Text(MoveCopy.exposureBody(
                    estimate,
                    hasShelter: store.recommendations.shelter != nil
                ))
                    .sweatType(.body15)
                    .foregroundStyle(Ink.n600)
            } else {
                Text(MoveCopy.basicHeading)
                    .sweatType(.title29)
                    .foregroundStyle(Ink.n900)
                Text(MoveCopy.basicBody)
                    .sweatType(.body15)
                    .foregroundStyle(Ink.n600)
            }
        }
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: Space.x1) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        .fill(Ink.n300)
                    RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        .fill(Accent.base)
                        .frame(width: proxy.size.width * store.progress.fractionCompleted)
                }
            }
            .frame(height: 5)

            ViewThatFits(in: .horizontal) {
                HStack {
                    Text(store.session.route.origin.name)
                    Spacer(minLength: Space.x2)
                    Text(store.session.route.destination.name)
                }
                VStack(alignment: .leading, spacing: Space.x1) {
                    Text(store.session.route.origin.name)
                    Text(store.session.route.destination.name)
                }
            }
            .sweatType(.caption12)
            .foregroundStyle(Ink.n600)

            Text(MoveCopy.remainingTime(store.progress))
                .sweatType(.caption13)
                .foregroundStyle(Ink.n600)
                .padding(.top, Space.x1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(MoveCopy.progressAccessibility(
            route: store.session.route,
            progress: store.progress
        ))
    }

    private var actions: some View {
        VStack(spacing: Space.x3) {
            if let shelter = store.recommendations.shelter {
                SelectableCard(
                    title: MoveCopy.shelterAction,
                    description: MoveCopy.shelterDetail(shelter),
                    titleStyle: .bodyStrong16,
                    isSelected: store.selectedRecommendation == .shelter(shelter.id)
                ) {
                    store.selectShelter(shelter)
                }
                .accessibilityLabel(MoveCopy.shelterAccessibility(shelter))
            }

            if let detour = store.recommendations.shadeDetour {
                SelectableCard(
                    title: MoveCopy.detourAction,
                    description: MoveCopy.detourDetail(detour),
                    titleStyle: .bodyStrong16,
                    isSelected: store.selectedRecommendation == .shadeDetour(detour.route.id)
                ) {
                    store.selectShadeDetour(detour)
                }
            }

            SelectableCard(
                title: MoveCopy.waterAction,
                description: store.isWaterReminderSelected
                    ? MoveCopy.waterScheduled
                    : MoveCopy.waterDetail,
                titleStyle: .bodyStrong16,
                isSelected: store.isWaterReminderSelected
            ) {
                store.toggleWaterReminder()
            }
            .disabled(store.reminderState == .scheduling)
        }
    }

    @ViewBuilder
    private var issues: some View {
        VStack(alignment: .leading, spacing: Space.x2) {
            switch store.trackingState {
            case .idle, .starting:
                issueText(MoveCopy.locationPending)
            case .stale(let lastObservedAt):
                issueText(MoveCopy.stale(lastObservedAt: lastObservedAt))
            case .authorizationDenied:
                issueText(MoveCopy.locationDenied)
            case .failed:
                issueText(MoveCopy.locationFailed)
            case .tracking, .ended:
                EmptyView()
            }

            switch store.reminderState {
            case .denied:
                issueText(MoveCopy.waterDenied)
            case .failed:
                issueText(MoveCopy.waterFailed)
            case .idle, .scheduling, .scheduled:
                EmptyView()
            }

            if store.hasLiveActivityIssue {
                issueText(MoveCopy.activityUnavailable)
            }
        }
    }

    private func issueText(_ text: String) -> some View {
        Text(text)
            .sweatType(.caption13)
            .foregroundStyle(Ink.n600)
            .padding(Space.x3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Surface.accentWash, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }

    private var finishButton: some View {
        VStack(spacing: Space.x2) {
            SweatButton(MoveCopy.finish) {
                Task {
                    if let completion = await store.finish() {
                        onFinished(completion)
                    }
                }
            }

            if store.trackingState == .authorizationDenied {
                SweatButton(MoveCopy.cancel, style: .ghost) {
                    Task {
                        if let completion = await store.finish() {
                            onFinished(completion)
                        }
                    }
                }
            }
        }
    }
}
