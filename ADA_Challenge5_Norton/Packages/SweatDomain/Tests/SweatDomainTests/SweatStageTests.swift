import Testing
@testable import SweatDomain

@Suite("SweatStage — 구간 정의")
struct SweatStageTests {

    /// R3 · R5 — 경계값 전수.
    ///
    /// 각 경계에서 정확히 어느 쪽으로 떨어지는지 고정한다.
    /// 하한은 포함, 상한은 제외다.
    @Test("경계 직전·직후", arguments: [
        (27.9, 1), (28.0, 2),
        (32.9, 2), (33.0, 3),
        (34.9, 3), (35.0, 4),
        (35.9, 4), (36.0, 5),
        (42.9, 5), (43.0, 6),
    ])
    func boundary(temperature: Double, expected: Int) {
        #expect(SweatStage.containing(temperature).rawValue == expected)
    }

    @Test("구간이 빈틈없이 이어진다")
    func rangesAreContiguous() {
        let all = SweatStage.allCases
        #expect(all.count == SweatStage.boundaries.count + 1)
        #expect(all.first?.range.lowerBound == -.infinity)
        #expect(all.last?.range.upperBound == .infinity)
        for (lower, upper) in zip(all, all.dropFirst()) {
            #expect(lower.range.upperBound == upper.range.lowerBound,
                    "\(lower)와 \(upper) 사이에 빈틈 또는 겹침")
        }
    }

    @Test("range와 containing이 서로 모순되지 않는다")
    func rangeMatchesLookup() {
        for stage in SweatStage.allCases {
            let lower = stage.range.lowerBound
            if lower.isFinite {
                #expect(SweatStage.containing(lower) == stage)
            }
            let upper = stage.range.upperBound
            if upper.isFinite {
                #expect(SweatStage.containing(upper) != stage, "상한은 제외되어야 한다")
            }
        }
    }

    @Test("안전 안내가 필요한 단계는 5·6뿐")
    func safetyGuidance() {
        #expect(SweatStage.allCases.filter(\.requiresSafetyGuidance) == [.five, .six])
    }

    @Test("Comparable 순서가 rawValue와 일치")
    func ordering() {
        #expect(SweatStage.allCases == SweatStage.allCases.sorted())
        #expect(SweatStage.one < SweatStage.six)
    }
}
