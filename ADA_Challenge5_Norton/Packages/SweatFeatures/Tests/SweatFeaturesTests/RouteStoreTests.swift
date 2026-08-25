import Foundation
import RouteData
import SweatDomain
import Testing
@testable import SweatFeatures

@Suite("경로 입력 상태")
struct RouteStoreTests {
    @Test("문자열만 입력해서는 경로를 계산할 수 없다")
    func requiresResolvedPlaces() {
        let store = makeStore()
        store.originQuery = "Origin"
        store.destinationQuery = "Destination"
        #expect(!store.canCalculate)
    }

    @Test("장소를 확정한 뒤 도보 경로를 계산한다")
    func calculatesWalkingRoute() async throws {
        let search = FakePlaceSearch()
        let source = FakeRouteSource(result: .success([makeRoute()]))
        let store = makeStore(search: search, source: source)

        try await selectPlace(.origin, query: "Origin", store: store)
        try await selectPlace(.destination, query: "Destination", store: store)

        #expect(store.canCalculate)
        #expect(await store.calculate())
        #expect(source.calls == 1)
        #expect(store.selectedRoute?.exposure == nil, "데이터가 없는데 0% 분석을 만들면 안 된다")
    }

    @Test("도보 경로가 없으면 자동차 폴백 없이 전용 오류가 남는다")
    func noRouteIsDistinct() async throws {
        let store = makeStore(source: FakeRouteSource(result: .failure(.noRoute)))
        try await selectPlace(.origin, query: "Origin", store: store)
        try await selectPlace(.destination, query: "Destination", store: store)

        #expect(!(await store.calculate()))
        #expect(store.issue == .routeUnavailable)
        #expect(store.routes.isEmpty)
    }

    @Test("경로 공급자 장애는 다시 시도 가능한 오류로 구분한다")
    func routeFailureIsDistinct() async throws {
        let store = makeStore(source: FakeRouteSource(result: .failure(.unavailable)))
        try await selectPlace(.origin, query: "Origin", store: store)
        try await selectPlace(.destination, query: "Destination", store: store)

        #expect(!(await store.calculate()))
        #expect(store.issue == .routeFailed)
    }

    @Test("검색 장애 뒤 같은 검색어로 다시 시도할 수 있다")
    func retriesFailedSearch() async throws {
        let search = FlakyPlaceSearch()
        let store = makeStore(search: search)
        store.originQuery = "Origin"
        store.queryDidChange(.origin)

        for _ in 0 ..< 50 where store.issue == nil { await Task.yield() }
        #expect(store.issue == .searchFailed)

        store.retrySearch()
        for _ in 0 ..< 50 where store.suggestions.isEmpty { await Task.yield() }
        #expect(search.suggestionCalls == 2)
        #expect(store.suggestions.first?.title == "Origin")
    }

    @Test("새 검색어가 들어오면 이전 검색을 취소한다")
    func cancelsPreviousSearch() {
        let search = FakePlaceSearch()
        let store = makeStore(search: search, searchDelay: .seconds(1))

        store.originQuery = "A"
        store.queryDidChange(.origin)
        store.originQuery = "Apple"
        store.queryDidChange(.origin)

        #expect(search.cancelCalls == 2)
    }

    @Test("노출 데이터가 있으면 더 적게 노출되는 후보로 전환한다")
    func selectsLessExposedAlternative() async throws {
        let fast = makeRoute(duration: 900)
        let sheltered = makeRoute(duration: 1_100)
        let analyzer = MappedExposureAnalyzer(outdoorRatios: [
            fast.id: 0.9,
            sheltered.id: 0.2,
        ])
        let store = makeStore(
            source: FakeRouteSource(result: .success([fast, sheltered])),
            analyzer: analyzer,
            stage: { .one }
        )
        try await selectPlace(.origin, query: "Origin", store: store)
        try await selectPlace(.destination, query: "Destination", store: store)

        #expect(await store.calculate())
        #expect(store.selectedRoute?.id == fast.id)
        #expect(store.hasLessExposedAlternative)

        store.selectLessExposedRoute()
        #expect(store.selectedRoute?.id == sheltered.id)
    }

