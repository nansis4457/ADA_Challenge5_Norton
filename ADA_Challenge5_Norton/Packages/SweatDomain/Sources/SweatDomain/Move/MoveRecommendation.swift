import Foundation

/// 현재 위치 앞쪽에서 분석된 그늘 없는 구간.
public struct AheadExposureEstimate: Sendable, Codable, Equatable {
    public let expectedDuration: TimeInterval

    public init?(expectedDuration: TimeInterval) {
        guard expectedDuration.isFinite, expectedDuration > 0 else { return nil }
        self.expectedDuration = expectedDuration
    }
}

/// 공식 데이터에서 운영 상태가 확인된 무더위쉼터 후보.
public struct HeatShelterRecommendation: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let name: String
    public let coordinate: Coordinate
    public let distanceMeters: Double
    public let expectedWalkingTime: TimeInterval
    public let sourceName: String

    public init?(
        id: String,
        name: String,
        coordinate: Coordinate,
        distanceMeters: Double,
        expectedWalkingTime: TimeInterval,
        sourceName: String
    ) {
        let trimmedID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSource = sourceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedID.isEmpty, !trimmedName.isEmpty, !trimmedSource.isEmpty,
              coordinate.isValid,
              distanceMeters.isFinite, distanceMeters >= 0,
              expectedWalkingTime.isFinite, expectedWalkingTime >= 0
        else { return nil }

        self.id = trimmedID
        self.name = trimmedName
        self.coordinate = coordinate
        self.distanceMeters = distanceMeters
        self.expectedWalkingTime = expectedWalkingTime
        self.sourceName = trimmedSource
    }
}

/// 실제 대안 경로와 비교해 얻은 그늘 우회 추정.
public struct ShadeDetourRecommendation: Sendable, Codable, Equatable {
    public let route: WalkingRoute
    public let additionalTravelTime: TimeInterval
    public let expectedOutdoorTimeReduction: TimeInterval

    public init?(
        route: WalkingRoute,
        additionalTravelTime: TimeInterval,
        expectedOutdoorTimeReduction: TimeInterval
    ) {
        guard additionalTravelTime.isFinite, additionalTravelTime >= 0,
              expectedOutdoorTimeReduction.isFinite, expectedOutdoorTimeReduction > 0
        else { return nil }
        self.route = route
        self.additionalTravelTime = additionalTravelTime
        self.expectedOutdoorTimeReduction = expectedOutdoorTimeReduction
    }
}

/// 추천은 하나의 전체 상태가 아니라 근거별로 독립해 존재한다.
public struct MoveRecommendations: Sendable, Codable, Equatable {
    public let aheadExposure: AheadExposureEstimate?
    public let shelter: HeatShelterRecommendation?
    public let shadeDetour: ShadeDetourRecommendation?

    public init(
        aheadExposure: AheadExposureEstimate? = nil,
        shelter: HeatShelterRecommendation? = nil,
        shadeDetour: ShadeDetourRecommendation? = nil
    ) {
        self.aheadExposure = aheadExposure
        self.shelter = shelter
        self.shadeDetour = shadeDetour
    }

    public var hasAnyAnalysis: Bool {
        aheadExposure != nil || shelter != nil || shadeDetour != nil
    }
}
