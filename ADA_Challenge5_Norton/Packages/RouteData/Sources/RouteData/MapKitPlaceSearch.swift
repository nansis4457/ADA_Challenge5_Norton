import CoreLocation
import Foundation
import MapKit
import SweatDomain

/// MapKit 자동완성과 장소 검색을 하나의 async 경계로 감싼다.
@MainActor
public final class MapKitPlaceSearch: NSObject, PlaceSearching {
    private let completer: MKLocalSearchCompleter
    private var completions: [String: MKLocalSearchCompletion] = [:]
    private var pending: CheckedContinuation<[PlaceSuggestion], any Error>?

    public override init() {
        let completer = MKLocalSearchCompleter()
        completer.resultTypes = [.address, .pointOfInterest]
        self.completer = completer
        super.init()
        completer.delegate = self
    }

    public func suggestions(
        for query: String,
        near coordinate: Coordinate?
    ) async throws -> [PlaceSuggestion] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            cancel()
            return []
        }

        cancelPending(throwing: CancellationError())
        completions.removeAll(keepingCapacity: true)

        if let coordinate, coordinate.isValid {
            completer.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                ),
                latitudinalMeters: 30_000,
                longitudinalMeters: 30_000
            )
            completer.regionPriority = .required
        } else {
            completer.regionPriority = .default
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pending = continuation
                completer.queryFragment = query
            }
        } onCancel: {
            Task { @MainActor [weak self] in self?.cancel() }
        }
    }

    public func resolve(_ suggestion: PlaceSuggestion) async throws -> RoutePlace {
        guard let completion = completions[suggestion.id] else {
            throw PlaceSearchError.suggestionExpired
        }

        let request = MKLocalSearch.Request(completion: completion)
        request.resultTypes = [.address, .pointOfInterest]
        let response: MKLocalSearch.Response
        do {
            response = try await MKLocalSearch(request: request).start()
        } catch {
            throw PlaceSearchError.unavailable
        }

        guard let item = response.mapItems.first else {
            throw PlaceSearchError.noResolvedPlace
        }

        let location = item.location.coordinate
        let detail = item.address?.shortAddress?.nonEmpty ?? suggestion.subtitle.nonEmpty
        guard let place = RoutePlace(
            name: item.name?.nonEmpty ?? suggestion.title,
            detail: detail,
            coordinate: Coordinate(latitude: location.latitude, longitude: location.longitude)
        ) else {
            throw PlaceSearchError.noResolvedPlace
        }
        return place
    }

    public func cancel() {
        completer.cancel()
        cancelPending(throwing: CancellationError())
    }

    private func cancelPending(throwing error: any Error) {
        pending?.resume(throwing: error)
        pending = nil
    }
}

extension MapKitPlaceSearch: @preconcurrency MKLocalSearchCompleterDelegate {
    public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        var nextCompletions: [String: MKLocalSearchCompletion] = [:]
        let suggestions = completer.results.map { completion in
            let id = UUID().uuidString
            nextCompletions[id] = completion
            return PlaceSuggestion(
                id: id,
                title: completion.title,
                subtitle: completion.subtitle
            )
        }

        completions = nextCompletions
        pending?.resume(returning: suggestions)
        pending = nil
    }

    public func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        cancelPending(throwing: PlaceSearchError.unavailable)
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
