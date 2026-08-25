import Foundation
import SweatDomain
import SweatPersistence
import WeatherData

/// 홈 화면의 상태.
///
/// 위치를 얻고, 날씨를 받고, 단계를 계산해 화면이 그릴 것을 준비한다.
/// 실패해도 화면이 비지 않도록 마지막 값을 붙들고 있는 것도 여기 책임이다.
@Observable
public final class HomeStore {

    public enum Phase: Sendable, Equatable {
        case loading
        case ready
        /// 위치 권한을 거부해 지역을 골라야 한다.
        case needsRegion(reason: LocationOutcome)
        /// 날씨를 못 받았고 보여줄 값도 없다.
        case failed
    }

    public private(set) var phase: Phase = .loading
    public private(set) var observation: WeatherObservation?
    public private(set) var forecast: WeatherForecast?
    public private(set) var attribution: WeatherAttributionInfo?
    /// 위치 권한이 없어 사용자가 고른 지역.
    public private(set) var region: FallbackRegion?
    /// GPS 좌표를 역지오코딩한 지역명. 실패하면 뷰가 `현재 위치`로 대신한다.
    public private(set) var placeName: String?

    private let repository: WeatherRepository
    private let location: any LocationProviding
    private let locationName: any LocationNameProviding
    private let profile: () -> UserProfile

    public init(
        repository: WeatherRepository,
        location: any LocationProviding,
        locationName: any LocationNameProviding = SystemLocationNameProvider(),
        profile: @escaping () -> UserProfile
    ) {
        self.repository = repository
        self.location = location
        self.locationName = locationName
        self.profile = profile
    }

    // MARK: 계산 결과

    /// 지금 단계. 관측값이 없으면 `nil`.
    public var stage: SweatStage? {
        guard let observation else { return nil }
        let current = profile()
        return SweatStageEngine.stage(
            apparentTemperature: observation.apparentTemperature,
            sensitivity: current.sensitivity,
            calibration: current.calibrationOffset
        )
    }

    public var copy: SweatCopy? { stage.map(SweatCopy.of) }

    /// 예보값의 단계. 홈과 **같은 엔진·같은 개인 보정**을 쓴다.
    /// 예보만 다른 기준으로 계산하면 같은 날 두 곳의 단계가 어긋난다.
    public func stage(forApparent apparent: Double) -> SweatStage {
        let current = profile()
        return SweatStageEngine.stage(
            apparentTemperature: apparent,
            sensitivity: current.sensitivity,
            calibration: current.calibrationOffset
        )
    }

    /// 값이 얼마나 오래됐나. 화면이 `n분 전` 배지를 띄울지 판단한다.
    public var minutesSinceObservation: Int? {
        observation.map { Int($0.age() / 60) }
    }

    // MARK: 불러오기

    public func load() async {
        phase = observation == nil ? .loading : phase

        let coordinate: Coordinate
        if let region {
            coordinate = region.coordinate
        } else {
            switch await location.currentLocation() {
            case .located(let value):
                coordinate = value
                // 역지오코딩 때문에 첫 날씨 표시가 늦어지지 않게 동시에 시작한다.
                let nameTask = Task { await locationName.name(for: value) }
                await loadWeather(at: coordinate)
                placeName = await nameTask.value
                return
            case .denied:
                phase = .needsRegion(reason: .denied)
                return
            case .unavailable:
                phase = .needsRegion(reason: .unavailable)
                return
            }
        }

        await loadWeather(at: coordinate)
    }

    /// 사용자가 지역을 골랐다.
    public func select(_ region: FallbackRegion) async {
        self.region = region
        placeName = nil
        phase = .loading
        await loadWeather(at: region.coordinate)
    }

    private func loadWeather(at coordinate: Coordinate) async {
        do {
            observation = try await repository.currentObservation(at: coordinate)
            phase = .ready
        } catch {
            // 마지막 값이라도 있으면 화면을 비우지 않는다. 배지가 오래됐음을 알린다.
            phase = observation == nil ? .failed : .ready
        }

        // 예보는 없어도 화면이 성립한다. 실패해도 조용히 넘어간다.
        forecast = try? await repository.forecast(at: coordinate)

        // 출처 표기는 법적 요건이라 날씨를 보여주는 동안 반드시 함께 있어야 한다.
        if attribution == nil {
            attribution = try? await repository.attribution()
        }
    }
}
