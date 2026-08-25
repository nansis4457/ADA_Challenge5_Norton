import SweatDomain

/// 도보 경로의 실내·지하/실외 구간을 분석한다.
public protocol ExposureAnalyzing: Sendable {
    func analyze(_ route: WalkingRoute) async -> ExposureAnalysis?
}

/// 실제 데이터 공급자가 없을 때 쓰는 정직한 기본값.
public struct NoCoverageExposureAnalyzer: ExposureAnalyzing {
    public init() {}
    public func analyze(_ route: WalkingRoute) async -> ExposureAnalysis? { nil }
}

/// 테스트·미리보기·수동 검증용 고정 비율 분석기.
///
/// 실제 경로 분석처럼 사용하지 않도록 이름에 `Fixture`를 남긴다.
public struct FixtureExposureAnalyzer: ExposureAnalyzing {
    private let coveredRatio: Double
    private let outdoorRatio: Double

    public init?(coveredRatio: Double, outdoorRatio: Double) {
        guard coveredRatio.isFinite, outdoorRatio.isFinite,
              coveredRatio >= 0, outdoorRatio >= 0,
              coveredRatio + outdoorRatio > 0,
              coveredRatio + outdoorRatio <= 1 else { return nil }
        self.coveredRatio = coveredRatio
        self.outdoorRatio = outdoorRatio
    }

    public func analyze(_ route: WalkingRoute) async -> ExposureAnalysis? {
        let covered = ExposureSegment(
            kind: .covered,
            expectedDuration: route.expectedTravelTime * coveredRatio
        )
        let outdoor = ExposureSegment(
            kind: .outdoor,
            expectedDuration: route.expectedTravelTime * outdoorRatio
        )
        return ExposureAnalysis(
            routeDuration: route.expectedTravelTime,
            segments: [covered, outdoor].compactMap { $0 }
        )
    }
}
