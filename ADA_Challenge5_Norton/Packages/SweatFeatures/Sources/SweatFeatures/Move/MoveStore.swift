import Foundation
import MoveActivitySupport
import MoveData
import SweatDomain
import SweatPersistence

@Observable
final class MoveStore {
    enum TrackingState: Sendable, Equatable {
        case idle
        case starting
        case tracking
        case stale(lastObservedAt: Date?)
        case authorizationDenied
        case failed
        case ended
    }

    enum ReminderState: Sendable, Equatable {
        case idle
        case scheduling
        case scheduled
        case denied
        case failed
    }

    enum RecommendationSelection: Sendable, Equatable {
        case shelter(String)
        case shadeDetour(UUID)
    }

    let session: MoveSession
    let recommendations: MoveRecommendations
    private(set) var progress: MoveProgress
    private(set) var trackingState: TrackingState = .idle
    private(set) var reminderState: ReminderState = .idle
    private(set) var selectedRecommendation: RecommendationSelection?
    private(set) var hasLiveActivityIssue = false

    private let tracker: any MovementTracking
    private let notifications: any MovementNotificationScheduling
    private let activity: any MoveActivityUpdating
    private let persistence: any ActiveMovePersisting
    private let calculator: RouteProgressCalculator
    private let maximumUsableAccuracyMeters: Double
    private var needsInitialPersistence: Bool
    private var trackingTask: Task<Void, Never>?

    init(
        route: WalkingRoute,
        startedAt: Date = Date(),
        recommendations: MoveRecommendations = MoveRecommendations(),
        tracker: any MovementTracking = SystemMovementTracker(),
        notifications: any MovementNotificationScheduling = SystemMovementNotificationScheduler(),
        activity: any MoveActivityUpdating = SystemMoveActivityClient(),
        persistence: any ActiveMovePersisting = ActiveMoveStore(),
        calculator: RouteProgressCalculator = RouteProgressCalculator(),
        maximumUsableAccuracyMeters: Double = 100
    ) {
        let session = MoveSession(route: route, startedAt: startedAt)!
        self.session = session
        self.recommendations = recommendations
        self.tracker = tracker
        self.notifications = notifications
        self.activity = activity
        self.persistence = persistence
        self.calculator = calculator
        self.maximumUsableAccuracyMeters = max(maximumUsableAccuracyMeters, 0)
        self.needsInitialPersistence = true
        self.progress = calculator.progress(
            session: session,
            location: route.path[0],
            observedAt: startedAt
        )!
    }

    init(
        snapshot: ActiveMoveSnapshot,
        recommendations: MoveRecommendations = MoveRecommendations(),
        tracker: any MovementTracking = SystemMovementTracker(),
        notifications: any MovementNotificationScheduling = SystemMovementNotificationScheduler(),
        activity: any MoveActivityUpdating = SystemMoveActivityClient(),
        persistence: any ActiveMovePersisting = ActiveMoveStore(),
        calculator: RouteProgressCalculator = RouteProgressCalculator(),
        maximumUsableAccuracyMeters: Double = 100
    ) {
        self.session = snapshot.session
        self.progress = snapshot.progress
        self.recommendations = recommendations
        self.tracker = tracker
        self.notifications = notifications
        self.activity = activity
        self.persistence = persistence
        self.calculator = calculator
        self.maximumUsableAccuracyMeters = max(maximumUsableAccuracyMeters, 0)
        self.needsInitialPersistence = false
    }

    var isWaterReminderSelected: Bool {
        reminderState == .scheduled
    }

    func start() {
        guard trackingTask == nil, trackingState == .idle else { return }
        if needsInitialPersistence {
            persist(at: Date())
            needsInitialPersistence = false
        }
        trackingState = .starting
        trackingTask = Task { [weak self] in
            await self?.runTracking()
        }
    }

    func selectShelter(_ shelter: HeatShelterRecommendation) {
        selectedRecommendation = .shelter(shelter.id)
    }

    func selectShadeDetour(_ detour: ShadeDetourRecommendation) {
        selectedRecommendation = .shadeDetour(detour.route.id)
    }

    func toggleWaterReminder() {
        if reminderState == .scheduled {
            notifications.cancelWaterReminder(for: session.id)
            reminderState = .idle
            return
        }
        guard reminderState != .scheduling else { return }

        reminderState = .scheduling
        Task { [weak self] in
            guard let self else { return }
            do {
                reminderState = switch try await notifications.scheduleWaterReminder(for: session.id) {
                case .scheduled: .scheduled
                case .denied: .denied
                }
            } catch {
                reminderState = .failed
            }
        }
    }

    func finish(at endedAt: Date = Date()) async -> MoveCompletion? {
        guard trackingState != .ended else { return nil }
        trackingTask?.cancel()
        trackingTask = nil
        tracker.stop()
        notifications.cancelWaterReminder(for: session.id)
        await activity.end(finalProgress: progress)
        persistence.clear()
        trackingState = .ended

        return MoveCompletion(
            sessionID: session.id,
            routeID: session.route.id,
            startedAt: session.startedAt,
            endedAt: max(endedAt, session.startedAt),
            traveledDistanceMeters: progress.traveledDistanceMeters,
            fractionCompleted: progress.fractionCompleted
        )
    }

    private func runTracking() async {
        do {
            try await activity.start(session: session, progress: progress)
        } catch {
            hasLiveActivityIssue = true
        }
        trackingState = .tracking

        do {
            for try await event in tracker.updates() {
                guard !Task.isCancelled else { return }
                await handle(event)
            }
        } catch is CancellationError {
            // 사용자가 이동을 끝낸 정상 흐름이다.
        } catch {
            guard !Task.isCancelled else { return }
            trackingState = .failed
        }
    }

    private func handle(_ event: MovementEvent) async {
        switch event {
        case .location(let coordinate, let observedAt, let horizontalAccuracy):
            guard horizontalAccuracy <= maximumUsableAccuracyMeters,
                  let next = calculator.progress(
                    session: session,
                    location: coordinate,
                    observedAt: observedAt,
                    previous: progress
                  )
            else {
                trackingState = .stale(lastObservedAt: progress.observedAt)
                return
            }
            progress = next
            persist(at: observedAt)
            trackingState = .tracking
            await activity.update(progress: next)

        case .stationary:
            if trackingState != .authorizationDenied { trackingState = .tracking }

        case .unavailable:
            trackingState = .stale(lastObservedAt: progress.observedAt)

        case .authorizationDenied:
            trackingState = .authorizationDenied
        }
    }

    private func persist(at savedAt: Date) {
        guard let snapshot = ActiveMoveSnapshot(
            session: session,
            progress: progress,
            savedAt: savedAt
        ) else { return }
        persistence.save(snapshot)
    }
}
