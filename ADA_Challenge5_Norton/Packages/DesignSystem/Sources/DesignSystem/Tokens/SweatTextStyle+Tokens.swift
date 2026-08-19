import SwiftUI

/// Figma 텍스트 스타일 하나에 대응하는 값.
///
/// SwiftUI에는 Figma의 line-height에 정확히 대응하는 API가 없다.
/// `lineSpacing`은 줄 사이에 **추가로** 넣는 여백이라, 폰트가 이미 가진
/// 줄 높이(SF Pro 기준 대략 `size × 1.2`)를 빼서 근사한다.
///
/// `lineSpacing`은 한 `Text` **안의 줄 사이**에만 들어간다. 한 줄짜리 텍스트에는
/// 아무 효과가 없으므로, 같은 문구라도 Figma보다 상자가 작다.
/// Selectable Card 기준 Figma 77.9pt 대 SwiftUI 70.7pt.
///
/// - Note: **의도된 차이다.** SwiftUI 기본 조판을 따르기로 결정했다 (2026-08-19).
///   Figma의 프레임 높이는 참고값이며 구현 목표가 아니다.
///   간격과 순서를 맞추고 높이는 콘텐츠가 정하게 둔다.
public struct SweatTextStyle: Sendable, Equatable {

    /// Figma에서의 이름. 디버깅과 카탈로그 표시에 쓴다.
    public let figmaName: String
    public let size: CGFloat
    public let weight: Font.Weight
    /// Figma line-height 비율. 130% → 1.3
    public let lineHeightRatio: CGFloat
    /// 자간 (pt). Figma의 % 값을 크기에 곱해 환산했다.
    public let tracking: CGFloat

    /// 고정 크기 폰트. **Dynamic Type을 따르지 않는다.**
    /// 화면에서는 이 값을 직접 쓰지 말고 `.sweatType(_:)`을 쓴다.
    public var font: Font { .system(size: size, weight: weight) }

    /// 폰트가 이미 가진 줄 높이를 뺀 나머지. 음수면 0.
    public var lineSpacing: CGFloat {
        max(0, size * (lineHeightRatio - 1.2))
    }
}

/// 폰트·자간·줄간격을 함께 적용하고 Dynamic Type에 맞춰 확대한다.
///
/// `Font.system(size:)`는 고정 크기라 **Dynamic Type을 따르지 않는다.**
/// 접근성 설정을 키워도 글자가 그대로면 헌법 IX 위반이므로,
/// `@ScaledMetric`으로 배율을 얻어 크기·자간·줄간격에 함께 곱한다.
/// 자간과 줄간격도 같이 곱해야 글자만 커지고 간격은 그대로인 어색한 상태를 피한다.
private struct SweatTypeModifier: ViewModifier {
    let style: SweatTextStyle

    /// 본문 기준 Dynamic Type 배율. 기본 크기에서 1.0이다.
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .font(.system(size: style.size * scale, weight: style.weight))
            .tracking(style.tracking * scale)
            .lineSpacing(style.lineSpacing * scale)
    }
}

extension View {
    /// 텍스트 스타일 하나를 폰트·자간·줄간격까지 함께 적용한다.
    ///
    /// Dynamic Type 배율이 자동으로 반영된다.
    public func sweatType(_ style: SweatTextStyle) -> some View {
        modifier(SweatTypeModifier(style: style))
    }
}

