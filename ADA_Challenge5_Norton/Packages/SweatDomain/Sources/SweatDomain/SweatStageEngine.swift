import Foundation

/// 체감온도로부터 땀 불편 단계를 산출한다.
///
/// ## 습도와 풍속을 받지 않는 이유 (규칙 「습도·풍속은 등급을 바꾸지 않는다」)
///
/// 기상청 체감온도 산식에 습도가 이미 반영되어 있다. 여기서 다시 더하면
/// 이중 계산이다. 그래서 이 함수의 시그니처에는 습도·풍속이 **없다.**
/// 테스트로 막는 대신 타입으로 막았다 — 위반이 컴파일되지 않는다.
///
/// 습도·풍속은 단계가 아니라 *설명과 추천의 강도*를 바꾼다.
/// 그 책임은 별도 타입(002에서 추가할 `EnvironmentNote`)이 진다.
public enum SweatStageEngine {

    /// 개인 보정값의 허용 범위 (℃).
    ///
    /// - Warning: 규칙 「기록이 예측을 고친다」는 보정 폭을 "±1.5**단계**"로 규정하는데,
    ///   이 파라미터는 **℃** 단위다. 단계 폭이 구간마다 다르므로
    ///   (28~33℃는 5℃, 35~36℃는 1℃) 둘은 1:1로 환산되지 않는다.
    ///   현재 값은 잠정치이며, 단계 오차를 ℃로 환산하는 책임은
    ///   `CalibrationEngine`(005)에 있다. spec.md 미해결 질문 참조.
    public static let calibrationLimit: Double = 3.0

    /// 주어진 조건에서의 땀 불편 단계.
    ///
    /// - Parameters:
    ///   - apparentTemperature: 기상청 체감온도 (℃).
    ///     이 값을 만드는 책임은 이 패키지 밖(002)에 있다.
    ///   - sensitivity: 사용자가 고른 땀 민감도.
    ///   - calibration: 자가 기록에서 학습된 개인 보정 (℃).
    ///     `±calibrationLimit` 범위로 잘린다.
    /// - Returns: 1~6단계. `apparentTemperature`가 `NaN`이면 1단계.
    public static func stage(
        apparentTemperature: Double,
        sensitivity: Sensitivity,
        calibration: Double = 0
    ) -> SweatStage {
        let clamped = min(max(calibration, -calibrationLimit), calibrationLimit)
        let adjusted = apparentTemperature + sensitivity.offset + clamped
        return SweatStage.containing(adjusted)
    }
}
