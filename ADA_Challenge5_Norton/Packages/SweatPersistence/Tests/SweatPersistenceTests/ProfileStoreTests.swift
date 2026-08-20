import Foundation
import Testing
@testable import SweatPersistence
import SweatDomain

@Suite("ProfileStore")
struct ProfileStoreTests {

    /// 실제 사용자 설정을 건드리지 않도록 매번 새 suite를 쓴다.
    private func makeStore() -> (ProfileStore, UserDefaults) {
        let suite = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return (ProfileStore(defaults: defaults), defaults)
    }

    @Test("빈 저장소는 기본값을 준다")
    func emptyStoreReturnsDefault() {
        let (store, _) = makeStore()
        #expect(store.load() == .default)
        #expect(store.load().sensitivity == .normal)
        #expect(store.load().transport == .subway)
        #expect(store.load().outdoorDuration == .twentyToForty)
        #expect(store.load().hasCompletedOnboarding == false)
    }

    @Test("저장한 값이 그대로 돌아온다")
    func roundTrip() {
        let (store, _) = makeStore()
        var profile = UserProfile.default
        profile.sensitivity = .high
        profile.transport = .bike
        profile.outdoorDuration = .over40
        profile.hasCompletedOnboarding = true
        profile.calibrationOffset = 0.6

        store.save(profile)
        #expect(store.load() == profile)
    }

    @Test("손상된 데이터는 기본값으로 복구된다")
    func corruptedDataRecovers() {
        let (store, defaults) = makeStore()
        defaults.set(Data("이건 JSON이 아니다".utf8), forKey: "sweat.userProfile")

        #expect(store.load() == .default, "손상된 데이터에서도 크래시 없이 기본값")
        #expect(defaults.data(forKey: "sweat.userProfile") == nil, "손상된 값은 지워야 매 실행 실패하지 않는다")
    }

    @Test("필드가 없는 예전 저장값도 읽힌다")
    func partialDataDecodes() throws {
        let (store, defaults) = makeStore()
        let old = #"{"sensitivity":"high","hasCompletedOnboarding":true}"#
        defaults.set(Data(old.utf8), forKey: "sweat.userProfile")

        let loaded = store.load()
        #expect(loaded.sensitivity == .high)
        #expect(loaded.hasCompletedOnboarding == true)
        #expect(loaded.transport == UserProfile.default.transport, "없는 필드는 기본값")
    }

    @Test("reset은 기본값으로 되돌린다")
    func reset() {
        let (store, _) = makeStore()
        var profile = UserProfile.default
        profile.hasCompletedOnboarding = true
        store.save(profile)
        store.reset()
        #expect(store.load().hasCompletedOnboarding == false)
    }
}
