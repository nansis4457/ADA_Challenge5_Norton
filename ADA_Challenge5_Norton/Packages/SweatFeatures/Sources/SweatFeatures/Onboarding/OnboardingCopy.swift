import SweatDomain

/// 온보딩 화면의 모든 문구.
///
/// 규칙 「문구는 뷰 밖에」 — 뷰에 한글 문자열 리터럴을 두지 않는다.
///
/// 단계 관련 문구(`SweatCopy`)와는 별개다. 이쪽은 단계와 무관한 UI 텍스트다.
/// 원문은 `docs/specs/001-onboarding/spec.md` §6.
public enum OnboardingCopy {

    // MARK: 공통
    public static let next = "다음"
    /// 임시 화면의 편집 진입점. 005에서 마이페이지 메뉴로 대체된다.
    public static let editSensitivity = "땀 민감도 다시 설정"
    public static let editMovement = "이동 패턴 수정"
    public static let save = "저장"
    public static let backToProfile = "← 마이페이지"

    // MARK: 1단계 — 땀 민감도
    public enum Sensitivity {
        public static let step = "STEP 1 / 3"
        public static let heading = "땀은 얼마나\n많이 흘리는 편인가요?"
        public static let sub = "같은 날씨에서도 사람마다 느끼는 정도가 달라요. 등급과 추천을 조정하는 데 쓰입니다."

        public static func title(_ value: SweatDomain.Sensitivity) -> String {
            switch value {
            case .low:    "적은 편"
            case .normal: "보통"
            case .high:   "많은 편"
            }
        }

        public static func description(_ value: SweatDomain.Sensitivity) -> String {
            switch value {
            case .low:    "더워도 땀은 잘 안 나는 편이에요"
            case .normal: "남들과 비슷한 정도예요"
            case .high:   "조금만 더워도 땀이 많이 나요"
            }
        }
    }

    // MARK: 2단계 — 이동 패턴
    public enum Movement {
        public static let step = "STEP 2 / 3"
        public static let heading = "평소 이동은\n어떻게 하시나요?"
        public static let sub = "이동수단과 시간은 실외 노출 계산과 휴식 추천에 쓰입니다."
        public static let transportLabel = "주 이동수단"
        public static let durationLabel = "하루 야외 이동 시간"

        public static func title(_ value: Transport) -> String {
            switch value {
            case .walk:   "도보"
            case .subway: "지하철"
            case .bus:    "버스"
            case .bike:   "자전거"
            }
        }

        public static func title(_ value: OutdoorDuration) -> String {
            switch value {
            case .under20:       "20분 이하"
            case .twentyToForty: "20~40분"
            case .over40:        "40분 이상"
            }
        }
    }

    // MARK: 3단계 — 알림
    public enum Notification {
        public static let step = "STEP 3 / 3"
        public static let heading = "외출 전에\n알려드릴까요?"
        public static let sub = "땀 부담이 높은 날 아침, 그리고 이동 중 더위가 심해질 때만 보냅니다."
        public static let previewLabel = "미리보기"

        /// 알림 문구는 화면 문구와 별개로 관리한다.
        /// 원문은 개발가이드 §7 — Figma와 한 글자 다르며 개발가이드를 따른다.
        public static let previewTitle = "오늘은 땀이 많이 날 수 있어요"
        public static let previewBody = "체감온도가 높아요. 가능하면 그늘이 많은 길로 이동해보세요."

        public static let allow = "알림 허용하고 시작"
        public static let later = "나중에 할게요"
    }

    /// 린트·테스트용 전체 목록.
    public static var allStrings: [String] {
        var result = [next, save, backToProfile, editSensitivity, editMovement,
                      Sensitivity.step, Sensitivity.heading, Sensitivity.sub,
                      Movement.step, Movement.heading, Movement.sub,
                      Movement.transportLabel, Movement.durationLabel,
                      Notification.step, Notification.heading, Notification.sub,
                      Notification.previewLabel, Notification.previewTitle,
                      Notification.previewBody, Notification.allow, Notification.later]
        result += SweatDomain.Sensitivity.allCases.flatMap { [Sensitivity.title($0), Sensitivity.description($0)] }
        result += Transport.allCases.map(Movement.title)
        result += OutdoorDuration.allCases.map(Movement.title)
        return result
    }
}
