import CoreLocation
import Foundation
import MapKit
import SweatDomain

/// MapKit 도보 경로를 공급자 중립 도메인 값으로 바꾼다.
@MainActor
public final class MapKitWalkingRouteSource: WalkingRouteProviding {
    public init() {}

    public func routes(
        from origin: RoutePlace,
        to destination: RoutePlace,
        departingAt departureDate: Date
    ) async throws -> [WalkingRoute] {
        let request = MKDirections.Request()
        request.source = mapItem(for: origin)
        request.destination = mapItem(for: destination)
        request.transportType = .walking
        request.requestsAlternateRoutes = true
        request.departureDate = departureDate

        let response: MKDirections.Response
        do {
            response = try await MKDirections(request: request).calculate()
        } catch {
            throw WalkingRouteError.unavailable
        }

        let routes = response.routes.compactMap { route in
            makeWalkingRoute(route, origin: origin, destination: destination)
        }
        guard !routes.isEmpty else { throw WalkingRouteError.noRoute }
        return routes
    }

    private func mapItem(for place: RoutePlace) -> MKMapItem {
        let location = CLLocation(
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude
        )
        let item = MKMapItem(location: location, address: nil)
        item.name = place.name
        return item
    }

    private func makeWalkingRoute(
        _ route: MKRoute,
        origin: RoutePlace,
        destination: RoutePlace
    ) -> WalkingRoute? {
        guard route.transportType.contains(.walking) else { return nil }

        let steps = route.steps.compactMap { step -> RouteStep? in
            let duration: TimeInterval
            if route.distance > 0 {
                duration = route.expectedTravelTime * (step.distance / route.distance)
            } else {
                duration = 0
            }
            return RouteStep(
                instruction: step.instructions,
                distanceMeters: step.distance,
                expectedTravelTime: duration,
                path: coordinates(from: step.polyline)
            )
        }

        return WalkingRoute(
            origin: origin,
            destination: destination,
            distanceMeters: route.distance,
            expectedTravelTime: route.expectedTravelTime,
            path: coordinates(from: route.polyline),
            steps: steps
        )
    }

    private func coordinates(from polyline: MKPolyline) -> [Coordinate] {
        guard polyline.pointCount > 0 else { return [] }
        var coordinates = Array(
            repeating: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            count: polyline.pointCount
        )
        polyline.getCoordinates(&coordinates, range: NSRange(location: 0, length: polyline.pointCount))
        return coordinates.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
    }
}
