import Foundation
import SweatDomain
import SweatPersistence

/// 마이페이지·자가 기록·지수 개선 화면의 모든 문구와 값 포맷.
enum ProfileCopy {
    static let title = "마이페이지"
    static let profileName = "내 프로필"
    static let avatarInitial = "나"

    static let recordedDays = "기록한 날"
    static let averageScore = "평균 체감 점수"
    static let predictionDifference = "예측과의 차이"

    static let managementSection = "내 땀 관리"
    static let logToday = "오늘 땀 기록하기"
    static let logEmpty = "오늘 기록이 아직 없어요"
    static let logDone = "오늘 기록을 수정할 수 있어요"
    static let history = "기록 히스토리"
    static let historyDescription = "최근 7일 예측과 실제 비교"
    static let editSensitivity = "내 땀 민감도 다시 설정"
    static let currentPrefix = "현재"
    static let editMovement = "이동 패턴 수정"
    static let stageGuide = "땀 단계 기준 보기"
    static let stageGuideDescription = "1~6단계 설명과 계산 방식"
    static let weatherNeeded = "홈에서 오늘 날씨를 먼저 확인해주세요"

    static let settingsSection = "설정"
    static let notification = "외출 전 알림"
    static let notificationOn = "켜짐"
    static let notificationOff = "꺼짐"
    static let location = "위치"
    static let currentLocation = "현재 위치"
    static let regionNeeded = "지역 선택 필요"
    static let dataSource = "데이터 출처"
    static let dataSourcePending = "날씨를 불러오면 표시돼요"

    static let backToProfile = "← 마이페이지"
    static let logKicker = "자가 기록"
    static let logHeading = "오늘 땀은 어느 정도였나요?"
    static let logSub = "기록은 예측 등급과 비교되어 다음 방문의 기준을 조정합니다."
    static let comfortable = "쾌적했다"
    static let verySweaty = "매우 땀참"
    static let tagPrompt = "어떤 게 힘들었나요"
    static let todayPrediction = "오늘 예측"
    static let chooseScorePrompt = "점수를 선택하면 예측과 체감을 비교해드릴게요."
    static let saveLog = "기록 저장"
    static let saveFailure = "기록을 저장하지 못했어요. 입력을 유지했으니 다시 시도해주세요."

    static let reportPeriod = "최근 7일"
    static let reportHeading = "이번주 날씨를 분석해봤어요"
    static let reportLegend = "회색은 앱이 예측한 등급, 파랑은 직접 기록한 체감이에요."
    static let predicted = "앱 예측"
    static let actual = "직접 기록"
    static let noRecentRecords = "최근 7일 기록이 아직 없어요"
    static let noRecentRecordsBody = "오늘의 체감을 기록하면 예측과 나란히 비교할 수 있어요."
    static let adjustedHeading = "기준이 조정되었어요"
    static let analyzedHeading = "기록을 분석했어요"
    static let waitingHeading = "기록을 더 모으고 있어요"
    static let confirm = "확인"
    static let eligibleSamples = "학습에 쓴 고습도 기록"
    static let higherSamples = "예측보다 높았던 기록"
    static let scoreUnit = "점"
    static let stageUnit = "단계"

    static func profileMeta(_ profile: UserProfile) -> String {
        [
            OnboardingCopy.Sensitivity.title(profile.sensitivity),
            OnboardingCopy.Movement.title(profile.transport),
            OnboardingCopy.Movement.title(profile.outdoorDuration),
        ].joined(separator: " · ")
    }

    static func sensitivityValue(_ sensitivity: Sensitivity) -> String {
        "\(currentPrefix) \(OnboardingCopy.Sensitivity.title(sensitivity))"
    }

    static func movementValue(_ profile: UserProfile) -> String {
        "\(OnboardingCopy.Movement.title(profile.transport)) · \(OnboardingCopy.Movement.title(profile.outdoorDuration))"
    }

    static func recordedDaysValue(_ count: Int) -> String { "\(count)일" }

    static func averageScoreValue(_ logs: [SweatLog]) -> String {
        guard !logs.isEmpty else { return "—" }
        return oneDecimal(logs.map { Double($0.actualScore) }.reduce(0, +) / Double(logs.count))
    }

