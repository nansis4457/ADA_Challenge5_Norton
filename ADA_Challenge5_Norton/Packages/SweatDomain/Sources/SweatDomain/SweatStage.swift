import Foundation

/// 땀 불편 단계 — 1(낮음) ~ 6(안전 경고 중심).
///
/// 이 타입은 **체감온도 구간의 유일한 출처**다 (규칙 「경계값은 한 곳에」).
/// 경계값을 바꿔야 하면 `boundaries` 한 곳만 고친다. 다른 파일에
/// 28·33·35·36·43 이 리터럴로 등장하면 규칙 위반이다.
///
/// 사용자에게 보이는 문구는 여기에 없다. 멘트·추천·구간 라벨은 모두
/// `SweatCopy`가 담당한다 (규칙 「문구는 뷰 밖에」 — 로직과 문구의 분리).
public enum SweatStage: Int, CaseIterable, Sendable, Comparable {
    case one = 1
    case two
    case three
    case four
    case five
    case six

    // MARK: - 구간 정의

    /// 단계를 가르는 체감온도 경계 (℃), 오름차순.
    ///
    /// **이 배열이 구간 정의의 전부다.**
    /// - `28 / 36 / 43` — 한국인 열감 연구의 열감 경계값
    /// - `33 / 35` — 국내 폭염특보 기준
    ///
    /// 확정된 의학적 기준이 아니라 **설계 후보**다 (규칙 「경계값은 한 곳에」).
    /// 근거 재검토는 `땀_날씨앱_구간화_UI_멘트_개발가이드.md` §10 참조.
    public static let boundaries: [Double] = [28, 33, 35, 36, 43]

    /// 이 단계에 해당하는 체감온도 범위 (℃).
    ///
    /// 하한은 포함, 상한은 제외한다. 양 끝 단계는 무한대로 열려 있다.
    /// 예) `.three` → `33.0 ..< 35.0`, `.six` → `43.0 ..< ∞`
    public var range: Range<Double> {
        let i = index
        let lower = i == 0 ? -Double.infinity : Self.boundaries[i - 1]
        let upper = i == Self.boundaries.count ? Double.infinity : Self.boundaries[i]
        return lower ..< upper
    }

    /// 주어진 체감온도가 속하는 단계.
    ///
    /// 개인 민감도·보정은 반영하지 않는다. 그건 `SweatStageEngine`의 몫이다.
    /// `NaN`이 들어오면 어떤 비교도 참이 아니므로 가장 낮은 단계를 반환한다.
    public static func containing(_ apparentTemperature: Double) -> SweatStage {
        let crossed = boundaries.count { apparentTemperature >= $0 }
        return SweatStage(rawValue: crossed + 1) ?? .six
    }

    // MARK: - 파생 속성

    /// 안전 안내가 필요한 단계인가.
    ///
    /// 5·6단계는 땀 불편을 넘어 온열질환 위험 구간이다. 이 단계의 문구는
    /// 완곡어법 제약(규칙 「단정하지 않는다」)에서 예외이며 단정형을 쓴다.
    public var requiresSafetyGuidance: Bool { self >= .five }

    /// `boundaries` 기준의 0-based 인덱스.
    private var index: Int { rawValue - 1 }

    // MARK: - Comparable

    public static func < (lhs: SweatStage, rhs: SweatStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
