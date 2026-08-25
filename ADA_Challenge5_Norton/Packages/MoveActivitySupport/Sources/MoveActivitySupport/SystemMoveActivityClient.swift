import Foundation
import SweatDomain

#if os(iOS)
@preconcurrency import ActivityKit

public final class SystemMoveActivityClient: MoveActivityUpdating {
    private let policy: MoveActivityUpdatePolicy
    private var activity: Activity<MoveActivityAttributes>?
    private var lastUpdatedAt: Date?
    private var lastFraction: Double?

    public init(policy: MoveActivityUpdatePolicy = MoveActivityUpdatePolicy()) {
        self.policy = policy
    }

    public var isAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    public func start(session: MoveSession, progress: MoveProgress) async throws {
        guard isAvailable else { throw MoveActivityError.disabled }

        for existing in Activity<MoveActivityAttributes>.activities
            where existing.attributes.sessionID != session.id {
            await existing.end(nil, dismissalPolicy: .immediate)
        }

        if let existing = Activity<MoveActivityAttributes>.activities.first(where: {
            $0.attributes.sessionID == session.id
        }) {
            activity = existing
            lastUpdatedAt = progress.observedAt
            lastFraction = progress.fractionCompleted
            return
        }

        let attributes = MoveActivityAttributes(
            sessionID: session.id,
            originName: session.route.origin.name,
            destinationName: session.route.destination.name
        )
        let content = ActivityContent(
            state: Self.contentState(progress),
            staleDate: progress.observedAt.addingTimeInterval(120)
        )
        activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
        lastUpdatedAt = progress.observedAt
        lastFraction = progress.fractionCompleted
    }

    @discardableResult
    public func update(progress: MoveProgress) async -> Bool {
        guard let activity, let lastUpdatedAt, let lastFraction,
              policy.shouldUpdate(
                lastUpdatedAt: lastUpdatedAt,
                lastFraction: lastFraction,
                nextObservedAt: progress.observedAt,
                nextFraction: progress.fractionCompleted
              )
        else { return false }

        await activity.update(ActivityContent(
            state: Self.contentState(progress),
            staleDate: progress.observedAt.addingTimeInterval(120)
        ))
        self.lastUpdatedAt = progress.observedAt
        self.lastFraction = progress.fractionCompleted
        return true
    }

    public func end(finalProgress: MoveProgress?) async {
        guard let activity else { return }
        let content = finalProgress.map {
            ActivityContent(state: Self.contentState($0), staleDate: nil)
        }
        await activity.end(content, dismissalPolicy: .immediate)
        self.activity = nil
        lastUpdatedAt = nil
        lastFraction = nil
    }

    private static func contentState(_ progress: MoveProgress) -> MoveActivityAttributes.ContentState {
        MoveActivityAttributes.ContentState(
            fractionCompleted: progress.fractionCompleted,
            remainingDistanceMeters: progress.remainingDistanceMeters,
            estimatedRemainingMinutes: max(Int(ceil(progress.estimatedRemainingTime / 60)), 0),
            elapsedMinutes: Int(progress.elapsedTime / 60)
        )
    }
}
#else
public typealias SystemMoveActivityClient = UnavailableMoveActivityClient
#endif
