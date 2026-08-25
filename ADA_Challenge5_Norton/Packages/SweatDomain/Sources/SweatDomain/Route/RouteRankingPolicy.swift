import Foundation

/// 예상 시간과 실외 노출로 도보 경로 후보의 순서를 정한다.
///
/// 값은 의학적 위험 점수가 아니라 **표시 순서를 위한 제품 정책**이다. 단계가 높을수록
/// 실외 1초의 추가 비용이 단조 증가한다. 실제 노출 분석이 없으면 예상 시간만 비교한다.
public enum RouteRankingPolicy {
    private static let outdoorPenalties: [Double] = [0, 0.15, 0.3, 0.45, 0.65, 0.85]

    public static func outdoorPenalty(for stage: SweatStage) -> Double {
        outdoorPenalties[stage.rawValue - 1]
    }

    public static func score(_ route: WalkingRoute, stage: SweatStage) -> Double {
        route.expectedTravelTime
            + (route.exposure?.outdoorDuration ?? 0) * outdoorPenalty(for: stage)
    }

    public static func ranked(_ routes: [WalkingRoute], stage: SweatStage) -> [WalkingRoute] {
        routes.sorted { lhs, rhs in
            let left = score(lhs, stage: stage)
            let right = score(rhs, stage: stage)
            if left == right { return lhs.expectedTravelTime < rhs.expectedTravelTime }
            return left < right
        }
    }
}
