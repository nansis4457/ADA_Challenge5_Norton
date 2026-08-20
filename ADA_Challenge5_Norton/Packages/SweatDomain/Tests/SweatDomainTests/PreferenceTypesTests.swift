import Testing
@testable import SweatDomain

@Suite("저장 식별자 안정성")
struct PreferenceTypesTests {

    /// 이 값들은 사용자 기기에 저장된다. 바뀌면 이미 저장된 설정을 읽지 못한다.
    /// 테스트를 고치기 전에 마이그레이션이 필요한지 먼저 따져야 한다.
    @Test("이동수단 rawValue")
    func transportRawValues() {
        #expect(Transport.walk.rawValue == "walk")
        #expect(Transport.subway.rawValue == "subway")
        #expect(Transport.bus.rawValue == "bus")
        #expect(Transport.bike.rawValue == "bike")
        #expect(Transport.allCases.count == 4)
    }

    @Test("야외 이동시간 rawValue")
    func durationRawValues() {
        #expect(OutdoorDuration.under20.rawValue == "under20")
        #expect(OutdoorDuration.twentyToForty.rawValue == "twentyToForty")
        #expect(OutdoorDuration.over40.rawValue == "over40")
        #expect(OutdoorDuration.allCases.count == 3)
    }

    @Test("민감도 rawValue — 001 이전부터 저장되던 값")
    func sensitivityRawValues() {
        #expect(Sensitivity.allCases.map(\.rawValue) == ["low", "normal", "high"])
    }

    @Test("모든 케이스가 rawValue로 왕복된다", arguments: Transport.allCases)
    func transportRoundTrip(_ value: Transport) {
        #expect(Transport(rawValue: value.rawValue) == value)
    }

    @Test("한글 라벨이 도메인에 새어 들어오지 않았다")
    func noKoreanLabels() {
        let raws = Transport.allCases.map(\.rawValue) + OutdoorDuration.allCases.map(\.rawValue)
        for raw in raws {
            // #expect 매크로 안에서 keyPath allSatisfy 를 쓰면 rethrows 로 확장돼 컴파일이 깨진다.
            let isASCII = raw.unicodeScalars.allSatisfy { $0.isASCII }
            #expect(isASCII, "\(raw)에 ASCII 밖 문자가 있습니다")
        }
    }
}
