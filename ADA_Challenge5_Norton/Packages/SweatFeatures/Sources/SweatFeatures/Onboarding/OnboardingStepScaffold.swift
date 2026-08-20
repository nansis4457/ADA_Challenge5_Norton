import SwiftUI
import DesignSystem

/// 온보딩 세 화면이 공유하는 뼈대.
///
/// 뒤로가기·단계 표시·제목·설명은 세 화면이 똑같다. 다른 건 가운데 내용과 CTA뿐이다.
struct OnboardingStepScaffold<Content: View, Actions: View>: View {

    let step: String
    let heading: String
    let sub: String
    var showsBack: Bool = false
    var onBack: () -> Void = {}
    @ViewBuilder let content: () -> Content
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if showsBack {
                    Button(action: onBack) {
                        Text(OnboardingCopy.backToProfile)
                            .sweatType(.body14)
                            .foregroundStyle(Accent.deep)
                    }
                    .padding(.bottom, Space.x3 + 2)
                }

                Text(step)
                    .sweatType(.overline11)
                    .foregroundStyle(Ink.n500)

                Text(heading)
                    .sweatType(.title30)
                    .foregroundStyle(Ink.n900)
                    .padding(.top, Space.x3)

                Text(sub)
                    .sweatType(.body15)
                    .foregroundStyle(Ink.n600)
                    .padding(.top, Space.x2)

                content()
                    .padding(.top, Space.x6)

                actions()
                    .padding(.top, Space.x7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Space.gutter)
            .padding(.top, Space.x7 * 2)
            .padding(.bottom, Space.x7)
        }
        .background(Surface.page)
    }
}
