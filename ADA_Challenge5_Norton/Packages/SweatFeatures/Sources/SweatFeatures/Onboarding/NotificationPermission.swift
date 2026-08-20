import UserNotifications

/// 알림 권한 요청 래퍼.
///
/// 실패를 예외로 올리지 않는다. 권한을 못 받는 건 정상적인 결과지 오류가 아니다.
enum NotificationPermission {

    /// 권한을 요청하고 허용 여부를 돌려준다.
    ///
    /// 이미 결정된 상태면 다시 묻지 않는다 — 시스템이 대화상자를 한 번만 띄운다.
    static func request() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }
}
