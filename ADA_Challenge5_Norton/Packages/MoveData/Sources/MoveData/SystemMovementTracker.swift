import Foundation
import SweatDomain

#if os(iOS)
import CoreLocation

/// When In Use 권한과 파란 시스템 표시를 사용해 활성 이동 위치를 받는다.
public final class SystemMovementTracker: MovementTracking {
    private var updateTask: Task<Void, Never>?
    private var backgroundSession: CLBackgroundActivitySession?

    public init() {}

    public func updates() -> AsyncThrowingStream<MovementEvent, any Error> {
        stop()
        backgroundSession = CLBackgroundActivitySession()

        return AsyncThrowingStream { continuation in
            updateTask = Task { [weak self] in
                do {
                    for try await update in CLLocationUpdate.liveUpdates(.fitness) {
                        guard !Task.isCancelled else { break }

                        if update.authorizationDenied
                            || update.authorizationDeniedGlobally
                            || update.authorizationRestricted {
                            continuation.yield(.authorizationDenied)
                            continue
                        }

                        if update.locationUnavailable {
                            continuation.yield(.unavailable(observedAt: Date()))
                            continue
                        }

                        if update.stationary {
                            continuation.yield(.stationary(observedAt: Date()))
                        }

                        guard let location = update.location else { continue }
                        let coordinate = Coordinate(
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude
                        )
                        guard coordinate.isValid else { continue }
                        continuation.yield(.location(
                            coordinate,
                            observedAt: location.timestamp,
                            horizontalAccuracy: max(location.horizontalAccuracy, 0)
                        ))
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
                self?.releaseSystemResources()
            }

            continuation.onTermination = { @Sendable [weak self] _ in
                Task { @MainActor in self?.stop() }
            }
        }
    }

    public func stop() {
        updateTask?.cancel()
        updateTask = nil
        releaseSystemResources()
    }

    private func releaseSystemResources() {
        backgroundSession?.invalidate()
        backgroundSession = nil
    }
}
#else
/// Swift Package의 macOS 테스트 빌드에서는 위치 추적을 시작할 수 없다.
public final class SystemMovementTracker: MovementTracking {
    public init() {}

    public func updates() -> AsyncThrowingStream<MovementEvent, any Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: MovementTrackingError.unavailable)
        }
    }

    public func stop() {}
}
#endif
