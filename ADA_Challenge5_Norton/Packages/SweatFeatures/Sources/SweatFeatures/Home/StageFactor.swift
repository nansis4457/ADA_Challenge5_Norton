import SweatDomain

/// 등급 상세에 보여줄 요인 하나.
///
/// **막대는 설명이지 계산이 아니다.** 단계는 체감온도가 정하고, 이 화면은
/// 그 값이 어떻게 나왔는지를 풀어 보여줄 뿐이다.
struct StageFactor: Identifiable {

    enum Kind: String, CaseIterable {
        case apparentTemperature
        case humidity
        case wind
    }

    let kind: Kind
    let value: String
    let note: String
    /// 막대로 표시할 위치 (0~1). **`nil`이면 막대를 그리지 않는다.**
    let position: Double?

    var id: String { kind.rawValue }

    /// 관측값과 단계에서 요인 세 개를 만든다.
    static func all(for observation: WeatherObservation, stage: SweatStage) -> [StageFactor] {
        [
            StageFactor(
                kind: .apparentTemperature,
                value: "\(observation.apparentTemperature.formatted(.number.precision(.fractionLength(1))))℃",
                note: DetailCopy.apparentNote(stage: stage),
                position: SweatStage.displayPosition(of: observation.apparentTemperature)
            ),
            StageFactor(
                kind: .humidity,
                value: "\(Int(observation.relativeHumidity))%",
                note: DetailCopy.humidityNote,
                position: min(max(observation.relativeHumidity / 100, 0), 1)
            ),
            // 풍속에는 막대가 없다. 아래 주석 참조.
            StageFactor(
                kind: .wind,
                value: "\(observation.windSpeed.formatted(.number.precision(.fractionLength(1)))) m/s",
                note: DetailCopy.windNote,
                position: nil
            ),
        ]
    }
}
