import Testing
import RouteData
import SweatDomain

@Suite("노출 분석 공급자")
struct ExposureAnalyzerTests {
    @Test("기본 분석기는 데이터가 없음을 nil로 표현한다")
    func noCoverage() async {
        let route = makeRoute()
        let result = await NoCoverageExposureAnalyzer().analyze(route)
        #expect(result == nil)
    }

    @Test("고정 분석기는 남은 구간을 unknown으로 보존한다")
    func fixtureKeepsUnknown() async {
        let analyzer = FixtureExposureAnalyzer(coveredRatio: 0.3, outdoorRatio: 0.5)!
        let result = await analyzer.analyze(makeRoute())
        #expect(result?.coveredRatio == 0.3)
        #expect(result?.outdoorRatio == 0.5)
        #expect(abs((result?.unknownRatio ?? 0) - 0.2) < 0.000_001)
    }

    private func makeRoute() -> WalkingRoute {
        let from = RoutePlace(
            name: "Origin",
            coordinate: Coordinate(latitude: 37.5, longitude: 127.0)
        )!
        let to = RoutePlace(
            name: "Destination",
            coordinate: Coordinate(latitude: 37.51, longitude: 127.01)
        )!
        return WalkingRoute(
            origin: from,
            destination: to,
            distanceMeters: 1_200,
            expectedTravelTime: 1_000,
            path: [from.coordinate, to.coordinate]
        )!
    }
}
