import SwiftUI
import DesignSystem
import SweatDomain
import SweatPersistence

/// 온보딩 결과를 확인하기 위한 임시 화면.
///
/// **002에서 진짜 홈으로 교체된다.** 지금은 날씨를 가져올 수단이 없어
/// 고정된 체감온도로 단계를 계산한다. 이 화면의 목적은 단 하나 —
/// 고른 민감도가 등급 계산에 실제로 반영되는지 눈으로 확인하는 것이다.
public struct StagePlaceholderView: View {

    /// 날씨 연동 전까지 쓰는 고정값. 002에서 실제 관측값으로 대체된다.
    private static let sampleApparentTemperature: Double = 34.2

    private let profile: UserProfile
    private let onEditSensitivity: () -> Void
    private let onEditMovement: () -> Void

    public init(
        profile: UserProfile,
        onEditSensitivity: @escaping () -> Void,
        onEditMovement: @escaping () -> Void
    ) {
        self.profile = profile
        self.onEditSensitivity = onEditSensitivity
        self.onEditMovement = onEditMovement
    }

    private var stage: SweatStage {
        SweatStageEngine.stage(
            apparentTemperature: Self.sampleApparentTemperature,
            sensitivity: profile.sensitivity,
            calibration: profile.calibrationOffset
        )
    }

    private var copy: SweatCopy { SweatCopy.of(stage) }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.x5) {
                summary
                actions
                editEntry
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Space.gutter)
            .padding(.vertical, Space.x7)
        }
        .background(Surface.page)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: Space.x2) {
            Text(copy.state)
                .sweatType(.overline11)
                .foregroundStyle(Ink.n500)
            Text(copy.headline)
                .sweatType(.hero31)
                .foregroundStyle(Ink.n900)
            Text(copy.summary)
                .sweatType(.body15)
                .foregroundStyle(Ink.n600)
            Text(stage.rangeLabel)
                .sweatType(.caption13)
                .foregroundStyle(StageColor.top(stage.rawValue))
        }
        // 단계는 색과 그림이 아니라 말로도 전달되어야 한다.
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stage.rawValue)단계, \(copy.state)")
    }

    private var actions: some View {
        VStack(alignment: .leading, spacing: Space.x2) {
            ForEach(Array(copy.actions.enumerated()), id: \.offset) { _, action in
                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .sweatType(.bodyStrong16)
                        .foregroundStyle(Ink.n900)
                    Text(action.body)
                        .sweatType(.body14)
                        .foregroundStyle(Ink.n600)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Space.x4)
                .background(Surface.card, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                .accessibilityElement(children: .combine)
            }
        }
    }

    /// 마이페이지(005)가 생기기 전까지 편집 경로를 검증하는 임시 진입점.
    private var editEntry: some View {
        VStack(spacing: Space.x2) {
            SweatButton(OnboardingCopy.editSensitivity, style: .ghost, action: onEditSensitivity)
            SweatButton(OnboardingCopy.editMovement, style: .ghost, action: onEditMovement)
        }
    }
}
