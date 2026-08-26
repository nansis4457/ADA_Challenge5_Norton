import Foundation
import SweatDomain

enum MoveCopy {
    static let kicker = "이동 중"
    static let exposureHeading = "앞 구간은 더울 수 있어요"
    static let basicHeading = "경로를 따라 이동 중이에요"
    static let basicBody = "실내·그늘 구간 데이터가 없어 현재는 남은 거리와 예상 시간만 안내해요."
    static let shelterAction = "무더위쉼터 들르기"
    static let detourAction = "그늘길로 우회"
    static let waterAction = "물 마시기 알림"
    static let waterDetail = "10분 뒤 다시 알려드릴게요"
    static let waterScheduled = "10분 뒤 알림이 예약됐어요"
    static let waterDenied = "알림 권한이 없어 예약할 수 없어요. 설정에서 알림을 켤 수 있어요."
    static let waterFailed = "알림을 예약하지 못했어요. 잠시 뒤 다시 시도해보세요."
    static let finish = "도착 · 오늘 기록하기"
    static let cancel = "이동 종료"
    static let locationPending = "위치를 확인하고 있어요"
    static let locationDenied = "위치 권한이 없어 자동으로 진행 상황을 계산할 수 없어요."
    static let locationFailed = "위치 정보를 이어서 받지 못했어요. 이동을 종료하거나 잠시 뒤 다시 확인해보세요."
    static let activityUnavailable = "잠금 화면 표시는 사용할 수 없지만 앱에서 이동을 계속 확인할 수 있어요."

    static func progressLine(_ progress: MoveProgress) -> String {
        "\(elapsedMinutes(progress.elapsedTime))분 경과 · 남은 거리 \(distance(progress.remainingDistanceMeters))"
    }

    static func remainingTime(_ progress: MoveProgress) -> String {
        "예상 \(remainingMinutes(progress.estimatedRemainingTime))분 남음"
    }

    static func progressAccessibility(
        route: WalkingRoute,
        progress: MoveProgress
    ) -> String {
        let percentage = Int((progress.fractionCompleted * 100).rounded())
        return "\(route.origin.name)에서 \(route.destination.name)까지, \(percentage)% 진행, "
            + "남은 거리 \(distance(progress.remainingDistanceMeters)), "
            + remainingTime(progress)
    }

    static func exposureBody(
        _ estimate: AheadExposureEstimate,
        hasShelter: Bool
    ) -> String {
        let first = "앞으로 \(durationMinutes(estimate.expectedDuration))분간 그늘이 없는 구간으로 예상돼요."
        return hasShelter ? first + " 근처에서 잠깐 쉬어갈 수 있어요." : first
    }

    static func shelterDetail(_ shelter: HeatShelterRecommendation) -> String {
        "\(distance(shelter.distanceMeters)) 앞 무더위쉼터 · 냉방 · 도보 "
            + "\(durationMinutes(shelter.expectedWalkingTime))분"
    }

    static func shelterAccessibility(_ shelter: HeatShelterRecommendation) -> String {
        shelterAction + ", " + shelter.name + ", " + shelterDetail(shelter)
    }

    static func detourDetail(_ detour: ShadeDetourRecommendation) -> String {
        "+\(durationMinutes(detour.additionalTravelTime))분 · 직사광선 구간이 약 "
            + "\(durationMinutes(detour.expectedOutdoorTimeReduction))분 줄어들 것으로 예상돼요"
    }

    static func stale(lastObservedAt: Date?) -> String {
        guard let lastObservedAt else { return locationPending }
        return "위치가 잠시 멈췄어요. 마지막 확인 "
            + lastObservedAt.formatted(date: .omitted, time: .shortened)
    }

    static func distance(_ meters: Double) -> String {
        if meters >= 1_000 {
            return (meters / 1_000).formatted(.number.precision(.fractionLength(1))) + "km"
        }
        return "\(Int((meters / 10).rounded() * 10))m"
    }

    static func elapsedMinutes(_ seconds: TimeInterval) -> Int {
        max(Int(seconds / 60), 0)
    }

    static func remainingMinutes(_ seconds: TimeInterval) -> Int {
        max(Int(ceil(seconds / 60)), 0)
    }

    static func durationMinutes(_ seconds: TimeInterval) -> Int {
        max(Int(ceil(seconds / 60)), 1)
    }
}
