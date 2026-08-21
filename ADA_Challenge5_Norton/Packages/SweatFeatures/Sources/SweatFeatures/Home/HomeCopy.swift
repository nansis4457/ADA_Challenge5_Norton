import SweatDomain

/// 홈과 등급 상세의 문구.
///
/// 단계 관련 문구는 `SweatCopy`에서 온다. 여기는 단계와 무관한 UI 텍스트다.
public enum HomeCopy {

    /// 관측 시각 표시.
    ///
    /// `기상청`도 `관측`도 쓰지 않는다. WeatherKit은 관측소 실측이 아니라
    /// 모델 기반 값이라 「추정치는 추정치로」에 걸린다.
    public static func observedAt(_ time: String) -> String { "\(time) 기준" }

    /// 오래된 값을 보여줄 때 붙이는 배지.
    public static func staleBadge(minutes: Int) -> String { "\(minutes)분 전" }

    public static let detailLink = "더 알아보기 ›"
    /// 출처 로고를 눌렀을 때 무슨 일이 생기는지 VoiceOver에 알린다.
    public static let attributionHint = "날씨 데이터 출처 페이지 열기"

    // MARK: 위치 권한

    public enum Location {
        public static let deniedTitle = "위치를 알 수 없어요"
        public static let deniedBody = "지역을 직접 고르면 그 지역 날씨로 알려드릴게요."
        public static let unavailableTitle = "위치를 가져오지 못했어요"
        public static let unavailableBody = "잠시 후 다시 시도하거나 지역을 직접 골라보세요."
        public static let choosePrompt = "지역 선택"

        public static func name(_ region: FallbackRegion) -> String {
            switch region {
            case .seoul:   "서울"
            case .busan:   "부산"
            case .daegu:   "대구"
            case .incheon: "인천"
            case .gwangju: "광주"
            case .daejeon: "대전"
            case .pohang:  "포항"
            }
        }
    }

    // MARK: 예보

    public enum Forecast {
        public static let hourly = "시간별 예보"
        public static let weekly = "주간 예보"
        public static let today = "오늘"

        public static func levelName(_ level: ForecastLevel) -> String {
            switch level {
            case .comfortable: "쾌적"
            case .moderate:    "보통"
            case .sweaty:      "땀 주의"
            case .hot:         "더움"
            }
        }
    }

    // MARK: 실패

    public enum Failure {
        public static let title = "날씨를 가져오지 못했어요"
        public static let body = "네트워크를 확인하고 다시 시도해보세요."
        public static let retry = "다시 시도"
    }

    // MARK: 관측값

    public enum Observation {
        public static let temperature = "기온"
        public static let humidity = "습도"
        public static let apparent = "체감"
    }

    /// 린트·테스트용 전체 목록.
    public static var allStrings: [String] {
        var result = [detailLink, attributionHint, observedAt("오전 8:00"), staleBadge(minutes: 12),
                      Location.deniedTitle, Location.deniedBody,
                      Location.unavailableTitle, Location.unavailableBody, Location.choosePrompt,
                      Failure.title, Failure.body, Failure.retry,
                      Forecast.hourly, Forecast.weekly, Forecast.today,
                      Observation.temperature, Observation.humidity, Observation.apparent]
        result += FallbackRegion.allCases.map(Location.name)
        result += ForecastLevel.allCases.map(Forecast.levelName)
        return result
    }
}
