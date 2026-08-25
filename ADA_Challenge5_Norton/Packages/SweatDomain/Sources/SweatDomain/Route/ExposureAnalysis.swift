import Foundation

/// 경로 한 구간의 노출 분류.
public enum ExposureKind: String, Sendable, Codable, CaseIterable {
    /// 실내 또는 지하로 확인된 구간.
    case covered
    /// 실외로 확인된 구간.
    case outdoor
    /// 데이터가 없어 분류하지 못한 구간.
    case unknown
}

/// 시간 순서로 이어지는 노출 구간.
public struct ExposureSegment: Identifiable, Sendable, Codable, Equatable, Hashable {
    public let id: UUID
    public let kind: ExposureKind
    public let expectedDuration: TimeInterval

    public init?(
        id: UUID = UUID(),
        kind: ExposureKind,
        expectedDuration: TimeInterval
    ) {
        guard expectedDuration.isFinite, expectedDuration > 0 else { return nil }
        self.id = id
        self.kind = kind
        self.expectedDuration = expectedDuration
    }
}

/// 도보 경로의 실내·지하/실외 노출 추정.
///
/// 전달된 구간 합이 전체 시간보다 짧으면 나머지는 `unknown`으로 채운다. 데이터가 없는
/// 시간을 실외로 간주하지 않기 위해서다. 분석된 구간이 하나도 없으면 생성하지 않는다.
public struct ExposureAnalysis: Sendable, Codable, Equatable {
    public let routeDuration: TimeInterval
    public let segments: [ExposureSegment]

    public init?(routeDuration: TimeInterval, segments: [ExposureSegment]) {
        guard routeDuration.isFinite, routeDuration > 0 else { return nil }

        let suppliedDuration = segments.reduce(0) { $0 + $1.expectedDuration }
        let tolerance = max(routeDuration * 0.001, 0.1)
        guard suppliedDuration <= routeDuration + tolerance else { return nil }

        let analyzedDuration = segments
            .filter { $0.kind != .unknown }
            .reduce(0) { $0 + $1.expectedDuration }
        guard analyzedDuration > 0 else { return nil }

        var normalized = segments
        let remainder = routeDuration - suppliedDuration
        if remainder > tolerance,
           let unknown = ExposureSegment(kind: .unknown, expectedDuration: remainder) {
            normalized.append(unknown)
        }

        self.routeDuration = routeDuration
        self.segments = normalized
    }

    public var coveredDuration: TimeInterval { duration(of: .covered) }
    public var outdoorDuration: TimeInterval { duration(of: .outdoor) }
    public var unknownDuration: TimeInterval {
        max(routeDuration - coveredDuration - outdoorDuration, 0)
    }

    /// 전체 경로 중 실제로 분류한 비율.
    public var coverageRatio: Double {
        clampedRatio((coveredDuration + outdoorDuration) / routeDuration)
    }

    public var coveredRatio: Double { clampedRatio(coveredDuration / routeDuration) }
    public var outdoorRatio: Double { clampedRatio(outdoorDuration / routeDuration) }
    public var unknownRatio: Double { clampedRatio(unknownDuration / routeDuration) }

    private func duration(of kind: ExposureKind) -> TimeInterval {
        segments.lazy
            .filter { $0.kind == kind }
            .reduce(0) { $0 + $1.expectedDuration }
    }

    private func clampedRatio(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
