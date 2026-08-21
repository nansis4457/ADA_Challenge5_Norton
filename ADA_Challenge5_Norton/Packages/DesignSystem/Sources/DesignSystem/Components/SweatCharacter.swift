import SwiftUI

/// 단계별 마스코트. Figma `Sweat Character`.
///
/// 이미지로 굽지 않고 `Path`로 그린다. 단계가 바뀔 때 색·표정·땀방울이
/// 이어서 변해야 하는데, 이미지를 갈아끼우면 툭 끊긴다.
public struct SweatCharacter: View {

    private let stage: Int
    private let size: CGFloat

    /// - Parameter stage: 1~6. 범위를 벗어나면 가장 가까운 끝으로 잘린다.
    public init(stage: Int, size: CGFloat = 272) {
        self.stage = min(max(stage, 1), 6)
        self.size = size
    }

    /// Figma 원본 좌표계. 모든 위치를 이 안에서 잡고 마지막에 비율로 늘린다.
    private static let canvas = CGSize(width: 220, height: 240)

    private var scale: CGFloat { size / Self.canvas.width }

    public var body: some View {
        Canvas { context, _ in draw(in: &context) }
            .frame(width: size, height: size * (Self.canvas.height / Self.canvas.width))
            .accessibilityHidden(true)   // 의미는 옆의 문구가 전달한다
    }

    private func draw(in context: inout GraphicsContext) {
        let s = scale
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: x * s, y: y * s, width: w * s, height: h * s)
        }

        // 바닥 그림자
        context.fill(Path(ellipseIn: rect(58, 221, 104, 14)), with: .color(Ink.n900.opacity(0.10)))

        // 다리
        for x in [86.0, 118.0] {
            context.fill(
                Path(roundedRect: rect(x, 168, 16, 52), cornerRadius: 8 * s),
                with: .color(StageColor.top(stage).opacity(0.75))
            )
        }

        // 몸통과 위쪽 하이라이트
        let body = rect(38, 40, 144, 144)
        context.fill(Path(ellipseIn: body), with: .color(StageColor.body(stage)))
        // 위쪽 45%만 밝게. 원본 컨텍스트를 복사해 클립하므로 이후 그리기에 영향이 없다.
        var highlight = context
        highlight.clip(to: Path(rect(36, 38, 148, 67)))
        highlight.fill(Path(ellipseIn: body), with: .color(StageColor.top(stage).opacity(0.55)))

        // 눈
        for x in [86.0, 134.0] {
            context.fill(Path(ellipseIn: rect(x - 19, 84, 38, 44)), with: .color(.white))
            context.fill(Path(ellipseIn: rect(x - 7, pupilY - 7, 14, 14)), with: .color(Ink.n900))
        }

        // 입
        var mouth = Path()
        mouth.move(to: p(mouthLeft, mouthY))
        mouth.addQuadCurve(to: p(mouthLeft + 28, mouthY), control: p(mouthLeft + 14, mouthY + mouthCurve))
        context.stroke(mouth, with: .color(Ink.n900), style: StrokeStyle(lineWidth: 4 * s, lineCap: .round))

        // 땀방울
        for drop in drops {
            context.fill(dropPath(at: p(drop.x, drop.y), scale: drop.scale * s),
                         with: .color(Accent.light.opacity(drop.opacity)))
        }
    }

    /// 물방울 하나. 위가 뾰족하고 아래가 둥글다.
    private func dropPath(at origin: CGPoint, scale s: CGFloat) -> Path {
        var path = Path()
        path.move(to: origin)
        path.addCurve(
            to: CGPoint(x: origin.x, y: origin.y + 18 * s),
            control1: CGPoint(x: origin.x + 6 * s, y: origin.y + 9 * s),
            control2: CGPoint(x: origin.x + 6 * s, y: origin.y + 14 * s))
        path.addCurve(
            to: origin,
            control1: CGPoint(x: origin.x - 6 * s, y: origin.y + 14 * s),
            control2: CGPoint(x: origin.x - 6 * s, y: origin.y + 9 * s))
        path.closeSubpath()
        return path
    }

    // MARK: 단계별 표정

    /// 단계가 오를수록 눈동자가 아래로 내려간다 — 지친 눈.
    private var pupilY: CGFloat { [104, 105, 108, 110, 112, 113][stage - 1] }

    private var mouthY: CGFloat { [136, 138, 142, 148, 150, 152][stage - 1] }
    private var mouthLeft: CGFloat { stage == 1 ? 94 : 96 }

    /// 양수면 웃고, 0이면 일자, 음수면 찡그린다.
    private var mouthCurve: CGFloat { [16, 11, 0, -11, -13, -14][stage - 1] }

    private struct Drop { let x, y, scale, opacity: CGFloat }

    /// 단계가 오를수록 땀방울이 늘어난다.
    private var drops: [Drop] {
        switch stage {
        case 1: []
        case 2: [Drop(x: 168, y: 78, scale: 1, opacity: 0.8)]
        case 3: [Drop(x: 168, y: 74, scale: 1, opacity: 0.85),
                 Drop(x: 44, y: 92, scale: 0.85, opacity: 0.7)]
        case 4: [Drop(x: 170, y: 70, scale: 1.05, opacity: 0.9),
                 Drop(x: 42, y: 88, scale: 0.9, opacity: 0.8),
                 Drop(x: 150, y: 158, scale: 0.8, opacity: 0.7)]
        case 5: [Drop(x: 172, y: 66, scale: 1.1, opacity: 0.95),
                 Drop(x: 40, y: 84, scale: 1, opacity: 0.85),
                 Drop(x: 152, y: 156, scale: 0.85, opacity: 0.8),
                 Drop(x: 62, y: 152, scale: 0.8, opacity: 0.7)]
        default: [Drop(x: 174, y: 62, scale: 1.15, opacity: 1),
                  Drop(x: 38, y: 80, scale: 1.05, opacity: 0.9),
                  Drop(x: 154, y: 154, scale: 0.9, opacity: 0.85),
                  Drop(x: 60, y: 150, scale: 0.85, opacity: 0.8),
                  Drop(x: 110, y: 186, scale: 0.8, opacity: 0.7)]
        }
    }
}

