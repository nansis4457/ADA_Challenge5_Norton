import Foundation
import Testing
@testable import WeatherData
import SweatDomain

/// 소스를 흉내 내는 스텁. 실패 경로를 마음대로 만들 수 있다.
actor StubSource: WeatherSourcing {
    enum Behavior: Sendable {
        case succeed(WeatherObservation)
        case fail(any Error)
        /// 처음 N번은 실패하고 그다음 성공한다. 재시도 검증용.
        case failThenSucceed(times: Int, WeatherObservation)
    }

    private var behavior: Behavior
    private(set) var callCount = 0

    init(_ behavior: Behavior) { self.behavior = behavior }

    func currentObservation(at coordinate: Coordinate) async throws -> WeatherObservation {
        callCount += 1
        switch behavior {
        case .succeed(let value):
            return value
        case .fail(let error):
            throw error
        case .failThenSucceed(let times, let value):
            if callCount <= times { throw StubError.transient }
            return value
        }
    }
}

enum StubError: Error, Equatable { case transient, offline }

/// 테스트에서 시간을 앞으로 돌리기 위한 시계.
///
/// `var`를 `@Sendable` 클로저에 캡처할 수 없어(Swift 6) 잠금으로 감싼다.
final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date

    init(_ start: Date = Date()) { current = start }

    var now: Date {
        lock.lock(); defer { lock.unlock() }
        return current
    }

    func advance(by interval: TimeInterval) {
        lock.lock(); defer { lock.unlock() }
        current += interval
    }
}

@Suite("WeatherRepository")
struct WeatherRepositoryTests {

    let seoul = Coordinate(latitude: 37.5665, longitude: 126.9780)

    func observation(minutesAgo: Double = 0, temp: Double = 31.5) -> WeatherObservation {
        WeatherObservation(
            temperature: temp, relativeHumidity: 78, windSpeed: 1.1,
            observedAt: Date().addingTimeInterval(-minutesAgo * 60),
            source: .appleWeather
        )
    }

    func makeCache() -> WeatherCache { WeatherCache(directory: nil) }

    // MARK: 정상 경로

    @Test("소스에서 받아 캐시에 넣는다")
    func fetchesAndCaches() async throws {
        let expected = observation()
        let source = StubSource(.succeed(expected))
        let cache = makeCache()
        let repository = WeatherRepository(source: source, cache: cache)

        let first = try await repository.currentObservation(at: seoul)
        #expect(first == expected)

        // 두 번째 호출은 캐시가 새것이라 네트워크를 타지 않는다.
        _ = try await repository.currentObservation(at: seoul)
        #expect(await source.callCount == 1, "신선한 캐시가 있으면 다시 받아오지 않는다")
    }

    @Test("캐시가 오래되면 다시 받아온다")
    func refetchesWhenStale() async throws {
        let source = StubSource(.succeed(observation()))
        let cache = makeCache()
        let clock = TestClock()
        let repository = WeatherRepository(source: source, cache: cache) { clock.now }

        _ = try await repository.currentObservation(at: seoul)
        clock.advance(by: WeatherRepository.freshWindow + 60)
        _ = try await repository.currentObservation(at: seoul)

        #expect(await source.callCount == 2)
    }

    // MARK: 실패 경로 (R10, R11)

    @Test("실패하면 재시도한다")
    func retriesOnFailure() async throws {
        let expected = observation()
        let source = StubSource(.failThenSucceed(times: 1, expected))
        let repository = WeatherRepository(source: source, cache: makeCache(), retryCount: 1)

        let result = try await repository.currentObservation(at: seoul)
        #expect(result == expected)
        #expect(await source.callCount == 2, "한 번 실패하고 한 번 더 시도한다")
    }

