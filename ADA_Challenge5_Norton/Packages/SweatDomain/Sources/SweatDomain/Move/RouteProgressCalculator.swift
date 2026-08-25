import Foundation

/// 도보 경로 좌표열에 현재 위치를 투영해 진행률을 계산한다.
public struct RouteProgressCalculator: Sendable {
    /// 경로에서 이 거리보다 멀면 경로 이탈로 보고 새 진행값을 만들지 않는다.
    public let maximumSnapDistanceMeters: Double

    public init(maximumSnapDistanceMeters: Double = 60) {
        self.maximumSnapDistanceMeters = max(0, maximumSnapDistanceMeters)
    }

    public func progress(
        session: MoveSession,
        location: Coordinate,
        observedAt: Date,
        previous: MoveProgress? = nil
    ) -> MoveProgress? {
        guard location.isValid,
              observedAt.timeIntervalSinceReferenceDate.isFinite,
              observedAt >= session.startedAt,
              let projection = projection(of: location, onto: session.route.path),
              projection.distanceFromPath <= maximumSnapDistanceMeters
        else { return nil }

        let previousFraction = previous.flatMap { progress in
            progress.sessionID == session.id && progress.routeID == session.route.id
                ? progress.fractionCompleted
                : nil
        } ?? 0
        let fraction = min(max(max(projection.fraction, previousFraction), 0), 1)
        let traveled = session.route.distanceMeters * fraction
        let remaining = max(session.route.distanceMeters - traveled, 0)
        let remainingTime = max(session.route.expectedTravelTime * (1 - fraction), 0)

        return MoveProgress(
            sessionID: session.id,
            routeID: session.route.id,
            observedAt: observedAt,
            elapsedTime: observedAt.timeIntervalSince(session.startedAt),
            traveledDistanceMeters: traveled,
            remainingDistanceMeters: remaining,
            estimatedRemainingTime: remainingTime,
            fractionCompleted: fraction
        )
    }

    private func projection(
        of point: Coordinate,
        onto path: [Coordinate]
    ) -> (fraction: Double, distanceFromPath: Double)? {
        guard path.count >= 2 else { return nil }

        let segmentLengths = zip(path, path.dropFirst()).map(Self.surfaceDistance)
        let totalLength = segmentLengths.reduce(0, +)
        guard totalLength.isFinite, totalLength > 0 else { return nil }

        var traversed = 0.0
        var bestDistance = Double.greatestFiniteMagnitude
        var bestAlong = 0.0

        for index in segmentLengths.indices {
            let start = path[index]
            let end = path[index + 1]
            let referenceLatitude = (start.latitude + end.latitude + point.latitude) / 3
            let segment = Self.planarDelta(from: start, to: end, at: referenceLatitude)
            let toPoint = Self.planarDelta(from: start, to: point, at: referenceLatitude)
            let squaredLength = segment.x * segment.x + segment.y * segment.y
            guard squaredLength > 0 else {
                traversed += segmentLengths[index]
                continue
            }

            let rawT = (toPoint.x * segment.x + toPoint.y * segment.y) / squaredLength
            let t = min(max(rawT, 0), 1)
            let offsetX = toPoint.x - segment.x * t
            let offsetY = toPoint.y - segment.y * t
            let distance = hypot(offsetX, offsetY)

            if distance < bestDistance {
                bestDistance = distance
                bestAlong = traversed + segmentLengths[index] * t
            }
            traversed += segmentLengths[index]
        }

        guard bestDistance.isFinite else { return nil }
        return (min(max(bestAlong / totalLength, 0), 1), bestDistance)
    }

    private static func planarDelta(
        from origin: Coordinate,
        to point: Coordinate,
        at referenceLatitude: Double
    ) -> (x: Double, y: Double) {
        let latitudeDelta = radians(point.latitude - origin.latitude)
        let longitudeDelta = radians(normalizedLongitudeDelta(point.longitude - origin.longitude))
        let x = earthRadiusMeters * longitudeDelta * cos(radians(referenceLatitude))
        let y = earthRadiusMeters * latitudeDelta
        return (x, y)
    }

    private static func surfaceDistance(_ start: Coordinate, _ end: Coordinate) -> Double {
        let latitudeDelta = radians(end.latitude - start.latitude)
        let longitudeDelta = radians(normalizedLongitudeDelta(end.longitude - start.longitude))
        let startLatitude = radians(start.latitude)
        let endLatitude = radians(end.latitude)
        let a = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(startLatitude) * cos(endLatitude)
            * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        return earthRadiusMeters * 2 * atan2(sqrt(a), sqrt(max(1 - a, 0)))
    }

    private static func normalizedLongitudeDelta(_ degrees: Double) -> Double {
        var value = degrees.truncatingRemainder(dividingBy: 360)
        if value > 180 { value -= 360 }
        if value < -180 { value += 360 }
        return value
    }

    private static func radians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }

    private static let earthRadiusMeters = 6_371_000.0
}
