import Foundation
import Testing
@testable import MoveActivitySupport

@Suite("Live Activity 갱신 정책")
struct MoveActivityUpdatePolicyTests {
    private let policy = MoveActivityUpdatePolicy()
    private let start = Date(timeIntervalSinceReferenceDate: 1_000)

    @Test("29초와 4.9퍼센트포인트 변화는 갱신하지 않는다")
    func belowBothThresholds() {
        #expect(!policy.shouldUpdate(
            lastUpdatedAt: start,
            lastFraction: 0.2,
            nextObservedAt: start.addingTimeInterval(29),
            nextFraction: 0.249
        ))
    }

    @Test("30초가 지나면 작은 진행 변화도 갱신한다")
    func intervalThreshold() {
        #expect(policy.shouldUpdate(
            lastUpdatedAt: start,
            lastFraction: 0.2,
            nextObservedAt: start.addingTimeInterval(30),
            nextFraction: 0.201
        ))
    }

    @Test("5퍼센트포인트가 바뀌면 30초 전에도 갱신한다")
    func progressThreshold() {
        #expect(policy.shouldUpdate(
            lastUpdatedAt: start,
            lastFraction: 0.2,
            nextObservedAt: start.addingTimeInterval(5),
            nextFraction: 0.25
        ))
    }

    @Test("이전 시각으로 돌아간 이벤트는 갱신하지 않는다")
    func rejectsEarlierDate() {
        #expect(!policy.shouldUpdate(
            lastUpdatedAt: start,
            lastFraction: 0.2,
            nextObservedAt: start.addingTimeInterval(-1),
            nextFraction: 0.8
        ))
    }
}
