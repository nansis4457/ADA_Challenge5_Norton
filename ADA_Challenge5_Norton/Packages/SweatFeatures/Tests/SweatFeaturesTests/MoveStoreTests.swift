import Foundation
import MoveActivitySupport
import MoveData
import SweatDomain
import SweatPersistence
import Testing
@testable import SweatFeatures

@Suite("이동 상태")
struct MoveStoreTests {
    private let startedAt = Date(timeIntervalSinceReferenceDate: 1_000)

    @Test("위치 이벤트로 진행률을 갱신하고 Live Activity에 전달한다")
    func tracksProgress() async throws {
        let route = makeRoute()
        let activity = FakeActivityClient()
        let tracker = FixtureMovementTracker(events: [
            .location(
                Coordinate(latitude: 37.505, longitude: 127.005),
                observedAt: startedAt.addingTimeInterval(300),
                horizontalAccuracy: 5
            ),
        ])
        let store = MoveStore(
            route: route,
            startedAt: startedAt,
            tracker: tracker,
            notifications: FakeNotificationScheduler(),
            activity: activity,
            persistence: FakeActiveMovePersistence()
        )

        store.start()
        for _ in 0 ..< 30 where store.progress.fractionCompleted == 0 { await Task.yield() }

        #expect(abs(store.progress.fractionCompleted - 0.5) < 0.02)
        #expect(activity.startCalls == 1)
        #expect(activity.updates.count == 1)
    }

    @Test("분석 데이터가 없으면 추천 상태를 만들지 않는다")
    func noAnalysisDoesNotFabricateRecommendations() {
        let store = MoveStore(
            route: makeRoute(),
            startedAt: startedAt,
            tracker: FixtureMovementTracker(events: []),
            notifications: FakeNotificationScheduler(),
            activity: FakeActivityClient(),
            persistence: FakeActiveMovePersistence()
        )

        #expect(!store.recommendations.hasAnyAnalysis)
        #expect(store.recommendations.shelter == nil)
        #expect(store.recommendations.shadeDetour == nil)
    }

    @Test("정확도가 낮은 위치는 진행률을 늘리지 않고 stale로 남긴다")
    func inaccurateLocationBecomesStale() async {
        let tracker = FixtureMovementTracker(events: [
            .location(
                Coordinate(latitude: 37.505, longitude: 127.005),
                observedAt: startedAt.addingTimeInterval(300),
                horizontalAccuracy: 200
            ),
        ])
        let store = MoveStore(
            route: makeRoute(),
            startedAt: startedAt,
            tracker: tracker,
            notifications: FakeNotificationScheduler(),
            activity: FakeActivityClient(),
            persistence: FakeActiveMovePersistence()
        )

        store.start()
        for _ in 0 ..< 100 where store.trackingState != .stale(lastObservedAt: startedAt) {
            await Task.yield()
        }

        #expect(store.progress.fractionCompleted == 0)
        #expect(store.trackingState == .stale(lastObservedAt: startedAt))
    }

    @Test("물 알림은 예약 후 종료할 때 취소한다")
    func reminderAndFinishCleanup() async throws {
        let notifications = FakeNotificationScheduler()
        let tracker = FixtureMovementTracker(events: [])
        let activity = FakeActivityClient()
        let persistence = FakeActiveMovePersistence()
        let store = MoveStore(
            route: makeRoute(),
            startedAt: startedAt,
            tracker: tracker,
            notifications: notifications,
            activity: activity,
            persistence: persistence
        )

        store.toggleWaterReminder()
        for _ in 0 ..< 30 where store.reminderState == .scheduling { await Task.yield() }
        let completion = try #require(await store.finish(at: startedAt.addingTimeInterval(600)))

        #expect(store.reminderState == .scheduled)
        #expect(notifications.scheduleCalls == 1)
        #expect(notifications.cancelled == [store.session.id])
        #expect(tracker.didStop)
        #expect(activity.endCalls == 1)
        #expect(persistence.clearCalls == 1)
        #expect(completion.elapsedTime == 600)
    }

    @Test("위치 권한 거부는 별도 상태로 남는다")
    func authorizationDenied() async {
        let store = MoveStore(
            route: makeRoute(),
            startedAt: startedAt,
            tracker: FixtureMovementTracker(events: [.authorizationDenied]),
            notifications: FakeNotificationScheduler(),
            activity: FakeActivityClient(),
            persistence: FakeActiveMovePersistence()
        )

        store.start()
        for _ in 0 ..< 100 where store.trackingState != .authorizationDenied {
            await Task.yield()
        }

        #expect(store.trackingState == .authorizationDenied)
    }

