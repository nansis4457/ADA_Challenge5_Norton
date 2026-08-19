import Foundation
import Testing
@testable import SweatDomain

@Suite("SweatCopy — 문구와 UX Writing 제약")
struct SweatCopyLintTests {

    /// 한 단계의 모든 문구를 한 줄씩.
    static func strings(of stage: SweatStage) -> [(label: String, text: String)] {
        let copy = SweatCopy.of(stage)
        var result: [(String, String)] = [
            ("state", copy.state),
            ("headline", copy.headline),
            ("summary", copy.summary),
        ]
        for (i, action) in copy.actions.enumerated() {
            result.append(("actions[\(i)].title", action.title))
            result.append(("actions[\(i)].body", action.body))
        }
        return result
    }

    // MARK: - 헌법 III · 금지 표현

    /// 이 앱은 땀의 **양**을 예측하지 않는다.
    /// 분비량 수치·배수 표현·단정형 등식은 근거 없는 과장이다.
    ///
    /// 안전 문구는 완곡어법 예외지만, 이 금지 패턴은 예외 없이 전 단계에 적용된다.
    /// "단정하지 마라"가 아니라 "없는 과학을 지어내지 마라"이기 때문이다.
    /// - Note: 분비량 패턴은 **"땀" 근처의 부피 수치**만 잡는다.
    ///   `물 500mL를 챙기면 좋아요`는 정상 문구이므로 부피 단위만으로는 판정할 수 없다.
    ///   단어 경계(`\b`)는 쓰지 않는다 — 한글이 단어 문자로 취급되어
    ///   `500mL가`의 `L`과 `가` 사이에 경계가 생기지 않는다. (역검증에서 발견)
    static let forbidden: [(pattern: String, reason: String)] = [
        (#"땀[^\n]{0,12}\d+\s*(mL|ml|리터|L)"#, "땀 분비량 수치"),
        (#"\d+\s*배"#,                          "배수 표현"),
        (#"땀\s*(매우\s*)?많음"#,                "단정형 상태 표기"),
        (#"=\s*땀"#,                             "등식 표현"),
    ]

    @Test("금지 표현이 없다", arguments: SweatStage.allCases)
    func noForbiddenExpressions(stage: SweatStage) throws {
        for (pattern, reason) in Self.forbidden {
            let regex = try NSRegularExpression(pattern: pattern)
            for (label, text) in Self.strings(of: stage) {
                let hits = regex.numberOfMatches(
                    in: text, range: NSRange(text.startIndex..., in: text))
                #expect(
                    hits == 0,
                    """
                    \(stage) \(label)에 금지 표현(\(reason))이 있습니다: "\(text)"
                    헌법 III — 이 앱은 땀의 양을 예측하지 않습니다.
                    """
                )
            }
        }
    }

    // MARK: - 문구 완결성

    @Test("모든 단계에 문구가 채워져 있다", arguments: SweatStage.allCases)
    func copyIsComplete(stage: SweatStage) {
        let copy = SweatCopy.of(stage)
        #expect(!copy.state.isEmpty)
        #expect(!copy.headline.isEmpty)
        #expect(!copy.summary.isEmpty)
        #expect(!copy.actions.isEmpty, "\(stage)에 추천 행동이 없습니다")
        for (label, text) in Self.strings(of: stage) {
            #expect(!text.trimmingCharacters(in: .whitespaces).isEmpty,
                    "\(stage) \(label)이 비어 있습니다")
        }
    }

    @Test("단계마다 문구가 서로 다르다")
    func copyIsDistinct() {
        let headlines = SweatStage.allCases.map { SweatCopy.of($0).headline }
        #expect(Set(headlines).count == headlines.count, "중복된 메인 멘트가 있습니다")
        let states = SweatStage.allCases.map { SweatCopy.of($0).state }
        #expect(Set(states).count == states.count, "중복된 상태 라벨이 있습니다")
    }

    // MARK: - 안전 안내

    /// 개발가이드 §5 ⑤ — 폭염 기준에 해당하면 안전 안내를 별도로 보여준다.
    @Test("안전 단계에는 안전 카테고리 행동이 있다")
    func safetyStagesHaveSafetyAction() {
        for stage in SweatStage.allCases where stage.requiresSafetyGuidance {
            let categories = SweatCopy.of(stage).actions.map(\.category)
            #expect(categories.contains(.safety), "\(stage)에 안전 안내가 없습니다")
        }
    }

    @Test("낮은 단계는 안전 경고로 겁주지 않는다")
    func lowStagesAvoidSafetyNoise() {
        for stage in SweatStage.allCases where !stage.requiresSafetyGuidance && stage < .four {
            let categories = SweatCopy.of(stage).actions.map(\.category)
            #expect(!categories.contains(.safety), "\(stage)에 불필요한 안전 경고가 있습니다")
        }
    }

    // MARK: - 구간 라벨

    /// 라벨은 `boundaries`에서 생성된다. 숫자를 손으로 다시 적으면 헌법 V 위반이다.
    @Test("구간 라벨이 경계값과 일치한다")
    func rangeLabelMatchesBoundaries() {
        #expect(SweatStage.one.rangeLabel == "< 28℃")
        #expect(SweatStage.three.rangeLabel == "33~35℃")
        #expect(SweatStage.six.rangeLabel == "≥ 43℃")

        for stage in SweatStage.allCases {
            if stage.range.lowerBound.isFinite {
                #expect(stage.rangeLabel.contains(String(Int(stage.range.lowerBound))))
            }
        }
    }
}
