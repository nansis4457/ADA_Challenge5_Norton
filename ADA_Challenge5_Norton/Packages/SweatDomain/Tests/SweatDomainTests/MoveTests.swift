import Foundation
import Testing
@testable import SweatDomain

@Suite("이동 진행")
struct MoveTests {
    private let startedAt = Date(timeIntervalSinceReferenceDate: 1_000)

    @Test("경로 시작·중간·도착을 0~100%에 투영한다")
    func projectsProgress() throws {
        let session = try #require(makeSession())
        let calculator = RouteProgressCalculator(maximumSnapDistanceMeters: 100)

        let start = try #require(calculator.progress(
            session: session,
            location: session.route.path[0],
            observedAt: startedAt
        ))
        let middle = try #require(calculator.progress(
            session: session,
            location: Coordinate(latitude: 37.505, longitude: 127.005),
            observedAt: startedAt.addingTimeInterval(300),
            previous: start
        ))
        let end = try #require(calculator.progress(
            session: session,
            location: session.route.path[2],
            observedAt: startedAt.addingTimeInterval(600),
            previous: middle
        ))

        #expect(start.fractionCompleted == 0)
        #expect(abs(middle.fractionCompleted - 0.5) < 0.02)
        #expect(end.fractionCompleted == 1)
        #expect(end.remainingDistanceMeters == 0)
        #expect(end.estimatedRemainingTime == 0)
    }

    @Test("GPS 위치가 뒤로 흔들려도 확정 진행률은 감소하지 않는다")
    func progressIsMonotonic() throws {
        let session = try #require(makeSession())
        let calculator = RouteProgressCalculator(maximumSnapDistanceMeters: 100)
        let forward = try #require(calculator.progress(
            session: session,
            location: Coordinate(latitude: 37.5075, longitude: 127.0075),
            observedAt: startedAt.addingTimeInterval(400)
        ))
        let jitteredBackward = try #require(calculator.progress(
            session: session,
            location: Coordinate(latitude: 37.503, longitude: 127.003),
            observedAt: startedAt.addingTimeInterval(410),
            previous: forward
        ))

        #expect(jitteredBackward.fractionCompleted == forward.fractionCompleted)
        #expect(jitteredBackward.remainingDistanceMeters == forward.remainingDistanceMeters)
    }

    @Test("경로에서 멀어진 위치는 진행값을 만들지 않는다")
    func rejectsOffRouteLocation() throws {
        let session = try #require(makeSession())
        let calculator = RouteProgressCalculator(maximumSnapDistanceMeters: 30)
        let farAway = Coordinate(latitude: 37.52, longitude: 127.0)

        #expect(calculator.progress(
            session: session,
            location: farAway,
            observedAt: startedAt.addingTimeInterval(60)
        ) == nil)
    }

    @Test("관측 시각이 시작보다 빠르면 진행값을 만들지 않는다")
    func rejectsObservationBeforeStart() throws {
        let session = try #require(makeSession())
        #expect(RouteProgressCalculator().progress(
            session: session,
            location: session.route.path[0],
            observedAt: startedAt.addingTimeInterval(-1)
        ) == nil)
    }

    @Test("완료 값은 종료 집계만 보관하고 잘못된 실외 시간은 거부한다")
    func completionValidation() throws {
        let session = try #require(makeSession())
        let endedAt = startedAt.addingTimeInterval(600)

        #expect(MoveCompletion(
            sessionID: session.id,
            routeID: session.route.id,
            startedAt: startedAt,
            endedAt: endedAt,
            traveledDistanceMeters: 900,
            fractionCompleted: 0.9,
            observedOutdoorTime: 300
        ) != nil)
        #expect(MoveCompletion(
            sessionID: session.id,
            routeID: session.route.id,
            startedAt: startedAt,
            endedAt: endedAt,
            traveledDistanceMeters: 900,
            fractionCompleted: 0.9,
            observedOutdoorTime: 601
        ) == nil)
    }

    @Test("추천 근거는 항목별로 독립해 존재한다")
    func recommendationAvailability() throws {
        let estimate = try #require(AheadExposureEstimate(expectedDuration: 240))
        let recommendations = MoveRecommendations(aheadExposure: estimate)

        #expect(recommendations.hasAnyAnalysis)
        #expect(recommendations.aheadExposure != nil)
        #expect(recommendations.shelter == nil)
        #expect(recommendations.shadeDetour == nil)
        #expect(!MoveRecommendations().hasAnyAnalysis)
    }

    private func makeSession() -> MoveSession? {
        let origin = RoutePlace(
            name: "Origin",
            coordinate: Coordinate(latitude: 37.5, longitude: 127.0)
        )!
        let destination = RoutePlace(
            name: "Destination",
            coordinate: Coordinate(latitude: 37.51, longitude: 127.01)
        )!
        let route = WalkingRoute(
            origin: origin,
            destination: destination,
            distanceMeters: 1_000,
            expectedTravelTime: 600,
            path: [
                origin.coordinate,
                Coordinate(latitude: 37.505, longitude: 127.005),
                destination.coordinate,
            ]
        )!
        return MoveSession(route: route, startedAt: startedAt)
    }
}