    @Test("확정된 장소 이름 반영은 같은 검색을 다시 시작하지 않는다")
    func selectionDoesNotRestartSearch() async throws {
        let search = FakePlaceSearch()
        let store = makeStore(search: search)
        try await selectPlace(.origin, query: "Origin", store: store)
        let callsAfterSelection = search.suggestionCalls

        store.queryDidChange(.origin)
        await Task.yield()

        #expect(search.suggestionCalls == callsAfterSelection)
        #expect(store.origin?.name == "Origin")
    }

    @Test("경과 0분과 예상 소요 시간은 다른 방식으로 표시한다")
    func durationFormatting() {
        #expect(RouteCopy.elapsedDuration(0) == "0분")
        #expect(RouteCopy.duration(0) == "1분")
    }

    private func makeStore(
        search: any PlaceSearching = FakePlaceSearch(),
        source: FakeRouteSource? = nil,
        analyzer: any ExposureAnalyzing = NoCoverageExposureAnalyzer(),
        searchDelay: Duration = .zero,
        stage: @escaping () -> SweatStage = { .three }
    ) -> RouteStore {
        RouteStore(
            placeSearch: search,
            routeSource: source ?? FakeRouteSource(result: .success([makeRoute()])),
            exposureAnalyzer: analyzer,
            searchDelay: searchDelay,
            stage: stage
        )
    }

    private func selectPlace(
        _ field: RouteStore.Field,
        query: String,
        store: RouteStore
    ) async throws {
        switch field {
        case .origin: store.originQuery = query
        case .destination: store.destinationQuery = query
        }
        store.queryDidChange(field)

        for _ in 0 ..< 20 where store.suggestions.isEmpty {
            await Task.yield()
        }
        let suggestion = try #require(store.suggestions.first)
        await store.select(suggestion)
    }

    private func makeRoute(duration: TimeInterval = 1_000) -> WalkingRoute {
        let origin = FakePlaceSearch.origin
        let destination = FakePlaceSearch.destination
        return WalkingRoute(
            origin: origin,
            destination: destination,
            distanceMeters: 1_200,
            expectedTravelTime: duration,
            path: [origin.coordinate, destination.coordinate]
        )!
    }
}

@MainActor
private final class FakePlaceSearch: PlaceSearching {
    static let origin = RoutePlace(
        name: "Origin",
        coordinate: Coordinate(latitude: 37.5, longitude: 127.0)
    )!
    static let destination = RoutePlace(
        name: "Destination",
        coordinate: Coordinate(latitude: 37.51, longitude: 127.01)
    )!

    private(set) var suggestionCalls = 0
    private(set) var cancelCalls = 0

    func suggestions(for query: String, near coordinate: Coordinate?) async throws -> [PlaceSuggestion] {
        suggestionCalls += 1
        return [PlaceSuggestion(id: query, title: query)]
    }

    func resolve(_ suggestion: PlaceSuggestion) async throws -> RoutePlace {
        suggestion.title == Self.origin.name ? Self.origin : Self.destination
    }

    func cancel() { cancelCalls += 1 }
}

@MainActor
private final class FlakyPlaceSearch: PlaceSearching {
    private(set) var suggestionCalls = 0

    func suggestions(for query: String, near coordinate: Coordinate?) async throws -> [PlaceSuggestion] {
        suggestionCalls += 1
        if suggestionCalls == 1 { throw PlaceSearchError.unavailable }
        return [PlaceSuggestion(id: query, title: query)]
    }

    func resolve(_ suggestion: PlaceSuggestion) async throws -> RoutePlace {
        FakePlaceSearch.origin
    }

    func cancel() {}
}

@MainActor
private final class FakeRouteSource: WalkingRouteProviding {
    let result: Result<[WalkingRoute], WalkingRouteError>
    private(set) var calls = 0

    init(result: Result<[WalkingRoute], WalkingRouteError>) {
        self.result = result
    }

    func routes(
        from origin: RoutePlace,
        to destination: RoutePlace,
        departingAt departureDate: Date
    ) async throws -> [WalkingRoute] {
        calls += 1
        return try result.get()
    }
}

private struct MappedExposureAnalyzer: ExposureAnalyzing {
    let outdoorRatios: [UUID: Double]

    func analyze(_ route: WalkingRoute) async -> ExposureAnalysis? {
        guard let ratio = outdoorRatios[route.id],
              let segment = ExposureSegment(
                kind: .outdoor,
                expectedDuration: route.expectedTravelTime * ratio
              ) else { return nil }
        return ExposureAnalysis(routeDuration: route.expectedTravelTime, segments: [segment])
    }
}