/// 예보 칸의 작은 표정. Figma `Weather Face`.
public struct WeatherFace: View {

    private let level: Int
    private let size: CGFloat

    /// - Parameter level: 1~4. `ForecastLevel.rawValue`를 넘긴다.
    public init(level: Int, size: CGFloat = 34) {
        self.level = min(max(level, 1), 4)
        self.size = size
    }

    public var body: some View {
        Canvas { context, _ in
            let s = size / 24
            context.fill(Path(ellipseIn: CGRect(x: 2 * s, y: 2 * s, width: 20 * s, height: 20 * s)),
                         with: .color(StageColor.body(stageForLevel)))
            for x in [8.6, 15.4] {
                context.fill(
                    Path(ellipseIn: CGRect(x: (x - 1.5) * s, y: 8.9 * s, width: 3 * s, height: 3 * s)),
                    with: .color(Ink.n900))
            }
            var mouth = Path()
            mouth.move(to: CGPoint(x: 9 * s, y: mouthY * s))
            mouth.addQuadCurve(to: CGPoint(x: 15 * s, y: mouthY * s),
                               control: CGPoint(x: 12 * s, y: (mouthY + curve) * s))
            context.stroke(mouth, with: .color(Ink.n900),
                           style: StrokeStyle(lineWidth: 1.5 * s, lineCap: .round))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    /// 표시 구간을 마스코트 색 단계로 되돌린다. 1·2·3·4 → 1·2·3·4단계 색.
    private var stageForLevel: Int { level }

    private var mouthY: CGFloat { [14.6, 14.6, 15.4, 16.0][level - 1] }
    private var curve: CGFloat { [2.6, 2.6, 0, -2.4][level - 1] }
}

#Preview("마스코트") {
    ScrollView {
        VStack(spacing: Space.x4) {
            ForEach(1...6, id: \.self) { stage in
                HStack(spacing: Space.x4) {
                    SweatCharacter(stage: stage, size: 120)
                    VStack(alignment: .leading) {
                        Text("\(stage)단계").sweatType(.heading19)
                        WeatherFace(level: min(stage, 4))
                    }
                }
            }
        }
        .padding(Space.gutter)
    }
    .background(Surface.page)
}
