import DesignSystem
import MapKit
import SwiftUI
import SweatDomain

/// 지도 공급자 전환 경계. MapKit 타입은 이 파일 밖으로 내보내지 않는다.
struct RouteMapView: View {
    let route: WalkingRoute?
    let showsUserLocation: Bool
    @State private var position: MapCameraPosition

    init(route: WalkingRoute? = nil, showsUserLocation: Bool = true) {
        self.route = route
        self.showsUserLocation = showsUserLocation
        _position = State(initialValue: Self.position(for: route))
    }

    var body: some View {
        Map(position: $position) {
            if showsUserLocation {
                UserAnnotation()
            }
            if let route {
                Marker(RouteCopy.originMarker, coordinate: coordinate(route.origin.coordinate))
                    .tint(Ink.n900)
                Marker(RouteCopy.destinationMarker, coordinate: coordinate(route.destination.coordinate))
                    .tint(Magenta.base)
                MapPolyline(coordinates: route.path.map(coordinate))
                    .stroke(Accent.base, style: StrokeStyle(lineWidth: Space.x1, lineCap: .round, lineJoin: .round))
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControls {
            MapCompass()
            if showsUserLocation { MapUserLocationButton() }
        }
        .accessibilityLabel(RouteCopy.mapLabel(
            origin: route?.origin.name,
            destination: route?.destination.name,
            minutes: route.map { RouteCopy.duration($0.expectedTravelTime) }
        ))
        .onChange(of: route?.id) { _, _ in
            position = Self.position(for: route)
        }
    }

    private func coordinate(_ value: Coordinate) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: value.latitude, longitude: value.longitude)
    }

    private static func position(for route: WalkingRoute?) -> MapCameraPosition {
        guard let route else {
            let seoul = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                latitudinalMeters: 8_000,
                longitudinalMeters: 8_000
            )
            return .userLocation(followsHeading: false, fallback: .region(seoul))
        }

        var rect = MKMapRect.null
        for coordinate in route.path {
            let point = MKMapPoint(CLLocationCoordinate2D(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ))
            rect = rect.union(MKMapRect(origin: point, size: MKMapSize(width: 1, height: 1)))
        }
        let padding = max(rect.width, rect.height) * 0.2
        return .rect(rect.insetBy(dx: -padding, dy: -padding))
    }
}
