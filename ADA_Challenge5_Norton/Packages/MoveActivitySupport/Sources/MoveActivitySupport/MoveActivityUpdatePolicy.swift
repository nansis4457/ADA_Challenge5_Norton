import Foundation

public struct MoveActivityUpdatePolicy: Sendable {
    public let minimumInterval: TimeInterval
    public let minimumProgressChange: Double

    public init(
        minimumInterval: TimeInterval = 30,
        minimumProgressChange: Double = 0.05
    ) {
        self.minimumInterval = max(minimumInterval, 0)
        self.minimumProgressChange = max(minimumProgressChange, 0)
    }

    public func shouldUpdate(
        lastUpdatedAt: Date,
        lastFraction: Double,
        nextObservedAt: Date,
        nextFraction: Double
    ) -> Bool {
        guard nextObservedAt >= lastUpdatedAt else { return false }
        let elapsed = nextObservedAt.timeIntervalSince(lastUpdatedAt)
        let progressChange = abs(nextFraction - lastFraction)
        // 0.25 - 0.20처럼 십진 경계가 이진 부동소수점에서 아주 작게 낮아지는 경우를 허용한다.
        let tolerance = 1e-9
        return elapsed >= minimumInterval
            || progressChange + tolerance >= minimumProgressChange
    }
}
