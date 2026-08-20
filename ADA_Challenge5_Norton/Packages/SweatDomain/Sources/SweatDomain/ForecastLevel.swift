import Foundation

/// 예보에 표시하는 4구간.
///
/// 시간별·주간 예보는 칸이 작아 6단계를 그대로 보여줄 수 없다.
/// Figma `Weather Face`의 Level 1~4에 대응한다.
///
/// **단계 계산 자체는 홈과 같은 엔진을 쓴다.** 여기서 다시 계산하지 않고
/// 이미 나온 `SweatStage`를 표시용으로 묶기만 한다. 홈과 예보의 단계가
/// 어긋나면 사용자가 먼저 알아챈다.
public enum ForecastLevel: Int, CaseIterable, Sendable, Comparable {
    case comfortable = 1
    case moderate
    case sweaty
    case hot

    /// 단계를 표시용 구간으로 묶는다.
    ///
    /// 4단계 이상은 칸 안에서 구분해 봐야 의미가 없어 하나로 합친다.
    /// 자세한 차이는 홈의 멘트가 전달한다.
    public init(_ stage: SweatStage) {
        self = switch stage {
        case .one:   .comfortable
        case .two:   .moderate
        case .three: .sweaty
        case .four, .five, .six: .hot
        }
    }

    public static func < (lhs: ForecastLevel, rhs: ForecastLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
