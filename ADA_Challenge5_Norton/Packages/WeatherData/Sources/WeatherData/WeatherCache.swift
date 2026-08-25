import Foundation
import SweatDomain

/// 캐시에 담긴 관측값.
///
/// `fetchedAt`과 `observation.observedAt`은 다르다.
/// 전자는 **우리가 받아온 시각**, 후자는 **날씨 데이터 자체의 시각**이다.
/// 캐시 신선도는 앞의 것으로, 화면의 `n분 전` 배지는 뒤의 것으로 판단한다.
public struct CachedObservation: Codable, Sendable, Equatable {
    public let observation: WeatherObservation
    public let fetchedAt: Date

    public init(observation: WeatherObservation, fetchedAt: Date) {
        self.observation = observation
        self.fetchedAt = fetchedAt
    }

    public func age(at now: Date) -> TimeInterval {
        max(0, now.timeIntervalSince(fetchedAt))
    }
}

/// 관측값 캐시.
///
/// 메모리와 디스크 두 층이다. **소스가 하나뿐이라 폴백 대상이 없으므로
/// 캐시가 유일한 방어선이다.** 네트워크가 끊겨도 마지막 값을 보여줄 수 있어야 한다.
///
/// 신선도 판단은 하지 않는다. 저장하고 꺼내줄 뿐이고, 얼마나 오래된 값을
/// 받아들일지는 `WeatherRepository`가 정한다.
public actor WeatherCache {

    private var memory: [String: CachedObservation] = [:]
    private let directory: URL?

    /// - Parameter directory: `nil`이면 메모리에만 담는다. 테스트에서 쓴다.
    public init(directory: URL? = WeatherCache.defaultDirectory) {
        self.directory = directory
        if let directory {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    public static var defaultDirectory: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first?.appending(path: "Weather", directoryHint: .isDirectory)
    }

    public func value(for key: String) -> CachedObservation? {
        if let hit = memory[key] { return hit }
        guard let url = fileURL(for: key),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(CachedObservation.self, from: data)
        else { return nil }
        memory[key] = decoded
        return decoded
    }

    public func store(_ entry: CachedObservation, for key: String) {
        memory[key] = entry
        guard let url = fileURL(for: key), let data = try? JSONEncoder().encode(entry) else { return }
        // 디스크 쓰기 실패로 앱이 멈추지 않는다. 다음 조회에서 다시 받아오면 된다.
        try? data.write(to: url, options: .atomic)
    }

    public func removeAll() {
        memory.removeAll()
        guard let directory else { return }
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func fileURL(for key: String) -> URL? {
        directory?.appending(path: Self.fileName(for: key))
    }

    /// 키를 파일명으로 바꾼다.
    ///
    /// **`hashValue`를 쓰면 안 된다.** Swift의 문자열 해시는 프로세스마다 다른 씨앗을
    /// 쓴다. 그래서 앱을 껐다 켜면 같은 좌표가 다른 파일을 가리키고, 디스크 캐시는
    /// 한 번도 재사용되지 않은 채 파일만 쌓인다. 실제로 그랬다 — 같은 자리에서 세 번
    /// 실행하니 파일이 세 개 생겼다.
    ///
    /// 좌표 키(`"37.500,127.000"`)에는 파일명에 쓰기 곤란한 문자가 섞이므로
    /// 글자와 숫자만 남기고 나머지는 `_`로 바꾼다. 값이 그대로 보여 디버깅에도 낫다.
    static func fileName(for key: String) -> String {
        String(key.map { $0.isLetter || $0.isNumber ? $0 : "_" }) + ".json"
    }
}
