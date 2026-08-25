import Foundation
import os

/// 콜드 스타트 계측 (R12).
///
/// **프로세스가 뜬 순간부터 단계가 화면에 보이기까지**를 잰다.
/// 앱 `init`부터 재면 dyld와 런타임 준비 시간이 빠져 실제 기다림보다 짧게 나온다.
/// 그래서 커널이 기록해 둔 프로세스 시작 시각을 기준으로 삼는다.
///
/// 한 번만 남긴다. 두 번째부터는 콜드 스타트가 아니다.
///
///     log show --predicate 'category == "coldstart"' --last 1m
@MainActor
public enum ColdStart {

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SweatFeatures",
        category: "coldstart"
    )
    private static var recorded = false

    /// 단계가 처음 보였다.
    public static func stageDidAppear() {
        guard !recorded else { return }
        recorded = true

        guard let started = processStart() else {
            log.error("프로세스 시작 시각을 읽지 못했다")
            return
        }
        let elapsed = Date().timeIntervalSince(started)
        log.info("단계 표시까지 \(elapsed * 1000, format: .fixed(precision: 0))ms")
    }

    /// 커널이 기록한 프로세스 시작 시각.
    private static func processStart() -> Date? {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, ProcessInfo.processInfo.processIdentifier]
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        guard sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0) == 0 else { return nil }

        let started = info.kp_proc.p_starttime
        return Date(timeIntervalSince1970: Double(started.tv_sec) + Double(started.tv_usec) / 1_000_000)
    }
}