// Figma `Sweat App` 텍스트 스타일의 코드 미러 (헌법 VIII).
//
// 정적 멤버를 SweatTextStyle 위에 두어야 `.sweatType(.hero31)` 단축 문법이 동작한다.
// 별도 네임스페이스(SweatType)에 두면 타입이 달라 점 문법을 쓸 수 없다.
extension SweatTextStyle {
    /// `Hero/31` — SF Pro Semibold 31pt / 128% / -2%
    public static let hero31 = SweatTextStyle(
        figmaName: "Hero/31", size: 31, weight: .semibold,
        lineHeightRatio: 1.28, tracking: -0.62)
    /// `Title/30` — SF Pro Semibold 30pt / 125% / -2%
    public static let title30 = SweatTextStyle(
        figmaName: "Title/30", size: 30, weight: .semibold,
        lineHeightRatio: 1.25, tracking: -0.6)
    /// `Title/29` — SF Pro Semibold 29pt / 130% / -2%
    public static let title29 = SweatTextStyle(
        figmaName: "Title/29", size: 29, weight: .semibold,
        lineHeightRatio: 1.3, tracking: -0.58)
    /// `Title/28` — SF Pro Semibold 28pt / 130% / -2%
    public static let title28 = SweatTextStyle(
        figmaName: "Title/28", size: 28, weight: .semibold,
        lineHeightRatio: 1.3, tracking: -0.56)
    /// `Title/27` — SF Pro Semibold 27pt / 130% / -2%
    public static let title27 = SweatTextStyle(
        figmaName: "Title/27", size: 27, weight: .semibold,
        lineHeightRatio: 1.3, tracking: -0.54)
    /// `Heading/19` — SF Pro Semibold 19pt / 135% / -2%
    public static let heading19 = SweatTextStyle(
        figmaName: "Heading/19", size: 19, weight: .semibold,
        lineHeightRatio: 1.35, tracking: -0.38)
    /// `Stat/22` — SF Pro Semibold 22pt / 125% / -2%
    public static let stat22 = SweatTextStyle(
        figmaName: "Stat/22", size: 22, weight: .semibold,
        lineHeightRatio: 1.25, tracking: -0.44)
    /// `Stat/18` — SF Pro Semibold 18pt / 130% / -2%
    public static let stat18 = SweatTextStyle(
        figmaName: "Stat/18", size: 18, weight: .semibold,
        lineHeightRatio: 1.3, tracking: -0.36)
    /// `Option/17` — SF Pro Semibold 17pt / 130% / -2%
    public static let option17 = SweatTextStyle(
        figmaName: "Option/17", size: 17, weight: .semibold,
        lineHeightRatio: 1.3, tracking: -0.34)
    /// `Input/17` — SF Pro Regular 17pt / 130% / -2%
    public static let input17 = SweatTextStyle(
        figmaName: "Input/17", size: 17, weight: .regular,
        lineHeightRatio: 1.3, tracking: -0.34)
    /// `Button/16` — SF Pro Semibold 16pt / 125% / -2%
    public static let button16 = SweatTextStyle(
        figmaName: "Button/16", size: 16, weight: .semibold,
        lineHeightRatio: 1.25, tracking: -0.32)
    /// `Body Strong/16` — SF Pro Semibold 16pt / 140% / -2%
    public static let bodyStrong16 = SweatTextStyle(
        figmaName: "Body Strong/16", size: 16, weight: .semibold,
        lineHeightRatio: 1.4, tracking: -0.32)
    /// `Body/15` — SF Pro Regular 15pt / 160% / -2%
    public static let body15 = SweatTextStyle(
        figmaName: "Body/15", size: 15, weight: .regular,
        lineHeightRatio: 1.6, tracking: -0.3)
    /// `Body Strong/15` — SF Pro Semibold 15pt / 145% / -2%
    public static let bodyStrong15 = SweatTextStyle(
        figmaName: "Body Strong/15", size: 15, weight: .semibold,
        lineHeightRatio: 1.45, tracking: -0.3)
    /// `Chip/15` — SF Pro Regular 15pt / 130% / -2%
    public static let chip15 = SweatTextStyle(
        figmaName: "Chip/15", size: 15, weight: .regular,
        lineHeightRatio: 1.3, tracking: -0.3)
    /// `Body/14` — SF Pro Regular 14pt / 155% / -2%
    public static let body14 = SweatTextStyle(
        figmaName: "Body/14", size: 14, weight: .regular,
        lineHeightRatio: 1.55, tracking: -0.28)
    /// `Caption/13` — SF Pro Regular 13pt / 160% / -2%
    public static let caption13 = SweatTextStyle(
        figmaName: "Caption/13", size: 13, weight: .regular,
        lineHeightRatio: 1.6, tracking: -0.26)
    /// `Caption/12` — SF Pro Regular 12pt / 140% / -2%
    public static let caption12 = SweatTextStyle(
        figmaName: "Caption/12", size: 12, weight: .regular,
        lineHeightRatio: 1.4, tracking: -0.24)
    /// `Tab/10.5` — SF Pro Medium 10.5pt / 120% / 0%
    public static let tab105 = SweatTextStyle(
        figmaName: "Tab/10.5", size: 10.5, weight: .medium,
        lineHeightRatio: 1.2, tracking: 0)
    /// `Overline/11` — SF Pro Regular 11pt / 130% / 14%
    public static let overline11 = SweatTextStyle(
        figmaName: "Overline/11", size: 11, weight: .regular,
        lineHeightRatio: 1.3, tracking: 1.54)
    /// `Title/24 Bold` — SF Pro Bold 24pt / 120% / -3%
    public static let title24Bold = SweatTextStyle(
        figmaName: "Title/24 Bold", size: 24, weight: .bold,
        lineHeightRatio: 1.2, tracking: -0.72)
    /// `Title/22 Bold` — SF Pro Bold 22pt / 120% / -2%
    public static let title22Bold = SweatTextStyle(
        figmaName: "Title/22 Bold", size: 22, weight: .bold,
        lineHeightRatio: 1.2, tracking: -0.44)
    /// `Stat/20 Bold` — SF Pro Bold 20pt / 120% / -2%
    public static let stat20Bold = SweatTextStyle(
        figmaName: "Stat/20 Bold", size: 20, weight: .bold,
        lineHeightRatio: 1.2, tracking: -0.4)
    /// `Section/15` — SF Pro Semibold 15pt / 130% / -2%
    public static let section15 = SweatTextStyle(
        figmaName: "Section/15", size: 15, weight: .semibold,
        lineHeightRatio: 1.3, tracking: -0.3)
    /// `List/16` — SF Pro Medium 16pt / 130% / -2%
    public static let list16 = SweatTextStyle(
        figmaName: "List/16", size: 16, weight: .medium,
        lineHeightRatio: 1.3, tracking: -0.32)
    /// `List/12.5` — SF Pro Regular 12.5pt / 130% / -2%
    public static let list125 = SweatTextStyle(
        figmaName: "List/12.5", size: 12.5, weight: .regular,
        lineHeightRatio: 1.3, tracking: -0.25)
    /// `Body/13.5` — SF Pro Regular 13.5pt / 140% / -2%
    public static let body135 = SweatTextStyle(
        figmaName: "Body/13.5", size: 13.5, weight: .regular,
        lineHeightRatio: 1.4, tracking: -0.27)
    /// `Forecast/16` — SF Pro Semibold 16pt / 125% / -2%
    public static let forecast16 = SweatTextStyle(
        figmaName: "Forecast/16", size: 16, weight: .semibold,
        lineHeightRatio: 1.25, tracking: -0.32)
    /// `Label/14 Medium` — SF Pro Medium 14pt / 130% / -2%
    public static let label14Medium = SweatTextStyle(
        figmaName: "Label/14 Medium", size: 14, weight: .medium,
        lineHeightRatio: 1.3, tracking: -0.28)

    /// 카탈로그·테스트용 전체 목록.
    public static let all: [SweatTextStyle] = [
        hero31, title30, title29, title28,
        title27, heading19, stat22, stat18,
        option17, input17, button16, bodyStrong16,
        body15, bodyStrong15, chip15, body14,
        caption13, caption12, tab105, overline11,
        title24Bold, title22Bold, stat20Bold, section15,
        list16, list125, body135, forecast16,
        label14Medium,
    ]
}
