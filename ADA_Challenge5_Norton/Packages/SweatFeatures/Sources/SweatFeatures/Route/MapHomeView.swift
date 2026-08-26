import DesignSystem
import SwiftUI

struct MapHomeView: View {
    enum Phase: Sendable, Equatable {
        case ready
        case failed
    }

    private let phase: Phase
    private let onRetry: () -> Void
    private let onSearch: () -> Void

    init(
        phase: Phase = .ready,
        onRetry: @escaping () -> Void = {},
        onSearch: @escaping () -> Void
    ) {
        self.phase = phase
        self.onRetry = onRetry
        self.onSearch = onSearch
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(RouteCopy.mapTitle)
                    .sweatType(.title22Bold)
                    .foregroundStyle(Ink.n900)
                Spacer()
                Button(action: onSearch) {
                    Image(systemName: "magnifyingglass")
                        .imageScale(.large)
                        .foregroundStyle(Accent.base)
                        .frame(width: 44, height: 44)
                        .background(Surface.card, in: Circle())
                        .shadow(color: Ink.n900.opacity(0.18), radius: 3, y: 1)
                }
                .accessibilityLabel(RouteCopy.searchAction)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.x3)

            switch phase {
            case .ready:
                RouteMapView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .failed:
                ContentUnavailableView {
                    Label(RouteCopy.mapUnavailableTitle, systemImage: "map")
                        .foregroundStyle(Ink.n900)
                } description: {
                    Text(RouteCopy.mapUnavailableBody)
                        .foregroundStyle(Ink.n600)
                } actions: {
                    Button(RouteCopy.retry, action: onRetry)
                        .buttonStyle(.borderedProminent)
                        .tint(Accent.base)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Surface.page)
            }
        }
        .background(Surface.page)
    }
}

#if DEBUG
#Preview("06 · 지도") {
    MapHomeView {}
        .frame(width: 402, height: 874)
}

#Preview("06 · 지도 실패") {
    MapHomeView(phase: .failed, onRetry: {}) {}
        .frame(width: 402, height: 874)
}
#endif
