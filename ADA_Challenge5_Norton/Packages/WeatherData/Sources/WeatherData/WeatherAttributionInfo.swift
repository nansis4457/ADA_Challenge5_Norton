import Foundation

/// 화면에 표시할 날씨 출처.
///
/// 값은 전부 WeatherKit이 준다. **문구도 이미지도 우리가 만들지 않는다** —
/// 지역화와 변경을 Apple이 관리한다. 표기는 법적 요건이다.
public struct WeatherAttributionInfo: Sendable, Equatable {
    public let serviceName: String
    /// 출처 목록 전문.
    ///
    /// **화면에 그대로 늘어놓지 않는다.** 화면 몇 개 분량이라 붙이면 한참을 끌어내려야 한다.
    /// 같은 내용이 `legalPageURL`에 있고 링크로 요건을 만족한다.
    /// 이 값은 링크를 열 수 없는 자리(위젯 등)를 위한 대체 수단이다.
    public let legalText: String
    public let legalPageURL: URL
    /// 라이트/다크에 맞는 로고. URL이라 받아와야 한다.
    public let markLightURL: URL
    public let markDarkURL: URL

    public init(
        serviceName: String, legalText: String, legalPageURL: URL,
        markLightURL: URL, markDarkURL: URL
    ) {
        self.serviceName = serviceName
        self.legalText = legalText
        self.legalPageURL = legalPageURL
        self.markLightURL = markLightURL
        self.markDarkURL = markDarkURL
    }
}
