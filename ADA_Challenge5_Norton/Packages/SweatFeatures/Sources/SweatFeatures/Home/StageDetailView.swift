import SwiftUI
import DesignSystem
import SweatDomain
import WeatherData

/// 등급 상세 — 왜 이 단계인지.
public struct StageDetailView: View {

    private let observation: WeatherObservation
    private let stage: SweatStage
    private let attribution: WeatherAttributionInfo?
    private let onBack: () -> Void

    public init(
        observation: WeatherObservation,
        stage: SweatStage,
        attribution: WeatherAttributionInfo?,
        onBack: @escaping () -> Void
    ) {
        self.observation = observation
        self.stage = stage
        self.attribution = attribution
        self.onBack = onBack
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button(action: onBack) {
                    Text(DetailCopy.back)
                        .sweatType(.body14)
                        .foregroundStyle(Accent.deep)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(.rect)
                }

                Text(DetailCopy.heading(stage: stage))
                    .sweatType(.title28)
                    .foregroundStyle(Ink.n900)
                    .padding(.top, Space.x4)

                Text(DetailCopy.sub)
                    .sweatType(.body15)
                    .foregroundStyle(Ink.n600)
                    .padding(.top, Space.x2)

                VStack(alignment: .leading, spacing: Space.x5) {
                    ForEach(StageFactor.all(for: observation, stage: stage)) { factor in
                        FactorRow(factor: factor, stage: stage)
                    }
                }
                .padding(.top, Space.x6)

                Divider()
                    .overlay(Ink.n900.opacity(0.16))
                    .padding(.top, Space.x7)

                Text(DetailCopy.footnote)
                    .sweatType(.body14)
                    .foregroundStyle(Ink.n600)
                    .padding(.top, Space.x4)

                // 법적 요건이다. 날씨 값을 보여주는 화면에는 빠짐없이 둔다.
                if let attribution {
                    AttributionBlock(info: attribution)
                        .padding(.top, Space.x6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Space.gutter)
            .padding(.top, Space.x4)
            .padding(.bottom, Space.x7)
        }
        .frame(maxWidth: .infinity)
        .background(Surface.page)
    }
}

/// 요인 한 줄.
///
/// 막대가 있는 요인과 없는 요인이 섞인다. **풍속에는 막대가 없다** —
/// 여름철 체감온도 산식에 들어가지 않으므로, 막대를 그리면 기여하는 것처럼 보인다.
struct FactorRow: View {
    let factor: StageFactor
    let stage: SweatStage

    var body: some View {
        VStack(alignment: .leading, spacing: Space.x2) {
            HStack(alignment: .firstTextBaseline) {
                Text(DetailCopy.label(factor.kind))
                    .sweatType(.bodyStrong16)
                    .foregroundStyle(Ink.n900)
                Spacer()
                Text(factor.value)
                    .sweatType(.bodyStrong16)
                    .foregroundStyle(Ink.n900)
            }

            if let position = factor.position {
                GeometryReader { geometry in
                    Capsule().fill(Ink.n300)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(StageRole.outline(stage.rawValue))
                                .frame(width: max(4, geometry.size.width * position))
                        }
                }
                .frame(height: 5)
            }

            Text(factor.note)
                .sweatType(.body14)
                .foregroundStyle(Ink.n600)
        }
        .accessibilityElement(children: .combine)
    }
}
