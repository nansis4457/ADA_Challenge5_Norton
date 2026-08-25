import Foundation
import SweatDomain
import SweatPersistence

/// 앱 수명주기와 이동 화면이 같은 활성 추적 인스턴스를 공유한다.
///
/// 백그라운드 위치 이벤트로 앱이 다시 실행되면 App Delegate가 먼저 복원을 요청하고,
/// 이후 SwiftUI 화면은 새 추적기를 만들지 않고 이 인스턴스를 이어받는다.
@MainActor
public final class MoveBackgroundRuntime {
    public static let shared = MoveBackgroundRuntime()

    private let persistence: any ActiveMovePersisting
    private(set) var activeStore: MoveStore?

    init(persistence: any ActiveMovePersisting = ActiveMoveStore()) {
        self.persistence = persistence
    }

    public var hasActiveMove: Bool {
        activeStore != nil
    }

    public func resumeIfNeeded(now: Date = Date()) {
        guard activeStore == nil,
              let snapshot = persistence.load(now: now)
        else { return }

        let store = MoveStore(snapshot: snapshot, persistence: persistence)
        activeStore = store
        store.start()
    }

    func begin(route: WalkingRoute, startedAt: Date = Date()) -> MoveStore {
        if let activeStore { return activeStore }

        let store = MoveStore(
            route: route,
            startedAt: startedAt,
            persistence: persistence
        )
        activeStore = store
        return store
    }

    func releaseFinishedMove() {
        activeStore = nil
    }
}
