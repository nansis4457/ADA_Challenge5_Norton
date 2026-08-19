import CoreGraphics

/// 간격 토큰. Figma `space/*`.
public enum Space {
    /// `space/1`
    public static let x1: CGFloat = 4
    /// `space/2`
    public static let x2: CGFloat = 8
    /// `space/3`
    public static let x3: CGFloat = 12
    /// `space/4`
    public static let x4: CGFloat = 16
    /// `space/5`
    public static let x5: CGFloat = 22
    /// `space/6`
    public static let x6: CGFloat = 26
    /// `space/7`
    public static let x7: CGFloat = 32
    /// `screen/gutter` — 화면 좌우 여백
    public static let gutter: CGFloat = 22
}

/// 모서리 반경 토큰. Figma `radius/*`.
public enum Radius {
    /// `radius/sm`
    public static let sm: CGFloat = 2
    /// `radius/md`
    public static let md: CGFloat = 10
    /// `radius/lg`
    public static let lg: CGFloat = 12
    /// `radius/xl`
    public static let xl: CGFloat = 14
    /// `radius/pill`
    public static let pill: CGFloat = 999
}
