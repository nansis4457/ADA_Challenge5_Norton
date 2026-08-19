import Foundation

/// 단계별로 사용자에게 보여줄 문구.
///
/// 이 타입은 **앱의 모든 단계 관련 한글 문구의 유일한 출처**다 (헌법 II).
/// 뷰에 문자열 리터럴이 등장하면 위반이다.
///
/// 원문은 `땀_날씨앱_구간화_UI_멘트_개발가이드.md` §2·§5.
/// 문구를 고칠 때는 그 문서를 먼저 고친다.
public struct SweatCopy: Sendable, Equatable {

    /// 상태 라벨. 예) "땀 불편 높음"
    public let state: String

    /// 화면 중앙의 메인 멘트. 예) "오늘은 땀이 많이 날 수 있어요"
    public let headline: String

    /// 메인 멘트를 받는 한 문장.
    public let summary: String

    /// 이 단계에서 권하는 행동. 우선순위 순.
    public let actions: [Action]

    /// 사용자가 할 수 있는 구체적 행동.
    public struct Action: Sendable, Equatable {

        /// 개발가이드 §5의 다섯 갈래.
        public enum Category: String, Sendable, CaseIterable {
            case hydration  // ① 수분
            case clothing   // ② 복장
            case route      // ③ 경로
            case rest       // ④ 휴식
            case safety     // ⑤ 안전
        }

        public let category: Category
        public let title: String
        public let body: String

        public init(_ category: Category, _ title: String, _ body: String) {
            self.category = category
            self.title = title
            self.body = body
        }
    }
}

// MARK: - 단계별 문구

extension SweatCopy {

    /// 해당 단계의 문구.
    public static func of(_ stage: SweatStage) -> SweatCopy {
        switch stage {
        case .one:
            SweatCopy(
                state: "땀 부담 낮음",
                headline: "오늘은 땀 걱정이 적어요",
                summary: "오늘은 비교적 쾌적하게 이동할 수 있어요.",
                actions: [
                    .init(.hydration, "가볍게 준비해요", "평소처럼 이동하고 필요하면 물을 챙겨요."),
                    .init(.clothing, "통풍이 잘 되는 옷을 선택해요", "가벼운 옷차림이면 충분해요."),
                ])

        case .two:
            SweatCopy(
                state: "땀이 날 수 있음",
                headline: "슬슬 땀이 날 수 있어요",
                summary: "활동량이 많다면 땀을 느낄 수 있어요.",
                actions: [
                    .init(.hydration, "물을 미리 챙겨요", "이동 전에 물을 준비해요."),
                    .init(.clothing, "통풍이 잘 되는 옷을 입어요", "흡습·통풍이 좋은 옷을 선택해요."),
                    .init(.route, "그늘이 있는 길을 골라요", "가능하면 직사광선을 피해서 이동해요."),
                ])

        case .three:
            SweatCopy(
                state: "땀 불편 높음",
                headline: "오늘은 땀이 많이 날 수 있어요",
                summary: "높은 체감온도로 땀과 더위가 불편하게 느껴질 수 있어요.",
                actions: [
                    .init(.route, "더위를 덜 느끼는 길로 이동해요", "그늘·실내·냉방 공간을 거치는 경로를 우선 고려해요."),
                    .init(.hydration, "물을 가까이 준비해요", "이동 전 물을 챙기고 필요하면 휴식해요."),
                    .init(.clothing, "땀이 잘 마르는 옷을 선택해요", "통풍·흡습이 좋은 옷을 고려해요."),
                ])

        case .four:
            SweatCopy(
                state: "땀·더위 부담 매우 높음",
                headline: "오늘은 더위와 땀에 주의하세요",
                summary: "가능하면 더운 시간대의 야외 이동을 줄여보세요.",
                actions: [
                    .init(.route, "가능하면 더위를 피해서 이동해요", "외출 시간을 늦추거나 실내·그늘 경로를 우선 선택해요."),
                    .init(.rest, "중간에 쉬어가요", "무더운 야외 구간이 길다면 냉방·그늘 공간에서 쉬어가요."),
                    .init(.safety, "폭염에 주의해요", "한낮 야외 활동을 줄이고 이상 증상이 있으면 즉시 쉬어요."),
                ])

        case .five:
            SweatCopy(
                state: "매우 높은 땀·더위 부담",
                headline: "오늘은 더위가 매우 강해요",
                summary: "가능하면 시원한 곳에서 이동하고 중간에 쉬어가세요.",
                actions: [
                    .init(.route, "실내·그늘 경로만 이용해요", "야외 구간이 긴 경로는 피해요."),
                    .init(.rest, "중간에 반드시 쉬어가요", "무더위쉼터와 냉방 공간을 경유해요."),
                    .init(.safety, "폭염 안전 안내를 확인해요", "땀 단계와 별도로 안전을 우선하세요."),
                ])

        case .six:
            SweatCopy(
                state: "안전 경고 중심",
                headline: "오늘은 야외 활동을 줄여주세요",
                summary: "매우 높은 열환경이므로 안전을 우선하세요.",
                actions: [
                    .init(.safety, "외출을 최소화해요", "꼭 필요한 이동만 실내 경로로 계획해요."),
                    .init(.safety, "이상 증상이 있으면 즉시 쉬어요", "어지럽거나 메스꺼우면 도움을 요청하세요."),
                ])
        }
    }
}

// MARK: - 구간 라벨

extension SweatStage {

    /// 화면에 표시할 구간 라벨. 예) "< 28℃", "33~35℃", "≥ 43℃"
    ///
    /// `boundaries`에서 생성한다. 숫자를 문자열로 다시 적지 않는다 (헌법 V).
    public var rangeLabel: String {
        let lower = range.lowerBound
        let upper = range.upperBound
        return switch (lower.isFinite, upper.isFinite) {
        case (false, true):  "< \(Self.format(upper))℃"
        case (true, false):  "≥ \(Self.format(lower))℃"
        default:             "\(Self.format(lower))~\(Self.format(upper))℃"
        }
    }

    private static func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(value)
    }
}
