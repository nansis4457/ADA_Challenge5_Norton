import ActivityKit
import DesignSystem
import MoveActivitySupport
import SwiftUI
import WidgetKit

struct MoveLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MoveActivityAttributes.self) { context in
            MoveLockScreenView(context: context)
                .activityBackgroundTint(Surface.page)
                .activitySystemActionForegroundColor(Accent.base)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(MoveActivityCopy.moving, systemImage: "figure.walk")
                        .sweatType(.caption13)
                        .foregroundStyle(Accent.base)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(MoveActivityCopy.remainingMinutes(context.state.estimatedRemainingMinutes))
                        .sweatType(.caption13)
                        .foregroundStyle(Ink.n900)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: Space.x1 + 2) {
                        Text(MoveActivityCopy.route(
                            origin: context.attributes.originName,
                            destination: context.attributes.destinationName
                        ))
                            .sweatType(.caption12)
                            .foregroundStyle(Ink.n600)
                            .lineLimit(1)
                        ProgressView(value: context.state.fractionCompleted)
                            .tint(Accent.base)
                    }
                }
            } compactLeading: {
                Image(systemName: "figure.walk")
                    .foregroundStyle(Accent.base)
            } compactTrailing: {
                Text("\(MoveActivityCopy.percentage(context.state.fractionCompleted))%")
                    .sweatType(.caption12)
                    .foregroundStyle(Accent.base)
            } minimal: {
                Image(systemName: "figure.walk")
                    .foregroundStyle(Accent.base)
            }
            .keylineTint(Accent.base)
        }
    }
}

private struct MoveLockScreenView: View {
    let context: ActivityViewContext<MoveActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: Space.x2 + 2) {
            HStack(alignment: .firstTextBaseline) {
                Label(MoveActivityCopy.moving, systemImage: "figure.walk")
                    .sweatType(.caption13)
                    .foregroundStyle(Accent.base)
                Spacer(minLength: Space.x2)
                Text(MoveActivityCopy.elapsedMinutes(context.state.elapsedMinutes))
                    .sweatType(.caption13)
                    .foregroundStyle(Ink.n600)
            }

            Text(MoveActivityCopy.route(
                origin: context.attributes.originName,
                destination: context.attributes.destinationName
            ))
                .sweatType(.bodyStrong15)
                .foregroundStyle(Ink.n900)
                .lineLimit(1)

            ProgressView(value: context.state.fractionCompleted)
                .tint(Accent.base)

            HStack {
                Text(MoveActivityCopy.remainingDistance(context.state.remainingDistanceMeters))
                Spacer(minLength: Space.x2)
                Text(MoveActivityCopy.remainingMinutes(context.state.estimatedRemainingMinutes))
            }
            .sweatType(.caption13)
            .foregroundStyle(Ink.n600)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(MoveActivityCopy.accessibility(context))
    }
}

private enum MoveActivityCopy {
    static let moving = "이동 중"

    static func route(origin: String, destination: String) -> String {
        "\(origin) → \(destination)"
    }

    static func elapsedMinutes(_ minutes: Int) -> String {
        "\(minutes)분 경과"
    }

    static func remainingMinutes(_ minutes: Int) -> String {
        "예상 \(minutes)분 남음"
    }

    static func remainingDistance(_ meters: Double) -> String {
        "남은 거리 " + distance(meters)
    }

    static func percentage(_ fraction: Double) -> Int {
        Int((min(max(fraction, 0), 1) * 100).rounded())
    }

    static func accessibility(_ context: ActivityViewContext<MoveActivityAttributes>) -> String {
        route(
            origin: context.attributes.originName,
            destination: context.attributes.destinationName
        ) + ", \(percentage(context.state.fractionCompleted))% 진행, "
            + remainingDistance(context.state.remainingDistanceMeters) + ", "
            + remainingMinutes(context.state.estimatedRemainingMinutes)
    }

    private static func distance(_ meters: Double) -> String {
        if meters >= 1_000 {
            return (meters / 1_000).formatted(.number.precision(.fractionLength(1))) + "km"
        }
        return "\(Int((meters / 10).rounded() * 10))m"
    }
}
