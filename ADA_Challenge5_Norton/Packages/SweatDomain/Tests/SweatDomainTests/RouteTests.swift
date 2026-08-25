import Foundation
import Testing
@testable import SweatDomain

@Suite("도보 경로와 노출 분석")
struct RouteTests {
    private let origin = RoutePlace(
        name: "Origin",
        coordinate: Coordinate(latitude: 37.5445, longitude: 127.0560)
    )!
    private let destination = RoutePlace(
        name: "Destination",
        coordinate: Coordinate(latitude: 37.5572, longitude: 127.0453)
    )!

    @Test("장소는 이름과 유효한 좌표가 있어야 한다")
    func placeValidation() {
        #expect(RoutePlace(name: "  ", coordinate: origin.coordinate) == nil)
        #expect(RoutePlace(name: "X", coordinate: Coordinate(latitude: 91, longitude: 0)) == nil)
    }

    @Test("경로는 양수 거리·시간과 둘 이상의 좌표가 있어야 한다")
    func routeValidation() {
        #expect(makeRoute(duration: 0) == nil)
        #expect(makeRoute(duration: 600, path: [origin.coordinate]) == nil)
        #expect(makeRoute(duration: 600) != nil)
    }

    @Test("분석하지 못한 나머지를 실외가 아니라 unknown으로 채운다")
    func partialCoverage() {
        let analysis = ExposureAnalysis(routeDuration: 1_000, segments: [
            ExposureSegment(kind: .covered, expectedDuration: 200)!,
            ExposureSegment(kind: .outdoor, expectedDuration: 300)!,
        ])!

        #expect(analysis.coveredRatio == 0.2)
        #expect(analysis.outdoorRatio == 0.3)
        #expect(analysis.unknownRatio == 0.5)
        #expect(analysis.coverageRatio == 0.5)
        #expect(analysis.segments.last?.kind == .unknown)
    }

    @Test("분석 구간이 전혀 없으면 0% 결과를 만들지 않는다")
    func noFalseZeroAnalysis() {
        let unknown = ExposureSegment(kind: .unknown, expectedDuration: 600)!
        #expect(ExposureAnalysis(routeDuration: 600, segments: []) == nil)
        #expect(ExposureAnalysis(routeDuration: 600, segments: [unknown]) == nil)
    }

    @Test("전체 시간보다 긴 분석은 거부한다")
    func rejectsOverflow() {
        let segment = ExposureSegment(kind: .outdoor, expectedDuration: 601)!
        #expect(ExposureAnalysis(routeDuration: 600, segments: [segment]) == nil)
    }

    @Test("단계가 높아질수록 실외 노출 가중치가 낮아지지 않는다")
    func penaltyIsMonotonic() {
        let penalties = SweatStage.allCases.map(RouteRankingPolicy.outdoorPenalty)
        #expect(penalties == penalties.sorted())
    }

    @Test("더운 단계에서는 조금 느려도 실외 노출이 짧은 길이 먼저다")
    func hotterStageCanPreferLessExposure() {
        let fastOutdoor = makeRoute(duration: 1_000, outdoor: 900)!
        let coolDetour = makeRoute(duration: 1_100, outdoor: 300)!

        #expect(RouteRankingPolicy.ranked([coolDetour, fastOutdoor], stage: .one).first?.id == fastOutdoor.id)
        #expect(RouteRankingPolicy.ranked([fastOutdoor, coolDetour], stage: .six).first?.id == coolDetour.id)
    }

    private func makeRoute(
        duration: TimeInterval,
        outdoor: TimeInterval? = nil,
        path: [Coordinate]? = nil
    ) -> WalkingRoute? {
        let analysis = outdoor.flatMap { value in
            ExposureSegment(kind: .outdoor, expectedDuration: value).flatMap {
                ExposureAnalysis(routeDuration: duration, segments: [$0])
            }
        }
        return WalkingRoute(
            origin: origin,
            destination: destination,
            distanceMeters: 1_200,
            expectedTravelTime: duration,
            path: path ?? [origin.coordinate, destination.coordinate],
            exposure: analysis
        )
    }
}
