import Foundation
import SweatDomain
import Testing
@testable import SweatPersistence

@MainActor
@Suite("ActiveMoveStore")
struct ActiveMoveStoreTests {
    private let now = Date(timeIntervalSinceReferenceDate: 10_000)

    @Test("활성 이동의 최소 상태를 저장하고 복원한다")
    func roundTrip() throws {
        let (store, _) = makeStore()
        let snapshot = try #require(makeSnapshot(savedAt: now))

        store.save(snapshot)

        #expect(store.load(now: now.addingTimeInterval(60)) == snapshot)
    }

    @Test("12시간이 지난 이동은 복원하지 않고 삭제한다")
    func expiredSnapshotIsRemoved() throws {
        let (store, defaults) = makeStore()
        store.save(try #require(makeSnapshot(savedAt: now)))

        #expect(store.load(now: now.addingTimeInterval(12 * 60 * 60 + 1)) == nil)
        #expect(defaults.data(forKey: "sweat.activeMove") == nil)
    }

    @Test("완료된 이동은 저장하지 않는다")
    func completedSnapshotIsNotStored() throws {
        let (store, defaults) = makeStore()
        store.save(try #require(makeSnapshot(savedAt: now, fractionCompleted: 1)))

        #expect(defaults.data(forKey: "sweat.activeMove") == nil)
    }

    @Test("손상된 값은 복원하지 않고 삭제한다")
    func corruptedSnapshotIsRemoved() {
        let (store, defaults) = makeStore()
        defaults.set(Data("not-json".utf8), forKey: "sweat.activeMove")

        #expect(store.load(now: now) == nil)
        #expect(defaults.data(forKey: "sweat.activeMove") == nil)
    }

    private func makeStore() -> (ActiveMoveStore, UserDefaults) {
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        return (ActiveMoveStore(defaults: defaults), defaults)
    }

    private func makeSnapshot(
        savedAt: Date,
        fractionCompleted: Double = 0.4
    ) -> ActiveMoveSnapshot? {
        let origin = RoutePlace(
            name: "성수역",
            coordinate: Coordinate(latitude: 37.5, longitude: 127)
        )!
        let destination = RoutePlace(
            name: "한양대",
            coordinate: Coordinate(latitude: 37.51, longitude: 127.01)
        )!
        let route = WalkingRoute(
            origin: origin,
            destination: destination,
            distanceMeters: 1_000,
            expectedTravelTime: 600,
            path: [origin.coordinate, destination.coordinate]
        )!
        let session = MoveSession(
            route: route,
            startedAt: savedAt.addingTimeInterval(-300)
        )!
        let progress = MoveProgress(
            sessionID: session.id,
            routeID: route.id,
            observedAt: savedAt,
            elapsedTime: 300,
            traveledDistanceMeters: 1_000 * fractionCompleted,
            remainingDistanceMeters: 1_000 * (1 - fractionCompleted),
            estimatedRemainingTime: 600 * (1 - fractionCompleted),
            fractionCompleted: fractionCompleted
        )!
        return ActiveMoveSnapshot(session: session, progress: progress, savedAt: savedAt)
    }
}
