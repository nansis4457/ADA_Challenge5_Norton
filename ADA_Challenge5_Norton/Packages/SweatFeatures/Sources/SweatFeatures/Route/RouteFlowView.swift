import SwiftUI
import SweatDomain

struct RouteFlowView: View {
    private enum Destination: Hashable {
        case input
        case result
    }

    @State private var store: RouteStore
    @State private var path: [Destination] = []
    @State private var pendingStartRoute: WalkingRoute?
    @State private var showsStartPending = false

    init(stage: @escaping () -> SweatStage) {
        _store = State(initialValue: RouteStore(stage: stage))
    }

    var body: some View {
        NavigationStack(path: $path) {
            MapHomeView {
                path.append(.input)
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .input:
                    RouteInputView(store: store) {
                        path.append(.result)
                    }
                case .result:
                    RouteResultView(store: store) { route in
                        pendingStartRoute = route
                        showsStartPending = true
                    }
                }
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
        .alert(RouteCopy.startPendingTitle, isPresented: $showsStartPending) {
            Button(RouteCopy.confirm, role: .cancel) {}
        } message: {
            if let pendingStartRoute {
                Text(RouteCopy.startPendingMessage(
                    origin: pendingStartRoute.origin.name,
                    destination: pendingStartRoute.destination.name
                ))
            } else {
                Text(RouteCopy.startPendingBody)
            }
        }
    }
}
