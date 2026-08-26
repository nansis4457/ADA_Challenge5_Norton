import SwiftUI
import SweatDomain

struct RouteFlowView: View {
    private struct MoveDestination: Hashable {
        let id: UUID
        let store: MoveStore

        init(store: MoveStore) {
            self.id = store.session.id
            self.store = store
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    private enum Destination: Hashable {
        case input
        case result
        case move(MoveDestination)
    }

    @State private var store: RouteStore
    @State private var path: [Destination] = []
    private let moveRuntime: MoveBackgroundRuntime
    private let onMoveCompleted: (MoveCompletion) -> Void

    init(
        stage: @escaping () -> SweatStage,
        location: any LocationProviding = SystemLocationProvider(),
        automaticallyUsesCurrentLocation: Bool = true,
        moveRuntime: MoveBackgroundRuntime = .shared,
        onMoveCompleted: @escaping (MoveCompletion) -> Void,
        now: Date = Date()
    ) {
        self.moveRuntime = moveRuntime
        self.onMoveCompleted = onMoveCompleted
        _store = State(initialValue: RouteStore(
            location: location,
            automaticallyUsesCurrentLocation: automaticallyUsesCurrentLocation,
            stage: stage
        ))
        moveRuntime.resumeIfNeeded(now: now)
        if let restoredStore = moveRuntime.activeStore {
            _path = State(initialValue: [.move(MoveDestination(store: restoredStore))])
        }
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
                        let moveStore = moveRuntime.begin(route: route)
                        path.append(.move(MoveDestination(store: moveStore)))
                    }
                case .move(let destination):
                    MoveView(store: destination.store) { completion in
                        path = []
                        moveRuntime.releaseFinishedMove()
                        onMoveCompleted(completion)
                    }
                }
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
    }
}
