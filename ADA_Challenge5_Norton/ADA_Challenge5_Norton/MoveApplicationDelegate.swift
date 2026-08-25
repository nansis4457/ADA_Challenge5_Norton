import SweatFeatures
import UIKit

/// Core Location이 백그라운드에서 앱을 다시 실행한 경우 활성 이동을 즉시 재개한다.
@MainActor
final class MoveApplicationDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        MoveBackgroundRuntime.shared.resumeIfNeeded()
        return true
    }
}
