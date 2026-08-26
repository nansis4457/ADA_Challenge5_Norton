import Foundation
import Testing
@testable import SweatFeatures

/// 날짜·시각 표기.
///
/// 시뮬레이터에서 한국어 기기인데도 `10:29 AM`·`Thu`가 나왔다. 번들에 한국어
/// 로컬라이제이션이 없어 `Locale.current`가 영어로 잡힌 것이다. 그래서 로케일을
/// 고정했고, 이 검사가 그 고정을 지킨다.
///
/// **로케일을 바꿔도 결과가 같아야 한다.** 기기 설정이 무엇이든 화면은 한국어다.
@Suite("날짜·시각 표기")
struct HomeFormatTests {

    /// 2026-08-21 01:29 UTC. 시간대에 따라 시각은 달라져도 언어는 달라지지 않는다.
    private let sample = Date(timeIntervalSince1970: 1_787_016_540)

    @Test("시각·요일에 영문이 섞이지 않는다")
    func formatsStayKorean() {
        for text in [HomeCopy.Format.time(sample),
                     HomeCopy.Format.hour(sample),
                     HomeCopy.Format.weekday(sample)] {
            let hasLatin = text.contains { $0.isASCII && $0.isLetter }
            #expect(!hasLatin, "영문이 섞였다: \"\(text)\"")
        }
    }

    @Test("관측 시각은 오전·오후로 읽힌다")
    func timeUsesKoreanMeridiem() {
        let text = HomeCopy.Format.time(sample)
        #expect(text.contains("오전") || text.contains("오후"), "\(text)")
    }

    @Test("요일은 한 글자다")
    func weekdayIsSingleCharacter() {
        let text = HomeCopy.Format.weekday(sample)
        #expect("월화수목금토일".contains(text), "\(text)")
    }

    @Test("시간별 예보 접근성 문구가 모든 열 이름을 포함한다")
    func hourlyAccessibilityLabelNamesEveryValue() {
        let text = HomeCopy.Forecast.hourLabel(
            "오전 10시",
            .sweaty,
            temperature: "27도",
            humidity: 70
        )

        for label in [HomeCopy.Forecast.stageColumn,
                      HomeCopy.Forecast.temperatureColumn,
                      HomeCopy.Forecast.humidityColumn] {
            #expect(text.contains(label), "\(label)이 빠졌다: \(text)")
        }
    }
}
