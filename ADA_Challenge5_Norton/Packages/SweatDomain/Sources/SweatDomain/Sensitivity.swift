import Foundation

/// 사용자가 온보딩에서 고르는 땀 민감도.
///
/// 같은 날씨라도 사람마다 느끼는 정도가 다르다. 이 값은 체감온도에
/// 오프셋을 더해 단계 산출을 개인화한다.
///
/// 한글 라벨("적은 편" 등)은 여기에 없다. `SweatCopy` 담당이다 (헌법 II).
/// `rawValue`는 영속화용 식별자이며 사용자에게 보이지 않는다.
public enum Sensitivity: String, CaseIterable, Sendable, Codable {
    /// 더워도 땀은 잘 안 나는 편
    case low
    /// 남들과 비슷한 정도
    case normal
    /// 조금만 더워도 땀이 많이 나는 편
    case high

    /// 체감온도에 더할 보정값 (℃).
    ///
    /// 프로토타입(`sweat-app.dc.html`)의 ±1.2℃를 그대로 따른다.
    /// 근거는 경험적 설계값이며, 구간 경계와 마찬가지로 잠정치다.
    public var offset: Double {
        switch self {
        case .low:    -1.2
        case .normal:  0
        case .high:    1.2
        }
    }
}
