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
        // 좌표가 키라서 파일명에 못 쓰는 문자가 섞인다. 해시로 바꾼다.
        directory?.appending(path: "\(key.hashValue).json")
    }
}
