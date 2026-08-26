import Foundation

enum RouteCopy {
    static let mapTitle = "지도"
    static let searchAction = "경로 검색"
    static let mapUnavailableTitle = "지도를 불러오지 못했어요"
    static let mapUnavailableBody = "네트워크 연결을 확인하고 다시 시도해보세요."
    static let backToMap = "지도"
    static let inputHeading = "어디로 이동하세요?"
    static let origin = "출발"
    static let destination = "도착"
    static let departure = "출발 시간"
    static let currentLocationAction = "현재 위치를 출발지로 사용"
    static let locatingCurrentLocation = "현재 위치를 확인하고 있어요"
    static let currentLocationName = "현재 위치"
    static let currentLocationDenied = "위치 권한이 꺼져 있어요. 출발지를 직접 검색해주세요."
    static let currentLocationUnavailable = "현재 위치를 확인하지 못했어요. 출발지를 직접 검색해주세요."
    static let calculate = "경로 계산하기"
    static let inputNote = "데이터가 있는 경로에서는 그늘·실내 구간 비중과 예상 실외 노출 시간을 함께 계산해요."
    static let searching = "장소를 찾고 있어요"
    static let calculating = "도보 경로를 계산하고 있어요"
    static let emptySearch = "검색 결과가 없어요. 다른 이름이나 주소로 다시 찾아보세요."
    static let searchFailed = "장소를 찾지 못했어요. 네트워크를 확인하고 다시 시도해보세요."
    static let routeFailed = "도보 경로를 가져오지 못했어요. 잠시 후 다시 시도해보세요."
    static let routeUnavailable = "도보 경로를 찾지 못했어요. 출발지나 도착지를 바꿔보세요."
    static let retry = "다시 시도"

    static func selectionStatus(field: String, place: String?) -> String {
        if let place { return "\(field)지 선택 완료: \(place)" }
        return "\(field)지를 검색 결과에서 선택해주세요."
    }

    static let modifyRoute = "경로 수정"
    static let lessExposureHeading = "실외 노출이 적을 것으로 예상돼요"
    static let fastHeading = "빠른 도보 경로예요"
    static let total = "예상 소요"
    static let outdoorExposure = "예상 실외 노출"
    static let covered = "실내·지하 추정"
    static let outdoor = "실외 추정"
    static let unknown = "분석 안 됨"
    static let waypoints = "주요 구간"
    static let start = "이동 시작"
    static let lessExposureAction = "실외 노출이 적은 길 보기"
    static let estimateDisclosure = "구간 비율과 노출 시간은 지도·건물·통로 데이터를 바탕으로 계산한 추정치예요. 현장 상황과 다를 수 있어요."
    static let analysisUnavailable = "현재 경로는 실내·지하 구간 데이터를 확인할 수 없어 예상 소요 시간만 보여드려요."
    static let startPendingTitle = "경로를 선택했어요"
    static let startPendingBody = "이동 중 안내는 다음 단계에서 연결할게요."
    static let confirm = "확인"
    static let originMarker = "출발지"
    static let destinationMarker = "도착지"
    static let walkStep = "도보 이동"
    static let arrived = "도착"

    static func routePair(origin: String, destination: String) -> String {
        "\(origin) → \(destination)"
    }

    static func startPendingMessage(origin: String, destination: String) -> String {
        "\(routePair(origin: origin, destination: destination))\n\(startPendingBody)"
    }

    static func duration(_ seconds: TimeInterval) -> String {
        "\(max(Int((seconds / 60).rounded()), 1))분"
    }

    static func elapsedDuration(_ seconds: TimeInterval) -> String {
        "\(max(Int((seconds / 60).rounded()), 0))분"
    }

    static func percentage(_ ratio: Double) -> String {
        "\(Int((min(max(ratio, 0), 1) * 100).rounded()))%"
    }

    static func legend(_ title: String, ratio: Double) -> String {
        "\(title) \(percentage(ratio))"
    }

    static func partialCoverage(_ ratio: Double) -> String {
        "전체 경로 중 \(percentage(ratio)) 구간을 분석했어요."
    }

    static func mapLabel(origin: String?, destination: String?, minutes: String?) -> String {
        guard let origin, let destination, let minutes else {
            return "현재 위치를 확인할 수 있는 지도"
        }
        return "\(origin)에서 \(destination)까지 \(minutes) 도보 경로 지도"
    }

    static func segmentLabel(covered: Double, outdoor: Double, unknown: Double) -> String {
        var parts = [legend(coveredTitle, ratio: covered), legend(outdoorTitle, ratio: outdoor)]
        if unknown > 0.001 { parts.append(legend(unknownTitle, ratio: unknown)) }
        return parts.joined(separator: ", ")
    }

    private static let coveredTitle = covered
    private static let outdoorTitle = outdoor
    private static let unknownTitle = unknown
}
