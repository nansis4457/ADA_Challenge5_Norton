import Foundation
import Testing
@testable import SweatFeatures

@Suite("온보딩 문구")
struct OnboardingCopyTests {

    /// 000에서 단계 문구에 적용한 것과 같은 검사를 온보딩 문구에도 건다.
    /// 규칙 「단정하지 않는다」는 화면을 가리지 않는다.
    static let forbidden: [(pattern: String, reason: String)] = [
        (#"땀[^\n]{0,12}\d+\s*(mL|ml|리터|L)"#, "땀 분비량 수치"),
        (#"\d+\s*배"#,                          "배수 표현"),
        (#"땀\s*(매우\s*)?많음"#,                "단정형 상태 표기"),
        (#"=\s*땀"#,                             "등식 표현"),
    ]

    @Test("금지 표현이 없다")
    func noForbiddenExpressions() throws {
        for (pattern, reason) in Self.forbidden {
            let regex = try NSRegularExpression(pattern: pattern)
            for text in OnboardingCopy.allStrings {
                let hits = regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
                #expect(hits == 0, "금지 표현(\(reason)): \"\(text)\"")
            }
        }
    }

    @Test("빈 문구가 없다")
    func noEmptyStrings() {
        for text in OnboardingCopy.allStrings {
            #expect(!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    @Test("알림 미리보기는 개발가이드 원문을 따른다")
    func notificationPreviewMatchesGuide() {
        // Figma는 "오늘은 땀 많이 날 수 있어요"로 한 글자 다르다.
        // 문구의 출처는 개발가이드이므로 그쪽이 맞다.
        #expect(OnboardingCopy.Notification.previewTitle == "오늘은 땀이 많이 날 수 있어요")
    }

    @Test("문구가 중복되지 않는다")
    func noDuplicateOptionLabels() {
        let labels = SweatFeatures.OnboardingCopy.allStrings
        let optionLabels = labels.filter { $0.count <= 8 }
        #expect(Set(optionLabels).count == optionLabels.count, "선택지 라벨이 겹칩니다")
    }
}
