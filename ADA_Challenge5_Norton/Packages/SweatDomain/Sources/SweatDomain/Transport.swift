import Foundation

/// 주로 쓰는 이동수단.
///
/// 실외 노출 계산과 휴식 추천에 쓰인다 (003).
/// 001에서는 저장만 하고 소비하지 않는다 — 나중에 다시 묻지 않기 위해서다.
///
/// - Important: `rawValue`는 저장 식별자다. **바꾸면 이미 저장된 설정이 깨진다.**
///   바꿔야 한다면 마이그레이션이 필요하다. 한글 라벨은 여기 없다 —
///   문구를 고칠 때마다 데이터가 깨지면 안 되기 때문이다.
public enum Transport: String, CaseIterable, Sendable, Codable {
    case walk
    case subway
    case bus
    case bike
}

/// 하루 야외 이동 시간.
///
/// `Transport`와 같은 이유로 코드값과 라벨을 분리한다.
public enum OutdoorDuration: String, CaseIterable, Sendable, Codable {
    /// 20분 이하
    case under20
    /// 20~40분
    case twentyToForty
    /// 40분 이상
    case over40
}
