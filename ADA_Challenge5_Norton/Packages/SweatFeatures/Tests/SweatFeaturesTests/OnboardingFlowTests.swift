import Foundation
import Testing
@testable import SweatFeatures
import SweatDomain
import SweatPersistence

@Suite("온보딩 흐름")
struct OnboardingFlowTests {

    private func makeStore() -> ProfileStore {
        ProfileStore(defaults: UserDefaults(suiteName: "test.\(UUID().uuidString)")!)
    }

    // MARK: 최초 실행

    @Test("최초 실행은 1단계에서 시작하고 뒤로가기가 없다 (R11)")
    func initialModeStartsAtFirstStep() {
        let flow = OnboardingFlow(store: makeStore(), mode: .initial) {}
        #expect(flow.step == .sensitivity)
        #expect(flow.showsBackButton == false)
        #expect(flow.showsTabBar == false)
        #expect(flow.primaryActionTitle == OnboardingCopy.next)
    }

    @Test("세 단계를 순서대로 지난다")
    func advancesThroughSteps() {
        var finished = false
        let flow = OnboardingFlow(store: makeStore(), mode: .initial) { finished = true }
        flow.advance()
        #expect(flow.step == .movement)
        flow.advance()
        #expect(flow.step == .notification)
        #expect(finished == false, "알림 단계는 CTA로 끝난다")
    }

    @Test("온보딩을 마치면 저장되고 완료 표시가 남는다 (R2, R3)")
    func finishingPersistsProfile() {
        let store = makeStore()
        let flow = OnboardingFlow(store: store, mode: .initial) {}
        flow.select(Sensitivity.high)
        flow.select(Transport.bike)
        flow.select(OutdoorDuration.over40)
        flow.skipNotifications()

        let saved = store.load()
        #expect(saved.hasCompletedOnboarding == true)
        #expect(saved.sensitivity == .high)
        #expect(saved.transport == .bike)
        #expect(saved.outdoorDuration == .over40)
        #expect(saved.wantsNotification == false)
    }

    @Test("나중에 하기는 알림을 끈 채로 끝낸다 (R7)")
    func skipDoesNotEnableNotification() {
        let store = makeStore()
        let flow = OnboardingFlow(store: store, mode: .initial) {}
        flow.skipNotifications()
        #expect(store.load().wantsNotification == false)
    }

    // MARK: 편집

    @Test("편집은 지정된 단계에서 시작하고 저장으로 끝난다 (R8)")
    func editingModeStartsAtTarget() {
        let flow = OnboardingFlow(store: makeStore(), mode: .editing(.movement)) {}
        #expect(flow.step == .movement)
        #expect(flow.showsBackButton == true)
        #expect(flow.showsTabBar == true)
        #expect(flow.primaryActionTitle == OnboardingCopy.save)
    }

    @Test("편집에서 저장하면 다음 단계로 가지 않고 즉시 끝난다 (R10)")
    func editingFinishesImmediately() {
        var finished = false
        let flow = OnboardingFlow(store: makeStore(), mode: .editing(.sensitivity)) { finished = true }
        flow.select(Sensitivity.low)
        flow.advance()
        #expect(finished == true)
        #expect(flow.step == .sensitivity, "단계가 넘어가지 않는다")
    }

    @Test("편집은 저장된 값이 선택된 채로 시작한다 (R9)")
    func editingLoadsSavedValues() {
        let store = makeStore()
        var profile = UserProfile.default
        profile.sensitivity = .high
        profile.transport = .walk
        store.save(profile)

        let flow = OnboardingFlow(store: store, mode: .editing(.sensitivity)) {}
        #expect(flow.profile.sensitivity == .high)
        #expect(flow.profile.transport == .walk)
    }

    @Test("편집에서 완료 표시를 건드리지 않는다")
    func editingKeepsCompletionFlag() {
        let store = makeStore()
        var profile = UserProfile.default
        profile.hasCompletedOnboarding = true
        store.save(profile)

        let flow = OnboardingFlow(store: store, mode: .editing(.movement)) {}
        flow.select(Transport.bus)
        flow.advance()
        #expect(store.load().hasCompletedOnboarding == true)
        #expect(store.load().transport == .bus)
    }

    @Test("취소하면 저장하지 않고 되돌린다")
    func cancelDiscardsChanges() {
        let store = makeStore()
        var profile = UserProfile.default
        profile.sensitivity = .normal
        store.save(profile)

        var finished = false
        let flow = OnboardingFlow(store: store, mode: .editing(.sensitivity)) { finished = true }
        flow.select(Sensitivity.high)
        flow.cancel()

        #expect(finished == true)
        #expect(store.load().sensitivity == .normal, "취소한 변경은 저장되지 않는다")
    }

    // MARK: 민감도가 실제로 등급을 바꾸는가 (R4)

    @Test("고른 민감도가 등급 계산에 반영된다 (R4)")
    func sensitivityAffectsStage() {
        let temperature = 34.2
        let stages = Sensitivity.allCases.map {
            SweatStageEngine.stage(apparentTemperature: temperature, sensitivity: $0).rawValue
        }
        #expect(Set(stages).count > 1, "민감도에 따라 단계가 달라져야 한다")
    }
}
