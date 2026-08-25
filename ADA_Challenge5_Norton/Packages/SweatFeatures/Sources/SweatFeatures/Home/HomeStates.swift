import SwiftUI
import DesignSystem
import WeatherData

/// 위치 권한이 없을 때 지역을 고르게 한다 (R9).
struct RegionPicker: View {
    let reason: LocationOutcome
    let select: (FallbackRegion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Space.x2) {
            Text(title)
                .sweatType(.title27)
                .foregroundStyle(Ink.n900)
            Text(body_)
                .sweatType(.body15)
                .foregroundStyle(Ink.n600)

            Text(HomeCopy.Location.choosePrompt)
                .sweatType(.caption13)
                .foregroundStyle(Ink.n500)
                .padding(.top, Space.x4)

            FlowLayout(spacing: Space.x2) {
                ForEach(FallbackRegion.allCases, id: \.self) { region in
                    SweatChip(HomeCopy.Location.name(region), isOn: false) { select(region) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Space.gutter)
    }

    private var title: String {
        reason == .denied ? HomeCopy.Location.deniedTitle : HomeCopy.Location.unavailableTitle
    }
    private var body_: String {
        reason == .denied ? HomeCopy.Location.deniedBody : HomeCopy.Location.unavailableBody
    }
}

/// 날씨도 못 받고 보여줄 캐시도 없을 때.
struct FailureNotice: View {
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Space.x2) {
            Text(HomeCopy.Failure.title)
                .sweatType(.title27)
                .foregroundStyle(Ink.n900)
            Text(HomeCopy.Failure.body)
                .sweatType(.body15)
                .foregroundStyle(Ink.n600)
            SweatButton(HomeCopy.Failure.retry, action: retry)
                .padding(.top, Space.x3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Space.gutter)
    }
}

/// Apple Weather 출처 표기. **법적 요건이다.**
///
/// 로고를 누르면 데이터 출처 목록 페이지가 열린다.
///
/// - Important: `legalText`를 화면에 늘어놓지 않는다. 그 문구는 출처 목록 전문이라
///   화면 몇 개 분량이고, 홈 아래에 붙이면 사용자가 한참을 끌어내려야 한다.
///   **그 내용을 담은 페이지가 `legalPageURL`이고, 링크가 곧 요건을 만족한다.**
///   `legalText`는 링크를 열 수 없는 자리(위젯 등)를 위한 대체 수단이다.
struct AttributionBlock: View {
    let info: WeatherAttributionInfo
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Link(destination: info.legalPageURL) {
            AsyncImage(url: colorScheme == .dark ? info.markDarkURL : info.markLightURL) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                // 로고를 못 받아도 표기가 사라지면 안 된다.
                Text(info.serviceName)
                    .sweatType(.caption12)
                    .foregroundStyle(Ink.n500)
            }
            .frame(height: 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(info.serviceName)
        .accessibilityHint(HomeCopy.attributionHint)
    }
}
