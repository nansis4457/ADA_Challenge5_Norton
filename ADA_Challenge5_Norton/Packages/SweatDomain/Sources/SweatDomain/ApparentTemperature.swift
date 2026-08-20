import Foundation

/// 기상청 여름철 체감온도.
///
/// 2022년 6월 2일 개정식이다. 기온과 상대습도만 쓴다 — **풍속은 들어가지 않는다.**
///
/// ```
/// 체감온도 = -0.2442 + 0.55399·Tw + 0.45535·Ta - 0.0022·Tw² + 0.00278·Tw·Ta + 3.0
/// ```
///
/// `Tw`(습구온도)는 Stull 근사식으로 구한다.
///
/// 순수 함수다. 네트워크도 권한도 필요 없고, 어떤 소스에서 기온·습도를 받아오든
/// 이 계산을 거친다. 소스가 주는 체감온도는 산식이 달라 쓰지 않는다 —
/// 그러면 단계 기준이 둘이 된다.
///
/// - Note: 검증 2026-08-20. 계수는 기상청 공표식과 일치하지만 기상청 포털을
///   직접 열지 못해 1차 출처 눈확인이 남아 있다. `docs/architecture.md` §5.4 참조.
public enum ApparentTemperature {

    /// 여름철 체감온도 (℃).
    ///
    /// - Parameters:
    ///   - temperature: 기온 (℃)
    ///   - relativeHumidity: 상대습도 (%). 0~100 범위로 잘린다.
    /// - Returns: 체감온도 (℃). 입력이 `NaN`이면 `NaN`.
    public static func summer(temperature: Double, relativeHumidity: Double) -> Double {
        guard temperature.isFinite, relativeHumidity.isFinite else { return .nan }
        let ta = temperature
        let rh = min(max(relativeHumidity, 0), 100)
        let tw = wetBulb(temperature: ta, relativeHumidity: rh)
        return -0.2442
            + 0.55399 * tw
            + 0.45535 * ta
            - 0.0022 * tw * tw
            + 0.00278 * tw * ta
            + 3.0
    }

    /// 습구온도 (℃) — Stull 근사식.
    ///
    /// `atan`은 라디안이다. 도(degree)로 계산하면 값이 전혀 달라진다.
    ///
    /// 이 근사식은 기압 약 1013hPa, 상대습도 5~99%, 기온 -20~50℃ 범위에서
    /// 쓰도록 제안된 것이다. 그 밖에서는 오차가 커진다.
    public static func wetBulb(temperature: Double, relativeHumidity: Double) -> Double {
        guard temperature.isFinite, relativeHumidity.isFinite else { return .nan }
        let ta = temperature
        let rh = min(max(relativeHumidity, 0), 100)
        return ta * atan(0.151977 * (rh + 8.313659).squareRoot())
            + atan(ta + rh)
            - atan(rh - 1.676331)
            + 0.00391838 * pow(rh, 1.5) * atan(0.023101 * rh)
            - 4.686035
    }
}
