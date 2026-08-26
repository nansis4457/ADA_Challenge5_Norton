#if DEBUG
import Foundation
import MoveActivitySupport
import MoveData
import SwiftUI
import SweatDomain
import SweatPersistence

#Preview("09 · 분석 데이터 있음") {
    MovePreviewContainer(recommendations: MovePreviewFactory.fullRecommendations)
}

#Preview("09 · 분석 데이터 없음") {
    MovePreviewContainer(recommendations: MoveRecommendations())
}

#Preview("09 · 긴 장소명 · 부분 가용") {
    MovePreviewContainer(
        route: MovePreviewFactory.longNameRoute,
        recommendations: MoveRecommendations(
            aheadExposure: MovePreviewFactory.aheadExposure,
            shelter: nil,
            shadeDetour: MovePreviewFactory.shadeDetour
        )
    )
}

@MainActor
private struct MovePreviewContainer: View {
    @State private var store: MoveStore

    init(
        route: WalkingRoute = MovePreviewFactory.standardRoute,
        recommendations: MoveRecommendations
    ) {
        _store = State(initialValue: MovePreviewFactory.store(
            route: route,
            recommendations: recommendations
        ))
    }

    var body: some View {
        NavigationStack {
            MoveView(store: store) { _ in }
        }
        .frame(width: 402, height: 874)
    }
}

@MainActor
private enum MovePreviewFactory {
    static let aheadExposure = AheadExposureEstimate(expectedDuration: 4 * 60)!

    static let standardRoute = makeRoute(
        originName: "성수역 3번 출구",
        destinationName: "한양대 정문"
    )

    static let longNameRoute = makeRoute(
        originName: "서울숲역 수인분당선 3번 출구 앞 보행자 광장",
        destinationName: "한양대학교 서울캠퍼스 신본관 정문 안내소"
    )

    static let shadeDetour = ShadeDetourRecommendation(
        route: makeRoute(
            originName: "성수역 3번 출구",
            destinationName: "한양대 정문",
            distanceMeters: 1_380,
            expectedTravelTime: 13 * 60
        ),
        additionalTravelTime: 2 * 60,
        expectedOutdoorTimeReduction: 4 * 60
    )!

    static let fullRecommendations = MoveRecommendations(
        aheadExposure: aheadExposure,
        shelter: HeatShelterRecommendation(
            id: "shelter-preview",
            name: "성수동 무더위쉼터",
            coordinate: Coordinate(latitude: 37.545, longitude: 127.048),
            distanceMeters: 80,
            expectedWalkingTime: 60,
            sourceName: "미리보기 고정 데이터"
        ),
        shadeDetour: shadeDetour
    )

    static func store(
        route: WalkingRoute,
        recommendations: MoveRecommendations
    ) -> MoveStore {
        let startedAt = Date(timeIntervalSinceReferenceDate: 1_000)
        guard let session = MoveSession(route: route, startedAt: startedAt),
              let progress = MoveProgress(
                  sessionID: session.id,
                  routeID: route.id,
                  observedAt: startedAt.addingTimeInterval(9 * 60),
                  elapsedTime: 9 * 60,
                  traveledDistanceMeters: route.distanceMeters - 620,
                  remainingDistanceMeters: 620,
                  estimatedRemainingTime: 6 * 60,
                  fractionCompleted: 0.52
              ),
              let snapshot = ActiveMoveSnapshot(
                  session: session,
                  progress: progress,
                  savedAt: progress.observedAt
              )
        else {
            preconditionFailure("MoveView 미리보기 값을 만들 수 없습니다.")
        }

        return MoveStore(
            snapshot: snapshot,
            recommendations: recommendations,
            tracker: FixtureMovementTracker(events: []),
            notifications: PreviewMovementNotificationScheduler(),
            activity: PreviewMoveActivityClient(),
            persistence: PreviewActiveMoveStore()
        )
    }

    private static func makeRoute(
        originName: String,
        destinationName: String,
        distanceMeters: Double = 1_300,
        expectedTravelTime: TimeInterval = 15 * 60
    ) -> WalkingRoute {
        let originCoordinate = Coordinate(latitude: 37.544, longitude: 127.044)
        let destinationCoordinate = Coordinate(latitude: 37.557, longitude: 127.045)
        guard let origin = RoutePlace(name: originName, coordinate: originCoordinate),
              let destination = RoutePlace(name: destinationName, coordinate: destinationCoordinate),
              let route = WalkingRoute(
                  origin: origin,
                  destination: destination,
                  distanceMeters: distanceMeters,
                  expectedTravelTime: expectedTravelTime,
                  path: [originCoordinate, destinationCoordinate]
              )
        else {
            preconditionFailure("MoveView 미리보기 경로를 만들 수 없습니다.")
        }
        return route
    }
}

@MainActor
private final class PreviewMovementNotificationScheduler: MovementNotificationScheduling {
    func scheduleWaterReminder(for sessionID: UUID) async throws -> WaterReminderScheduleResult {
        .scheduled
    }

    func cancelWaterReminder(for sessionID: UUID) {}
}

@MainActor
private final class PreviewMoveActivityClient: MoveActivityUpdating {
    let isAvailable = true

    func start(session: MoveSession, progress: MoveProgress) async throws {}
    func update(progress: MoveProgress) async -> Bool { true }
    func end(finalProgress: MoveProgress?) async {}
}

@MainActor
private struct PreviewActiveMoveStore: ActiveMovePersisting {
    func load(now: Date) -> ActiveMoveSnapshot? { nil }
    func save(_ snapshot: ActiveMoveSnapshot) {}
    func clear() {}
}
#endif
