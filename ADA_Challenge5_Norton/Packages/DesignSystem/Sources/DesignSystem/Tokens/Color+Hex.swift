import SwiftUI

extension Color {
    /// `0xRRGGBB` 정수로 색을 만든다.
    ///
    /// Figma가 hex로 값을 주므로 변환 없이 그대로 옮길 수 있다.
    /// 이 이니셜라이저는 토큰 정의에서만 쓴다 — 화면 코드가 직접 호출하면
    /// 헌법 VIII(디자인 토큰 강제) 위반이다.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255,
            opacity: 1
        )
    }
}
