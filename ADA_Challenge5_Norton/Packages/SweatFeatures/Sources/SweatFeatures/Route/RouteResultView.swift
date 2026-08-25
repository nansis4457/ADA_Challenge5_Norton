import DesignSystem
import SwiftUI
import SweatDomain

struct RouteResultView: View {
    @Bindable var store: RouteStore
    let onStart: (WalkingRoute) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ScrollView {
            if let route = store.selectedRoute {
                VStack(alignment: .leading, spacing: 0) {
                    backButton

                    Text(RouteCopy.routePair(
                        origin: route.origin.name,
                        destination: route.destination.name
                    ))
                    .sweatType(.caption13)
                    .foregroundStyle(Ink.n600)
                    .padding(.top, Space.x3)

                    Text(route.exposure == nil ? RouteCopy.fastHeading : RouteCopy.lessExposureHeading)
                        .sweatType(.title27)
                        .foregroundStyle(Ink.n900)
                        .padding(.top, Space.x2)

                    RouteMapView(route: route, showsUserLocation: false)
                        .frame(height: 230)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                        .padding(.top, Space.x4)

                    if let exposure = route.exposure {
                        exposureSummary(exposure, route: route)
                    } else {
                        noAnalysisNotice
                            .padding(.top, Space.x3)
                    }

                    Divider()
                        .padding(.top, Space.x6)

                    waypointList(route)
                        .padding(.top, Space.x4)

                    SweatButton(RouteCopy.start) {
                        onStart(route)
                    }
                        .padding(.top, Space.x6)
                }
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.x2)
                .padding(.bottom, Space.x7)
            }
        }
        .background(Surface.page)
        .navigationBarBackButtonHidden(true)
    }

    private var backButton: some View {
        Button { dismiss() } label: {
            HStack(spacing: Space.x1) {
                Image(systemName: "chevron.left")
                Text(RouteCopy.modifyRoute)
                    .sweatType(.body14)
            }
            .foregroundStyle(Accent.deep)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(RouteCopy.modifyRoute)
    }

    private func exposureSummary(_ exposure: ExposureAnalysis, route: WalkingRoute) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ExposureSegmentBar(analysis: exposure)
                .frame(height: Space.x5)
                .padding(.top, Space.x3)

            ExposureLegend(analysis: exposure)
                .padding(.top, Space.x2)

            statistics(route, exposure: exposure)
                .padding(.top, Space.x5)

            if exposure.coverageRatio < 0.999 {
                Text(RouteCopy.partialCoverage(exposure.coverageRatio))
                    .sweatType(.caption13)
                    .foregroundStyle(Ink.n600)
                    .padding(.top, Space.x3)
            }

            Text(RouteCopy.estimateDisclosure)
                .sweatType(.caption13)
                .foregroundStyle(Ink.n600)
                .padding(Space.x4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Surface.magentaTint, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                .padding(.top, Space.x4)

            if store.hasLessExposedAlternative {
                Button(RouteCopy.lessExposureAction) {
                    store.selectLessExposedRoute()
                }
                .sweatType(.bodyStrong15)
                .foregroundStyle(OnColor.accent)
                .padding(.vertical, Space.x2)
                .padding(.horizontal, Space.x4)
                .background(Magenta.base, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                .padding(.top, Space.x2)
            }
        }
    }

    private var noAnalysisNotice: some View {
        Text(RouteCopy.analysisUnavailable)
            .sweatType(.caption13)
            .foregroundStyle(Ink.n600)
            .padding(Space.x4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Surface.accentWash, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }

    @ViewBuilder
    private func statistics(_ route: WalkingRoute, exposure: ExposureAnalysis) -> some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Space.x3) {
                statistic(RouteCopy.total, RouteCopy.duration(route.expectedTravelTime), color: Ink.n900)
                statistic(RouteCopy.outdoorExposure, RouteCopy.duration(exposure.outdoorDuration), color: Magenta.deep)
            }
        } else {
            HStack(spacing: Space.x6) {
                statistic(RouteCopy.total, RouteCopy.duration(route.expectedTravelTime), color: Ink.n900)
                statistic(RouteCopy.outdoorExposure, RouteCopy.duration(exposure.outdoorDuration), color: Magenta.deep)
            }
        }
    }

    private func statistic(_ title: String, _ value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).sweatType(.overline11).foregroundStyle(Ink.n400)
            Text(value).sweatType(.stat22).foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
    }

    private func waypointList(_ route: WalkingRoute) -> some View {
        VStack(alignment: .leading, spacing: Space.x3) {
            Text(RouteCopy.waypoints)
                .sweatType(.overline11)
                .foregroundStyle(Ink.n500)

            WaypointRow(time: RouteCopy.elapsedDuration(0), title: route.origin.name, detail: RouteCopy.originMarker)

            ForEach(waypointSteps(route)) { item in
                WaypointRow(time: item.time, title: item.title, detail: RouteCopy.walkStep)
            }

            WaypointRow(
                time: RouteCopy.duration(route.expectedTravelTime),
                title: route.destination.name,
                detail: RouteCopy.arrived
            )
        }
    }

    private func waypointSteps(_ route: WalkingRoute) -> [WaypointItem] {
        var elapsed: TimeInterval = 0
        return route.steps.compactMap { step in
            elapsed += step.expectedTravelTime
            guard !step.instruction.isEmpty else { return nil }
            return WaypointItem(time: RouteCopy.elapsedDuration(elapsed), title: step.instruction)
        }
        .prefix(3)
        .map { $0 }
    }
}

private struct WaypointItem: Identifiable {
    let id = UUID()
    let time: String
    let title: String
}

private struct WaypointRow: View {
    let time: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.x3) {
            Text(time)
                .sweatType(.caption13)
                .foregroundStyle(Ink.n400)
                .frame(width: 44, alignment: .leading)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .sweatType(.bodyStrong15)
                    .foregroundStyle(Ink.n900)
                Text(detail)
                    .sweatType(.caption13)
                    .foregroundStyle(Ink.n600)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ExposureSegmentBar: View {
    let analysis: ExposureAnalysis

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                ForEach(analysis.segments) { segment in
                    Rectangle()
                        .fill(color(segment.kind))
                        .frame(width: proxy.size.width * segment.expectedDuration / analysis.routeDuration)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(RouteCopy.segmentLabel(
            covered: analysis.coveredRatio,
            outdoor: analysis.outdoorRatio,
            unknown: analysis.unknownRatio
        ))
    }

    private func color(_ kind: ExposureKind) -> Color {
        switch kind {
        case .covered: Accent.light
        case .outdoor: Magenta.light
        case .unknown: Ink.n300
        }
    }
}

private struct ExposureLegend: View {
    let analysis: ExposureAnalysis

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Space.x4) { items }
            VStack(alignment: .leading, spacing: Space.x2) { items }
        }
    }

    @ViewBuilder
    private var items: some View {
        legendItem(Accent.light, RouteCopy.legend(RouteCopy.covered, ratio: analysis.coveredRatio))
        legendItem(Magenta.light, RouteCopy.legend(RouteCopy.outdoor, ratio: analysis.outdoorRatio))
        if analysis.unknownRatio > 0.001 {
            legendItem(Ink.n300, RouteCopy.legend(RouteCopy.unknown, ratio: analysis.unknownRatio))
        }
    }

    private func legendItem(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 5) {
            Rectangle().fill(color).frame(width: 9, height: 9)
            Text(text).sweatType(.caption13).foregroundStyle(Ink.n600)
        }
        .accessibilityElement(children: .combine)
    }
}
