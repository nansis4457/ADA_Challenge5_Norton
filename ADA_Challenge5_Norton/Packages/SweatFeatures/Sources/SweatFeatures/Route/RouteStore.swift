import Foundation
import RouteData
import SweatDomain

@Observable
final class RouteStore {
    enum Field: Sendable, Equatable {
        case origin
        case destination
    }

    enum Activity: Sendable, Equatable {
        case idle
        case searching
        case resolving
        case calculating
    }

    enum Issue: Sendable, Equatable {
        case searchFailed
        case routeFailed
        case routeUnavailable
    }

    var originQuery = ""
    var destinationQuery = ""
    let minimumDepartureDate: Date
    var departureDate: Date

    private(set) var origin: RoutePlace?
    private(set) var destination: RoutePlace?
    private(set) var suggestions: [PlaceSuggestion] = []
    private(set) var activeField: Field?
    private(set) var activity: Activity = .idle
    private(set) var issue: Issue?
    private(set) var completedSearch = false
    private(set) var routes: [WalkingRoute] = []
    private(set) var selectedRouteID: UUID?

    private let placeSearch: any PlaceSearching
    private let routeSource: any WalkingRouteProviding
    private let exposureAnalyzer: any ExposureAnalyzing
    private let stage: () -> SweatStage
    private let searchDelay: Duration
    private var searchTask: Task<Void, Never>?

    init(
        placeSearch: any PlaceSearching = MapKitPlaceSearch(),
        routeSource: any WalkingRouteProviding = MapKitWalkingRouteSource(),
        exposureAnalyzer: any ExposureAnalyzing = NoCoverageExposureAnalyzer(),
        searchDelay: Duration = .milliseconds(250),
        stage: @escaping () -> SweatStage
    ) {
        let now = Date()
        self.minimumDepartureDate = now
        self.departureDate = now
        self.placeSearch = placeSearch
        self.routeSource = routeSource
        self.exposureAnalyzer = exposureAnalyzer
        self.searchDelay = searchDelay
        self.stage = stage
    }

    var canCalculate: Bool {
        origin != nil && destination != nil && activity != .calculating
    }

    var selectedRoute: WalkingRoute? {
        guard let selectedRouteID else { return routes.first }
        return routes.first { $0.id == selectedRouteID }
    }

    var hasLessExposedAlternative: Bool {
        guard let selected = selectedRoute,
              let selectedOutdoor = selected.exposure?.outdoorDuration else { return false }
        return routes.contains { route in
            guard let outdoor = route.exposure?.outdoorDuration else { return false }
            return outdoor < selectedOutdoor
        }
    }

    func queryDidChange(_ field: Field) {
        activeField = field
        issue = nil
        completedSearch = false

        let query = query(for: field).trimmingCharacters(in: .whitespacesAndNewlines)
        if selectedPlace(for: field)?.name != query {
            setSelectedPlace(nil, for: field)
        } else if !query.isEmpty {
            suggestions = []
            activity = .idle
            return
        }

        searchTask?.cancel()
        placeSearch.cancel()

        guard !query.isEmpty else {
            suggestions = []
            activity = .idle
            return
        }

        activity = .searching
        searchTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(for: searchDelay)
                guard !Task.isCancelled else { return }
                let results = try await placeSearch.suggestions(for: query, near: origin?.coordinate)
                guard !Task.isCancelled, activeField == field else { return }
                suggestions = results
                completedSearch = true
                activity = .idle
            } catch is CancellationError {
                // 새 검색어가 들어와 취소된 정상 흐름이다.
            } catch {
                guard !Task.isCancelled else { return }
                suggestions = []
                completedSearch = true
                issue = .searchFailed
                activity = .idle
            }
        }
    }

    func select(_ suggestion: PlaceSuggestion) async {
        guard let field = activeField else { return }
        searchTask?.cancel()
        activity = .resolving
        issue = nil

        do {
            let place = try await placeSearch.resolve(suggestion)
            setSelectedPlace(place, for: field)
            setQuery(place.name, for: field)
            suggestions = []
            completedSearch = false
            activity = .idle
        } catch {
            issue = .searchFailed
            activity = .idle
        }
    }

    @discardableResult
    func calculate() async -> Bool {
        guard let origin, let destination, canCalculate else { return false }
        activity = .calculating
        issue = nil

        do {
            let candidates = try await routeSource.routes(
                from: origin,
                to: destination,
                departingAt: max(departureDate, minimumDepartureDate)
            )
            var analyzed: [WalkingRoute] = []
            for var route in candidates {
                route.exposure = await exposureAnalyzer.analyze(route)
                analyzed.append(route)
            }
            routes = RouteRankingPolicy.ranked(analyzed, stage: stage())
            selectedRouteID = routes.first?.id
            activity = .idle
            return !routes.isEmpty
        } catch WalkingRouteError.noRoute {
            routes = []
            selectedRouteID = nil
            issue = .routeUnavailable
            activity = .idle
            return false
        } catch {
            routes = []
            selectedRouteID = nil
            issue = .routeFailed
            activity = .idle
            return false
        }
    }

    func selectLessExposedRoute() {
        let candidates = routes.compactMap { route -> (WalkingRoute, TimeInterval)? in
            guard let outdoor = route.exposure?.outdoorDuration else { return nil }
            return (route, outdoor)
        }
        selectedRouteID = candidates.min { $0.1 < $1.1 }?.0.id ?? selectedRouteID
    }

    func retrySearch() {
        guard let activeField else { return }
        queryDidChange(activeField)
    }

    private func query(for field: Field) -> String {
        switch field {
        case .origin: originQuery
        case .destination: destinationQuery
        }
    }

    private func setQuery(_ query: String, for field: Field) {
        switch field {
        case .origin: originQuery = query
        case .destination: destinationQuery = query
        }
    }

    private func selectedPlace(for field: Field) -> RoutePlace? {
        switch field {
        case .origin: origin
        case .destination: destination
        }
    }

    private func setSelectedPlace(_ place: RoutePlace?, for field: Field) {
        switch field {
        case .origin: origin = place
        case .destination: destination = place
        }
    }
}