    @Test("재시도 횟수를 넘기면 포기한다")
    func stopsAfterRetryBudget() async {
        let source = StubSource(.fail(StubError.offline))
        let repository = WeatherRepository(source: source, cache: makeCache(), retryCount: 2)

        await #expect(throws: StubError.self) {
            try await repository.currentObservation(at: seoul)
        }
        #expect(await source.callCount == 3, "최초 1회 + 재시도 2회")
    }

    @Test("네트워크가 죽으면 오래된 캐시라도 준다 (R11)")
    func servesStaleCacheWhenOffline() async throws {
        let cached = observation(minutesAgo: 30)
        let cache = makeCache()
        let clock = TestClock()

        // 먼저 성공시켜 캐시를 채운다.
        let good = WeatherRepository(source: StubSource(.succeed(cached)), cache: cache) { clock.now }
        _ = try await good.currentObservation(at: seoul)

        // 신선도 창을 넘긴 뒤 네트워크가 죽은 상황
        clock.advance(by: WeatherRepository.freshWindow + 60)
        let broken = WeatherRepository(source: StubSource(.fail(StubError.offline)), cache: cache) { clock.now }

        let result = try await broken.currentObservation(at: seoul)
        #expect(result == cached, "빈 화면 대신 마지막 값을 보여준다")
    }

    @Test("캐시가 너무 오래되면 그냥 실패한다")
    func rejectsTooOldCache() async throws {
        let cache = makeCache()
        let clock = TestClock()
        let good = WeatherRepository(source: StubSource(.succeed(observation())), cache: cache) { clock.now }
        _ = try await good.currentObservation(at: seoul)

        clock.advance(by: WeatherRepository.staleWindow + 60)
        let broken = WeatherRepository(source: StubSource(.fail(StubError.offline)), cache: cache) { clock.now }

        await #expect(throws: StubError.self) {
            try await broken.currentObservation(at: seoul)
        }
    }

    @Test("캐시도 없고 네트워크도 죽으면 오류를 올린다")
    func throwsWhenNothingAvailable() async {
        let repository = WeatherRepository(source: StubSource(.fail(StubError.offline)), cache: makeCache())
        await #expect(throws: StubError.self) {
            try await repository.currentObservation(at: seoul)
        }
    }

    // MARK: 캐시 키

    @Test("같은 격자 안의 좌표는 캐시를 공유한다")
    func sameCellSharesKey() {
        // GPS가 몇 미터씩 흔들려도 같은 값을 다시 받아오지 않게 하려는 것이다.
        let a = Coordinate(latitude: 37.5661, longitude: 126.9781)
        let b = Coordinate(latitude: 37.5664, longitude: 126.9784)  // 둘 다 37.566 / 126.978
        #expect(WeatherRepository.key(for: a) == WeatherRepository.key(for: b))
    }

    /// 격자 방식의 한계다. 반올림 경계를 사이에 둔 두 점은 아무리 가까워도
    /// 키가 갈린다. 최악의 경우 요청이 한 번 더 나갈 뿐이라 받아들인다.
    @Test("반올림 경계에 걸치면 키가 갈린다")
    func roundingBoundarySplitsKey() {
        let below = Coordinate(latitude: 37.56649, longitude: 126.978)
        let above = Coordinate(latitude: 37.56651, longitude: 126.978)
        #expect(WeatherRepository.key(for: below) != WeatherRepository.key(for: above))
    }

    @Test("먼 좌표는 캐시를 나눠 쓴다")
    func distantCoordinatesDifferentKey() {
        let seoul = Coordinate(latitude: 37.5665, longitude: 126.9780)
        let busan = Coordinate(latitude: 35.1796, longitude: 129.0756)
        #expect(WeatherRepository.key(for: seoul) != WeatherRepository.key(for: busan))
    }
}

@Suite("WeatherCache")
struct WeatherCacheTests {

    func entry(fetchedAt: Date = Date()) -> CachedObservation {
        CachedObservation(
            observation: WeatherObservation(
                temperature: 31.5, relativeHumidity: 78, windSpeed: 1.1,
                observedAt: fetchedAt, source: .appleWeather),
            fetchedAt: fetchedAt
        )
    }

    @Test("저장한 값이 그대로 돌아온다")
    func roundTrip() async {
        let cache = WeatherCache(directory: nil)
        let value = entry()
        await cache.store(value, for: "key")
        #expect(await cache.value(for: "key") == value)
    }

    @Test("없는 키는 nil")
    func missingKey() async {
        let cache = WeatherCache(directory: nil)
        #expect(await cache.value(for: "없음") == nil)
    }

    @Test("디스크에 남아 다음 실행에서도 읽힌다")
    func survivesNewInstance() async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }

        let value = entry()
        await WeatherCache(directory: directory).store(value, for: "key")

        // 앱을 다시 켠 상황
        let reopened = WeatherCache(directory: directory)
        #expect(await reopened.value(for: "key") == value)
    }

    @Test("경과 시간이 음수가 되지 않는다")
    func ageNeverNegative() {
        let future = entry(fetchedAt: Date().addingTimeInterval(600))
        #expect(future.age(at: Date()) == 0)
    }
}
