import SwiftUI
import SweatDomain

struct RouteFlowView: View {
    private enum Destination: Hashable {
        case input
        case result
        case move
    }

    @State private var store: RouteStore
    @State private var path: [Destination] = []
    @State private var moveStore: MoveStore?
    @State private var showsFinished = false
    private let moveRuntime: MoveBackgroundRuntime

    init(
        stage: @escaping () -> SweatStage,
        moveRuntime: MoveBackgroundRuntime = .shared,
        now: Date = Date()
    ) {
        self.moveRuntime = moveRuntime
        _store = State(initialValue: RouteStore(stage: stage))
        moveRuntime.resumeIfNeeded(now: now)
        if let restoredStore = moveRuntime.activeStore {
            _path = State(initialValue: [.move])
            _moveStore = State(initialValue: restoredStore)
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
                        moveStore = moveRuntime.begin(route: route)
                        path.append(.move)
                    }
                case .move:
                    if let moveStore {
                        MoveView(store: moveStore) { _ in
                            showsFinished = true
                            path = []
                            self.moveStore = nil
                            moveRuntime.releaseFinishedMove()
                        }
                    }
                }
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
        .alert(MoveCopy.finishedTitle, isPresented: $showsFinished) {
            Button(MoveCopy.confirm, role: .cancel) {}
        } message: {
            Text(MoveCopy.finishedBody)
        }
    }
}
