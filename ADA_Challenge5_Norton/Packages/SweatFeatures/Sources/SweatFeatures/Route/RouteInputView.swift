import DesignSystem
import RouteData
import SwiftUI

struct RouteInputView: View {
    @Bindable var store: RouteStore
    let onCalculated: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                backButton

                Text(RouteCopy.inputHeading)
                    .sweatType(.title28)
                    .foregroundStyle(Ink.n900)
                    .padding(.top, Space.x4)

                VStack(spacing: Space.x3 + 2) {
                    SweatTextField(RouteCopy.origin, text: $store.originQuery)
                    SweatTextField(RouteCopy.destination, text: $store.destinationQuery)
                }
                .padding(.top, Space.x5)
                .onChange(of: store.originQuery) { _, _ in store.queryDidChange(.origin) }
                .onChange(of: store.destinationQuery) { _, _ in store.queryDidChange(.destination) }

                currentLocationButton
                    .padding(.top, Space.x2)

                searchFeedback

                selectionStatus
                    .padding(.top, Space.x2)

                departurePicker
                    .padding(.top, Space.x5)

                SweatButton(RouteCopy.calculate) {
                    Task {
                        if await store.calculate() { onCalculated() }
                    }
                }
                .disabled(!store.canCalculate)
                .opacity(store.canCalculate ? 1 : 0.45)
                .padding(.top, Space.x7)

                if store.activity == .calculating {
                    ProgressView(RouteCopy.calculating)
                        .sweatType(.caption13)
                        .foregroundStyle(Ink.n600)
                        .frame(maxWidth: .infinity)
                        .padding(.top, Space.x3)
                }

                if let issue = store.issue, issue != .searchFailed {
                    issueView(issue)
                        .padding(.top, Space.x3)
                }

                Text(RouteCopy.inputNote)
                    .sweatType(.caption13)
                    .foregroundStyle(Ink.n500)
                    .padding(.top, Space.x4)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.top, Space.x2)
            .padding(.bottom, Space.x7)
        }
        .background(Surface.page)
        .navigationBarBackButtonHidden(true)
        .task { await store.prepareCurrentLocationIfNeeded() }
    }

    private var backButton: some View {
        Button { dismiss() } label: {
            HStack(spacing: Space.x1) {
                Image(systemName: "chevron.left")
                Text(RouteCopy.backToMap)
                    .sweatType(.body14)
            }
            .foregroundStyle(Accent.deep)
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(RouteCopy.backToMap)
    }

    @ViewBuilder
    private var searchFeedback: some View {
        if store.activity == .locating {
            ProgressView(RouteCopy.locatingCurrentLocation)
                .sweatType(.caption13)
                .foregroundStyle(Ink.n600)
                .frame(maxWidth: .infinity)
                .padding(.top, Space.x3)
        } else if store.activity == .searching || store.activity == .resolving {
            ProgressView(RouteCopy.searching)
                .sweatType(.caption13)
                .foregroundStyle(Ink.n600)
                .frame(maxWidth: .infinity)
                .padding(.top, Space.x3)
        } else if store.issue == .searchFailed {
            issueView(.searchFailed)
                .padding(.top, Space.x3)
        } else if !store.suggestions.isEmpty {
            suggestionList
                .padding(.top, Space.x2)
        } else if store.completedSearch {
            Text(RouteCopy.emptySearch)
                .sweatType(.caption13)
                .foregroundStyle(Ink.n600)
                .padding(.top, Space.x3)
        }
    }

    private var currentLocationButton: some View {
        Button {
            Task { await store.useCurrentLocation() }
        } label: {
            Label(RouteCopy.currentLocationAction, systemImage: "location.fill")
                .sweatType(.bodyStrong15)
                .foregroundStyle(Accent.deep)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(store.activity == .locating)
    }

    private var selectionStatus: some View {
        VStack(alignment: .leading, spacing: Space.x1) {
            selectionStatusRow(
                RouteCopy.selectionStatus(field: RouteCopy.origin, place: store.selectedOriginName),
                isSelected: store.selectedOriginName != nil
            )
            selectionStatusRow(
                RouteCopy.selectionStatus(field: RouteCopy.destination, place: store.selectedDestinationName),
                isSelected: store.selectedDestinationName != nil
            )
            if let locationMessage {
                Text(locationMessage)
                    .sweatType(.caption13)
                    .foregroundStyle(Magenta.deep)
            }
        }
    }

    private func selectionStatusRow(_ text: String, isSelected: Bool) -> some View {
        Label(text, systemImage: isSelected ? "checkmark.circle.fill" : "circle")
            .sweatType(.caption13)
            .foregroundStyle(isSelected ? Accent.deep : Ink.n600)
            .accessibilityLabel(text)
    }

    private var locationMessage: String? {
        switch store.locationOutcome {
        case .denied: RouteCopy.currentLocationDenied
        case .unavailable: RouteCopy.currentLocationUnavailable
        case .deferred: RouteCopy.currentLocationUnavailable
        case .located, .none: nil
        }
    }

    private var suggestionList: some View {
        VStack(spacing: 0) {
            ForEach(store.suggestions) { suggestion in
                Button {
                    Task { await store.select(suggestion) }
                } label: {
                    HStack(spacing: Space.x3) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(Accent.base)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title)
                                .sweatType(.bodyStrong15)
                                .foregroundStyle(Ink.n900)
                            if !suggestion.subtitle.isEmpty {
                                Text(suggestion.subtitle)
                                    .sweatType(.caption12)
                                    .foregroundStyle(Ink.n500)
                            }
                        }
                        Spacer(minLength: Space.x2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Space.x3)
                    .padding(.horizontal, Space.x4)
                }
                .buttonStyle(.plain)

                if suggestion.id != store.suggestions.last?.id {
                    Divider().padding(.leading, Space.x4)
                }
            }
        }
        .background(Surface.card, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }

    private var departurePicker: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(RouteCopy.departure)
                .sweatType(.overline11)
                .foregroundStyle(Ink.n500)

            DatePicker(
                RouteCopy.departure,
                selection: $store.departureDate,
                in: store.minimumDepartureDate...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .tint(Accent.base)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Space.x3)
            .padding(.horizontal, Space.x4)
            .background(Surface.card, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .accessibilityLabel(RouteCopy.departure)
        }
    }

    private func issueView(_ issue: RouteStore.Issue) -> some View {
        VStack(alignment: .leading, spacing: Space.x2) {
            Text(issueMessage(issue))
                .sweatType(.caption13)
                .foregroundStyle(Magenta.deep)
            if issue == .searchFailed {
                Button(RouteCopy.retry) { store.retrySearch() }
                    .sweatType(.bodyStrong15)
                    .foregroundStyle(Accent.deep)
                    .frame(minHeight: 44, alignment: .leading)
                    .contentShape(.rect)
            } else if issue == .routeFailed {
                Button(RouteCopy.retry) {
                    Task {
                        if await store.calculate() { onCalculated() }
                    }
                }
                .sweatType(.bodyStrong15)
                .foregroundStyle(Accent.deep)
                .frame(minHeight: 44, alignment: .leading)
                .contentShape(.rect)
            }
        }
    }

    private func issueMessage(_ issue: RouteStore.Issue) -> String {
        switch issue {
        case .searchFailed: RouteCopy.searchFailed
        case .routeFailed: RouteCopy.routeFailed
        case .routeUnavailable: RouteCopy.routeUnavailable
        }
    }
}
