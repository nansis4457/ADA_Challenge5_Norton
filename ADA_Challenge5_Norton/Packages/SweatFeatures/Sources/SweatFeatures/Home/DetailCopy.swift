import SweatDomain

/// 등급 상세 화면의 문구.
public enum DetailCopy {

    public static let back = "← 홈"
    public static func heading(stage: SweatStage) -> String {
        "등급 \(stage.rawValue)은\n이렇게 나왔어요"
    }
    public static let sub = "체감온도가 단계를 정하고, 습도와 풍속은 설명과 추천을 고르는 데 쓰입니다."

    static func label(_ kind: StageFactor.Kind) -> String {
        switch kind {
        case .apparentTemperature: "체감온도"
        case .humidity:            "습도"
        case .wind:                "풍속"
        }
    }

    // MARK: 요인별 설명

    /// 체감온도만이 단계를 정한다.
    static func apparentNote(stage: SweatStage) -> String {
        "단계를 정하는 값이에요. \(stage.rangeLabel) 구간이라 \(stage.rawValue)단계입니다."
    }

    /// 습도는 **체감온도 계산에 들어간다.** 단계에 한 번 더 더하지는 않는다.
    static let humidityNote =
        "체감온도를 구할 때 이미 들어간 값이에요. 습도가 높으면 땀이 잘 마르지 않아 체감온도가 올라갑니다."

    /// 풍속은 여름철 체감온도 산식에 **들어가지 않는다.**
    /// 막대를 그리면 체감온도에 기여하는 것처럼 보이므로 값과 설명만 둔다.
    static let windNote =
        "체감온도 계산에는 들어가지 않아요. 바람이 약하면 그늘과 실내가 있는 길을 먼저 추천합니다."

    public static let footnote =
        "체감온도는 땀의 양을 정하는 값이 아니라 땀을 느끼거나 땀으로 불편할 가능성을 전달하는 기준으로 씁니다. "
        + "구간은 한국인 열감 연구와 기상청 폭염특보 기준을 참고한 설계안입니다."

    public static var allStrings: [String] {
        [back, sub, humidityNote, windNote, footnote,
         heading(stage: .three), apparentNote(stage: .three)]
        + StageFactor.Kind.allCases.map(label)
    }
}
