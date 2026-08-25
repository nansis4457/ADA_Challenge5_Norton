import DesignSystem
import SwiftUI

struct MapHomeView: View {
    let onSearch: () -> Void

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
                        .frame(width: 40, height: 40)
                        .background(Surface.card, in: Circle())
                        .shadow(color: Ink.n900.opacity(0.18), radius: 3, y: 1)
                }
                .accessibilityLabel(RouteCopy.searchAction)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.x3)

            RouteMapView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Surface.page)
    }
}
