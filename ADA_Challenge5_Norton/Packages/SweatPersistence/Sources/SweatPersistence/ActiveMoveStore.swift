import Foundation
import SweatDomain

/// 앱 재실행 뒤 복원하는 데 필요한 최소 이동 상태.
///
/// 원시 위치 이력은 저장하지 않고 선택 경로와 마지막 집계 진행값만 보관한다.
public struct ActiveMoveSnapshot: Sendable, Codable, Equatable {
    public let session: MoveSession
    public let progress: MoveProgress
    public let savedAt: Date

    public init?(
        session: MoveSession,
        progress: MoveProgress,
        savedAt: Date
    ) {
        guard session.id == progress.sessionID,
              session.route.id == progress.routeID,
              savedAt.timeIntervalSinceReferenceDate.isFinite
        else { return nil }

        self.session = session
        self.progress = progress
        self.savedAt = savedAt
    }
}

@MainActor
public protocol ActiveMovePersisting: Sendable {
    func load(now: Date) -> ActiveMoveSnapshot?
    func save(_ snapshot: ActiveMoveSnapshot)
    func clear()
}

/// 한 번에 하나인 활성 이동을 `UserDefaults`에 보관한다.
///
/// 마지막 갱신 뒤 기본 12시간이 지나면 오래된 세션으로 보고 삭제한다. 손상되거나
/// 이미 완료된 값도 같은 방식으로 제거해 앱 재실행 때 되살아나지 않게 한다.
@MainActor
public struct ActiveMoveStore: ActiveMovePersisting {
    private let defaults: UserDefaults
    private let maximumAge: TimeInterval
    private static let key = "sweat.activeMove"
    private static let clockSkewTolerance: TimeInterval = 5 * 60

    public init(
        defaults: UserDefaults = .standard,
        maximumAge: TimeInterval = 12 * 60 * 60
    ) {
        self.defaults = defaults
        self.maximumAge = max(maximumAge, 0)
    }

    public func load(now: Date) -> ActiveMoveSnapshot? {
        guard let data = defaults.data(forKey: Self.key) else { return nil }

        do {
            let snapshot = try JSONDecoder().decode(ActiveMoveSnapshot.self, from: data)
            let age = now.timeIntervalSince(snapshot.savedAt)
            guard snapshot.session.id == snapshot.progress.sessionID,
                  snapshot.session.route.id == snapshot.progress.routeID,
                  snapshot.progress.fractionCompleted < 1,
                  age >= -Self.clockSkewTolerance,
                  age <= maximumAge
            else {
                clear()
                return nil
            }
            return snapshot
        } catch {
            clear()
            return nil
        }
    }

    public func save(_ snapshot: ActiveMoveSnapshot) {
        guard snapshot.progress.fractionCompleted < 1,
              let data = try? JSONEncoder().encode(snapshot)
        else {
            clear()
            return
        }
        defaults.set(data, forKey: Self.key)
    }

    public func clear() {
        defaults.removeObject(forKey: Self.key)
    }
}
