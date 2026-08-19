import SwiftUI

// Figma `Sweat App` 변수 컬렉션의 코드 미러 (헌법 VIII).
// 값을 고칠 때는 Figma를 먼저 고치고 README.md의 매핑 표를 함께 갱신한다.

/// 무채색 잉크. 숫자가 클수록 진하다.
public enum Ink {
    /// `ink/200` — #E2E0E0
    public static let n200 = Color(hex: 0xE2E0E0)
    /// `ink/300` — #D7D3D3
    public static let n300 = Color(hex: 0xD7D3D3)
    /// `ink/400` — #9B9797
    public static let n400 = Color(hex: 0x9B9797)
    /// `ink/500` — #7D7979
    public static let n500 = Color(hex: 0x7D7979)
    /// `ink/600` — #605D5D
    public static let n600 = Color(hex: 0x605D5D)
    /// `ink/700` — #444141
    public static let n700 = Color(hex: 0x444141)
    /// `ink/900` — #201E1D
    public static let n900 = Color(hex: 0x201E1D)
}

/// 주 강조색(시안). 진행·선택·링크.
public enum Accent {
    /// `accent/base` — #0088B0
    public static let base = Color(hex: 0x0088B0)
    /// `accent/deep` — #006786
    public static let deep = Color(hex: 0x006786)
    /// `accent/light` — #38A6CF
    public static let light = Color(hex: 0x38A6CF)
}

/// 보조 강조색(마젠타). 더위·경고·실외 노출.
public enum Magenta {
    /// `magenta/base` — #D6006C
    public static let base = Color(hex: 0xD6006C)
    /// `magenta/dark` — #D82071
    public static let dark = Color(hex: 0xD82071)
    /// `magenta/deep` — #AA0B56
    public static let deep = Color(hex: 0xAA0B56)
    /// `magenta/light` — #FF90B1
    public static let light = Color(hex: 0xFF90B1)
    /// `magenta/mid` — #FF458E
    public static let mid = Color(hex: 0xFF458E)
}

/// 배경과 면.
public enum Surface {
    /// `bg/accent-tint` — #E9F8FF
    public static let accentTint = Color(hex: 0xE9F8FF)
    /// `bg/accent-wash` — #F0F8FB
    public static let accentWash = Color(hex: 0xF0F8FB)
    /// `bg/magenta-tint` — #FFF1F4
    public static let magentaTint = Color(hex: 0xFFF1F4)
    /// `bg/page` — #F3F2F2
    public static let page = Color(hex: 0xF3F2F2)
    /// `bg/surface` — #FFFFFF
    public static let card = Color(hex: 0xFFFFFF)
}

/// 테두리. SwiftUI `Border`와 겹치지 않도록 접미사를 붙였다.
public enum BorderColor {
    /// `border/accent` — #0088B0
    public static let accent = Color(hex: 0x0088B0)
    /// `border/subtle` — #D0CCCB
    public static let subtle = Color(hex: 0xD0CCCB)
}

/// 채워진 면 위에 얹는 색.
public enum OnColor {
    /// `on/accent` — #FFFFFF
    public static let accent = Color(hex: 0xFFFFFF)
}

/// 땀 단계별 마스코트 색. 1(시원) → 6(뜨거움).
///
/// `body`는 몸통, `top`은 위쪽 하이라이트다.
/// 범위를 벗어난 단계는 가장 가까운 끝으로 잘린다.
public enum StageColor {

    /// `stage/N-body`
    public static func body(_ stage: Int) -> Color {
        switch min(max(stage, 1), 6) {
        case 1: Color(hex: 0xE9F8FF)
        case 2: Color(hex: 0xCBEEFF)
        case 3: Color(hex: 0xFFDEE6)
        case 4: Color(hex: 0xFFC0D0)
        case 5: Color(hex: 0xFF90B1)
        case 6: Color(hex: 0xFF458E)
        default: Color(hex: 0xFF458E)
        }
    }

    /// `stage/N-top`
    public static func top(_ stage: Int) -> Color {
        switch min(max(stage, 1), 6) {
        case 1: Color(hex: 0xCBEEFF)
        case 2: Color(hex: 0x99E0FF)
        case 3: Color(hex: 0xFFC0D0)
        case 4: Color(hex: 0xFF90B1)
        case 5: Color(hex: 0xFF458E)
        case 6: Color(hex: 0xD82071)
        default: Color(hex: 0xD82071)
        }
    }

}