    @Test("Live Activity 시작 실패는 이동 추적을 막지 않는다")
    func liveActivityFailureIsNonBlocking() async {
        let activity = FakeActivityClient(startError: MoveActivityError.disabled)
        let store = MoveStore(
            route: makeRoute(),
            startedAt: startedAt,
            tracker: FixtureMovementTracker(events: []),
            notifications: FakeNotificationScheduler(),
            activity: activity,
            persistence: FakeActiveMovePersistence()
        )

        store.start()
        for _ in 0 ..< 100 where !store.hasLiveActivityIssue { await Task.yield() }

        #expect(store.hasLiveActivityIssue)
        #expect(store.trackingState == .tracking)
    }

    @Test("start를 다시 호출해도 같은 이동을 중복 시작하지 않는다")
    func duplicateStartIsIgnored() async {
        let activity = FakeActivityClient()
        let store = MoveStore(
            route: makeRoute(),
            startedAt: startedAt,
            tracker: FixtureMovementTracker(events: []),
            notifications: FakeNotificationScheduler(),
            activity: activity,
            persistence: FakeActiveMovePersistence()
        )

        store.start()
        store.start()
        for _ in 0 ..< 100 where activity.startCalls == 0 { await Task.yield() }

        #expect(activity.startCalls == 1)
    }

    @Test("도착 시 남은 예상 시간은 0분이다")
    func completedRouteShowsZeroMinutes() throws {
        let route = makeRoute()
        let session = try #require(MoveSession(route: route, startedAt: startedAt))
        let progress = try #require(RouteProgressCalculator().progress(
            session: session,
            location: route.path[1],
            observedAt: startedAt.addingTimeInterval(600)
        ))

        #expect(MoveCopy.remainingTime(progress) == "예상 0분 남음")
    }

    @Test("저장된 이동은 마지막 진행값에서 이어서 시작한다")
    func restoresProgress() throws {
        let route = makeRoute()
        let session = try #require(MoveSession(route: route, startedAt: startedAt))
        let progress = try #require(MoveProgress(
            sessionID: session.id,
            routeID: route.id,
            observedAt: startedAt.addingTimeInterval(300),
            elapsedTime: 300,
            traveledDistanceMeters: 400,
            remainingDistanceMeters: 600,
            estimatedRemainingTime: 360,
            fractionCompleted: 0.4
        ))
        let snapshot = try #require(ActiveMoveSnapshot(
            session: session,
            progress: progress,
            savedAt: progress.observedAt
        ))
        let persistence = FakeActiveMovePersistence(snapshot: snapshot)

        let store = MoveStore(
            snapshot: snapshot,
            tracker: FixtureMovementTracker(events: []),
            notifications: FakeNotificationScheduler(),
            activity: FakeActivityClient(),
            persistence: persistence
        )
        store.start()

        #expect(store.session.id == session.id)
        #expect(store.progress == progress)
        #expect(persistence.saveCalls == 0, "위치 관측 없이 복원 유효 시간을 늘리지 않는다")
    }

    private func makeRoute() -> WalkingRoute {
        let origin = RoutePlace(
            name: "성수역 3번 출구",
            coordinate: Coordinate(latitude: 37.5, longitude: 127)
        )!
        let destination = RoutePlace(
            name: "한양대 정문",
            coordinate: Coordinate(latitude: 37.51, longitude: 127.01)
        )!
        return WalkingRoute(
            origin: origin,
            destination: destination,
            distanceMeters: 1_000,
            expectedTravelTime: 600,
            path: [origin.coordinate, destination.coordinate]
        )!
    }
}

@MainActor
private final class FakeNotificationScheduler: MovementNotificationScheduling {
    private(set) var scheduleCalls = 0
    private(set) var cancelled: [UUID] = []

    func scheduleWaterReminder(for sessionID: UUID) async throws -> WaterReminderScheduleResult {
        scheduleCalls += 1
        return .scheduled
    }

    func cancelWaterReminder(for sessionID: UUID) {
        cancelled.append(sessionID)
    }
}

@MainActor
private final class FakeActivityClient: MoveActivityUpdating {
    var isAvailable = true
    let startError: MoveActivityError?
    private(set) var startCalls = 0
    private(set) var updates: [MoveProgress] = []
    private(set) var endCalls = 0

    init(startError: MoveActivityError? = nil) {
        self.startError = startError
    }

    func start(session: MoveSession, progress: MoveProgress) async throws {
        startCalls += 1
        if let startError { throw startError }
    }

    func update(progress: MoveProgress) async -> Bool {
        updates.append(progress)
        return true
    }

    func end(finalProgress: MoveProgress?) async {
        endCalls += 1
    }
}

@MainActor
private final class FakeActiveMovePersistence: ActiveMovePersisting {
    private(set) var snapshot: ActiveMoveSnapshot?
    private(set) var saveCalls = 0
    private(set) var clearCalls = 0

    init(snapshot: ActiveMoveSnapshot? = nil) {
        self.snapshot = snapshot
    }

    func load(now: Date) -> ActiveMoveSnapshot? {
        snapshot
    }

    func save(_ snapshot: ActiveMoveSnapshot) {
        self.snapshot = snapshot
        saveCalls += 1
    }

    func clear() {
        snapshot = nil
        clearCalls += 1
    }
}
