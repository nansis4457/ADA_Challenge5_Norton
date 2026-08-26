import Foundation
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

    // MARK: 날짜·시각

    /// 날짜와 시각도 문구다. 그래서 뷰가 아니라 여기서 만든다.
    ///
    /// **로케일을 한국어로 고정한다.** 화면 문구가 전부 한국어인데 번들에는
    /// 한국어 로컬라이제이션이 없어서, `Locale.current`에 맡기면 한국어 기기에서도
    /// `10:29 AM`·`Thu`가 나와 `오늘`과 뒤섞인다.
    public enum Format {
        static let korean = Locale(identifier: "ko_KR")

        /// `오전 10:29` — 관측 시각.
        public static func time(_ date: Date) -> String {
            date.formatted(.dateTime.locale(korean).hour().minute())
        }

        /// `오전 10시` — 시간별 예보의 칸 제목.
        public static func hour(_ date: Date) -> String {
            date.formatted(.dateTime.locale(korean).hour())
        }

        /// `금` — 주간 예보의 요일.
        public static func weekday(_ date: Date) -> String {
            date.formatted(.dateTime.locale(korean).weekday(.abbreviated))
        }
    }

    // MARK: 위치 권한

    public enum Location {
        public static let deferredTitle = "현재 위치 사용을 미뤘어요"
        public static let deferredBody = "지역을 직접 고르면 시스템 권한 없이도 날씨를 볼 수 있어요."
        public static let deniedTitle = "위치를 알 수 없어요"
        public static let deniedBody = "지역을 직접 고르면 그 지역 날씨로 알려드릴게요."
        public static let unavailableTitle = "위치를 가져오지 못했어요"
        public static let unavailableBody = "잠시 후 다시 시도하거나 지역을 직접 골라보세요."
        public static let choosePrompt = "지역 선택"
        /// 역지오코딩이 실패해도 위치 헤더를 비우지 않는다.
        public static let current = "현재 위치"

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
        public static let dateColumn = "날짜"
        public static let stageColumn = "땀 단계"
        public static let temperatureColumn = "기온"
        public static let humidityColumn = "습도"
        public static let temperatureRangeColumn = "기온 범위"
        public static let lowColumn = "최저"
        public static let highColumn = "최고"

        public static func levelName(_ level: ForecastLevel) -> String {
            switch level {
            case .comfortable: "쾌적"
            case .moderate:    "보통"
            case .sweaty:      "땀 주의"
            case .hot:         "더움"
            }
        }

        /// 시간별 예보가 닿지 않는 날의 고지 (규칙 「추정치는 추정치로」).
        ///
        /// 먼 날짜의 단계는 시간별 최고 체감온도가 아니라 근삿값에서 나온다.
        /// 같은 모양의 얼굴로 나란히 놓으면 같은 근거로 보이므로 밝힌다.
        public static let estimatedNote = "먼 날짜의 단계는 근삿값이에요"

        /// VoiceOver가 읽는 주간 예보 한 줄.
        public static func dayLabel(_ weekday: String, _ level: ForecastLevel,
                                    low: Int, high: Int) -> String {
            "\(weekday), \(levelName(level)), 최저 \(low)도, 최고 \(high)도"
        }

        /// VoiceOver가 읽는 시간별 예보 한 칸.
        public static func hourLabel(_ time: String, _ level: ForecastLevel,
                                     temperature: String, humidity: Int) -> String {
            "\(time), 땀 단계 \(levelName(level)), 기온 \(temperature), 습도 \(humidity)%"
        }
    }

    /// VoiceOver가 읽는 마스코트.
    ///
    /// 마스코트는 장식이 아니다 — 단계를 말로 전달한다 (R14).
    public static func mascotLabel(stage: Int, state: String, headline: String) -> String {
        "\(stage)단계, \(state). \(headline)"
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
                      Forecast.estimatedNote,
                      Forecast.hourLabel("오전 8시", .sweaty, temperature: "27도", humidity: 70),
                      Forecast.dayLabel("금", .sweaty, low: 26, high: 33),
                      mascotLabel(stage: 3, state: "땀 불편 높음", headline: "오늘은 땀이 많이 날 수 있어요"),
                      Location.deferredTitle, Location.deferredBody,
                      Location.deniedTitle, Location.deniedBody,
                      Location.unavailableTitle, Location.unavailableBody, Location.choosePrompt,
                      Location.current,
                      Failure.title, Failure.body, Failure.retry,
                      Forecast.hourly, Forecast.weekly, Forecast.today,
                      Forecast.dateColumn, Forecast.stageColumn,
                      Forecast.temperatureColumn, Forecast.humidityColumn,
                      Forecast.temperatureRangeColumn,
                      Forecast.lowColumn, Forecast.highColumn,
                      Observation.temperature, Observation.humidity, Observation.apparent]
        result += FallbackRegion.allCases.map(Location.name)
        result += ForecastLevel.allCases.map(Forecast.levelName)
        return result
    }
}