    static func differenceValue(_ logs: [SweatLog]) -> String {
        guard !logs.isEmpty else { return "—" }
        let difference = logs
            .map { Double($0.actualScore - $0.predictedStage) }
            .reduce(0, +) / Double(logs.count)
        if abs(difference) < 0.05 { return "0.0" }
        return String(format: "%+.1f", locale: korean, difference)
    }

    static func todayStatus(hasLog: Bool) -> String { hasLog ? logDone : logEmpty }

    static func notificationValue(_ profile: UserProfile) -> String {
        profile.wantsNotification ? notificationOn : notificationOff
    }

    static func locationValue(profile: UserProfile, placeName: String?, region: FallbackRegion?) -> String {
        if profile.usesCurrentLocation { return placeName ?? currentLocation }
        if let region { return HomeCopy.Location.name(region) }
        return regionNeeded
    }

    static func tagTitle(_ tag: SweatLogTag) -> String {
        switch tag {
        case .didNotDry: "땀이 안 말랐다"
        case .wetClothes: "옷이 젖었다"
        case .noShade: "그늘이 없었다"
        case .noRestArea: "쉴 곳이 없었다"
        }
    }

    static func predictionTitle(stage: SweatStage) -> String {
        "\(stage.rawValue)단계 · \(SweatCopy.of(stage).state)"
    }

    static func predictionMessage(stage: SweatStage, score: Int?) -> String {
        guard let score else { return chooseScorePrompt }
        if score > stage.rawValue {
            return "기록이 예측보다 높습니다. 다음 예측 기준을 조정하는 데 반영할게요."
        }
        if score < stage.rawValue {
            return "기록이 예측보다 낮습니다. 다음 예측 기준을 조정하는 데 반영할게요."
        }
        return "기록과 예측이 같아요. 현재 기준을 확인하는 데 반영할게요."
    }

    static func weatherUnavailableMessage() -> String { weatherNeeded }

    static func reportHeading(result: CalibrationResult, profile: UserProfile) -> String {
        guard result.hasEnoughSamples else { return waitingHeading }
        return abs(profile.calibrationOffset) > 0.000_001 ? adjustedHeading : analyzedHeading
    }

    static func reportBody(result: CalibrationResult, profile: UserProfile) -> String {
        guard result.hasEnoughSamples else {
            return "습도 \(Int(CalibrationEngine.humidityThreshold))% 이상인 날의 기록이 \(result.remainingSampleCount)건 더 필요해요. 충분히 모이면 개인 기준을 조정합니다."
        }

        let comparison: String
        switch result.meanStageDifference ?? 0 {
        case let value where value > 0.05:
            comparison = "체감이 예측보다 평균 \(oneDecimal(abs(value)))단계 높았어요."
        case let value where value < -0.05:
            comparison = "체감이 예측보다 평균 \(oneDecimal(abs(value)))단계 낮았어요."
        default:
            comparison = "체감과 예측의 평균 차이가 거의 없었어요."
        }
        return "고습도 기록에서 \(comparison) 현재 개인 보정은 \(signedTemperature(profile.calibrationOffset))입니다."
    }

    static func eligibleCount(_ count: Int) -> String { "\(count)일" }
    static func higherCount(_ count: Int) -> String { "\(count)일" }

    static func chartDay(_ date: Date) -> String {
        date.formatted(.dateTime.locale(korean).month(.twoDigits).day(.twoDigits))
    }

    static func chartSummary(_ logs: [SweatLog]) -> String {
        guard !logs.isEmpty else { return noRecentRecords }
        let values = logs.map {
            "\(chartDay($0.date)), 예측 \($0.predictedStage)단계, 직접 기록 \($0.actualScore)점"
        }
        return values.joined(separator: ". ")
    }

    static func dataSourceValue(_ serviceName: String?) -> String {
        serviceName ?? dataSourcePending
    }

    private static let korean = Locale(identifier: "ko_KR")

    private static func oneDecimal(_ value: Double) -> String {
        String(format: "%.1f", locale: korean, value)
    }

    private static func signedTemperature(_ value: Double) -> String {
        if abs(value) < 0.05 { return "0.0℃" }
        return String(format: "%+.1f℃", locale: korean, value)
    }
}
