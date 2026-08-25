import Foundation
import Testing
@testable import SweatFeatures
import SweatDomain
import SweatPersistence
import WeatherData

/// 권한 상태를 마음대로 만드는 스텁.
struct StubLocationProvider: LocationProviding {
    let outcome: LocationOutcome
    func currentLocation() async -> LocationOutcome { outcome }
}

struct StubLocationNameProvider: LocationNameProviding {
    let value: String?
    func name(for coordinate: Coordinate) async -> String? { value }
}

actor LocationTestWeatherSource: WeatherSourcing {
    func currentObservation(at coordinate: Coordinate) async throws -> WeatherObservation {
        WeatherObservation(
            temperature: 31.5, relativeHumidity: 78, windSpeed: 1.1,
            observedAt: Date(), source: .appleWeather
        )
    }

    func forecast(at coordinate: Coordinate) async throws -> WeatherForecast {
        WeatherForecast(hourly: [], daily: [], fetchedAt: Date())
    }

    func attribution() async throws -> WeatherAttributionInfo {
        WeatherAttributionInfo(
            serviceName: "Test Weather", legalText: "Test",
            legalPageURL: URL(string: "https://example.com/legal")!,
            markLightURL: URL(string: "https://example.com/light.png")!,
            markDarkURL: URL(string: "https://example.com/dark.png")!
        )
    }
}

@Suite("위치와 지역 대체")
struct LocationTests {

    @Test("거부는 오류가 아니라 값으로 온다 (R9)")
    func denialIsAValue() async {
        let provider = StubLocationProvider(outcome: .denied)
        #expect(await provider.currentLocation() == .denied)
    }

    @Test("거부와 사용 불가를 구분한다")
    func deniedAndUnavailableAreDistinct() {
        #expect(LocationOutcome.denied != LocationOutcome.unavailable)
        #expect(LocationOutcome.deferred != LocationOutcome.denied)
        #expect(LocationOutcome.deferred != LocationOutcome.unavailable)
    }

    @Test("온보딩에서 위치 사용을 미루면 홈이 시스템 권한을 다시 묻지 않는다 (R17)")
    func deferredLocationDoesNotRequestAgain() async {
        let provider = SpyLocationProvider(
            outcome: .located(Coordinate(latitude: 36.0190, longitude: 129.3435))
        )
        var profile = UserProfile.default
        profile.usesCurrentLocation = false
        let store = HomeStore(
            repository: WeatherRepository(
                source: LocationTestWeatherSource(),
                cache: WeatherCache(directory: nil)
            ),
            location: provider
        ) { profile }

        await store.load()

        #expect(await provider.recordedCallCount() == 0)
        #expect(store.phase == HomeStore.Phase.needsRegion(reason: LocationOutcome.deferred))
    }

    @Test("GPS 좌표의 지역명을 홈 저장소에 보관한다 (R3)")
    func resolvedPlaceNameIsStored() async {
        let coordinate = Coordinate(latitude: 36.0190, longitude: 129.3435)
        let store = HomeStore(
            repository: WeatherRepository(
                source: LocationTestWeatherSource(),
                cache: WeatherCache(directory: nil)
            ),
            location: StubLocationProvider(outcome: .located(coordinate)),
            locationName: StubLocationNameProvider(value: "포항시")
        ) { .default }

        await store.load()

        #expect(store.phase == .ready)
        #expect(store.placeName == "포항시")
        #expect(store.region == nil)
    }

    @Test("역지오코딩 실패가 날씨 표시를 막지 않는다")
    func geocodingFailureDoesNotBlockWeather() async {
        let coordinate = Coordinate(latitude: 36.0190, longitude: 129.3435)
        let store = HomeStore(
            repository: WeatherRepository(
                source: LocationTestWeatherSource(),
                cache: WeatherCache(directory: nil)
            ),
            location: StubLocationProvider(outcome: .located(coordinate)),
            locationName: StubLocationNameProvider(value: nil)
        ) { .default }

        await store.load()

        #expect(store.phase == .ready)
        #expect(store.observation != nil)
        #expect(store.placeName == nil)
    }

    // MARK: 대체 지역

    @Test("지역 식별자는 저장값이라 고정한다")
    func regionIdentifiersAreStable() {
        #expect(FallbackRegion.seoul.rawValue == "seoul")
        #expect(FallbackRegion.pohang.rawValue == "pohang")
        #expect(FallbackRegion.allCases.count == 7)
    }

    @Test("지역 이름이 도메인에 새어 들어오지 않았다")
    func regionHasNoKoreanInRawValue() {
        for region in FallbackRegion.allCases {
            let isASCII = region.rawValue.unicodeScalars.allSatisfy { $0.isASCII }
            #expect(isASCII, "\(region.rawValue)에 ASCII 밖 문자")
        }
    }

    @Test("모든 지역에 이름이 있다")
    func everyRegionHasName() {
        for region in FallbackRegion.allCases {
            #expect(!HomeCopy.Location.name(region).isEmpty)
        }
    }

    @Test("지역 이름이 겹치지 않는다")
    func regionNamesAreUnique() {
        let names = FallbackRegion.allCases.map(HomeCopy.Location.name)
        #expect(Set(names).count == names.count)
    }

    @Test("좌표가 한반도 범위 안에 있다", arguments: FallbackRegion.allCases)
    func coordinatesArePlausible(region: FallbackRegion) {
        let c = region.coordinate
        #expect((33.0...39.0).contains(c.latitude), "\(region) 위도 \(c.latitude)")
        #expect((124.0...132.0).contains(c.longitude), "\(region) 경도 \(c.longitude)")
    }

    @Test("지역마다 좌표가 다르다")
    func coordinatesAreDistinct() {
        let coords = FallbackRegion.allCases.map(\.coordinate)
        #expect(Set(coords).count == coords.count)
    }

    // MARK: 문구

    @Test("출처 문구에 기상청도 관측도 없다")
    func observedAtCopyAvoidsWrongSource() {
        let text = HomeCopy.observedAt("오전 8:00")
        #expect(!text.contains("기상청"))
        #expect(!text.contains("관측"), "WeatherKit은 모델 기반 값이다")
        #expect(text == "오전 8:00 기준")
    }

    @Test("홈 문구에 금지 표현이 없다")
    func homeCopyHasNoForbiddenExpressions() throws {
        for (pattern, reason) in OnboardingCopyTests.forbidden {
            let regex = try NSRegularExpression(pattern: pattern)
            for text in HomeCopy.allStrings {
                let hits = regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
                #expect(hits == 0, "금지 표현(\(reason)): \"\(text)\"")
            }
        }
    }
}
