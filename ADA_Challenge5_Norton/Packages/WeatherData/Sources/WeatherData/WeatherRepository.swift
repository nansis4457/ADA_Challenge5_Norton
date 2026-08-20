import Foundation
import SweatDomain

/// 날씨를 가져오는 단일 창구.
///
/// 화면은 어디서 왔는지 모른다. 캐시·재시도·실패 처리가 전부 여기 갇혀 있다.
public actor WeatherRepository {

    /// 이 시간 안이면 네트워크를 타지 않는다.
    public static let freshWindow: TimeInterval = 10 * 60
    /// 네트워크가 실패했을 때 이 시간 안의 캐시까지는 받아들인다.
    public static let staleWindow: TimeInterval = 60 * 60

    private let source: any WeatherSourcing
    private let cache: WeatherCache
    private let now: @Sendable () -> Date
    private let retryCount: Int

    public init(
        source: any WeatherSourcing,
        cache: WeatherCache = WeatherCache(),
        retryCount: Int = 1,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.source = source
        self.cache = cache
        self.retryCount = max(0, retryCount)
        self.now = now
    }

    /// 해당 좌표의 현재 날씨.
    ///
    /// 순서는 이렇다.
    /// 1. 캐시가 충분히 새것이면 그대로 준다 (네트워크를 타지 않는다)
    /// 2. 아니면 소스에서 받아온다. 실패하면 `retryCount`만큼 다시 시도한다
    /// 3. 그래도 실패하면 **오래된 캐시라도 준다** — 빈 화면을 만들지 않는다
    /// 4. 캐시조차 없으면 그때 오류를 올린다
    public func currentObservation(at coordinate: Coordinate) async throws -> WeatherObservation {
        let key = Self.key(for: coordinate)
        let cached = await cache.value(for: key)

        if let cached, cached.age(at: now()) < Self.freshWindow {
            return cached.observation
        }

        do {
            let fresh = try await fetchWithRetry(at: coordinate)
            await cache.store(CachedObservation(observation: fresh, fetchedAt: now()), for: key)
            return fresh
        } catch {
            // 네트워크가 죽었다. 오래된 값이라도 있으면 그걸 준다.
            // 화면은 observedAt 으로 "n분 전"을 표시해 정직하게 알린다.
            if let cached, cached.age(at: now()) < Self.staleWindow {
                return cached.observation
            }
            throw error
        }
    }

    private func fetchWithRetry(at coordinate: Coordinate) async throws -> WeatherObservation {
        var lastError: (any Error)?
        for _ in 0...retryCount {
            do {
                return try await source.currentObservation(at: coordinate)
            } catch {
                lastError = error
            }
        }
        throw lastError ?? WeatherRepositoryError.unavailable
    }

    /// 좌표를 캐시 키로. 소수 셋째 자리(약 100m)면 같은 지점으로 본다.
    ///
    /// GPS가 몇 미터씩 흔들려도 같은 값을 다시 받아오지 않게 하려는 것이다.
    ///
    /// - Note: 반올림 경계를 사이에 둔 두 점은 아무리 가까워도 키가 갈린다.
    ///   격자 방식의 한계이며, 최악의 경우 요청이 한 번 더 나갈 뿐이라 받아들인다.
    static func key(for coordinate: Coordinate) -> String {
        String(format: "%.3f,%.3f", coordinate.latitude, coordinate.longitude)
    }
}

public enum WeatherRepositoryError: Error, Equatable {
    /// 소스도 캐시도 값을 주지 못했다.
    case unavailable
}
