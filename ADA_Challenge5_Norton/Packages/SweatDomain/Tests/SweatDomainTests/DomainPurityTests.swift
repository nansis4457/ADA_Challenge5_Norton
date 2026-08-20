import Foundation
import Testing
@testable import SweatDomain

/// 소스 트리 위치. `#filePath`는 컴파일 시점의 절대 경로다.
enum PackageLayout {
    /// `.../Packages/SweatDomain`
    static let root = URL(filePath: #filePath)
        .deletingLastPathComponent()   // SweatDomainTests
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // SweatDomain

    static var manifest: URL { root.appending(path: "Package.swift") }
    static var sourcesDirectory: URL { root.appending(path: "Sources/SweatDomain") }

    /// 소스가 함께 있는 환경에서만 검사한다.
    /// 빌드 산출물만 배포된 환경에서는 이 검사를 건너뛴다.
    static var isAvailable: Bool {
        FileManager.default.fileExists(atPath: manifest.path)
    }

    static func swiftFiles(in directory: URL) throws -> [URL] {
        try FileManager.default
            .contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// 한 줄 주석과 블록 주석을 제거한 소스.
    ///
    /// 완전한 파서가 아니라 휴리스틱이다. 문자열 리터럴 안의 `//`는 구분하지 못한다.
    /// 이 검사의 목적은 실수로 흩어진 숫자 리터럴을 잡는 것이지 파싱이 아니다.
    static func strippingComments(_ source: String) -> String {
        var inBlock = false
        var kept: [String] = []
        for var line in source.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            if inBlock {
                guard let end = line.range(of: "*/") else { continue }
                line = String(line[end.upperBound...])
                inBlock = false
            }
            if let start = line.range(of: "/*") {
                let head = String(line[..<start.lowerBound])
                if let end = line.range(of: "*/", range: start.upperBound..<line.endIndex) {
                    line = head + String(line[end.upperBound...])
                } else {
                    line = head
                    inBlock = true
                }
            }
            if let slashes = line.range(of: "//") {
                line = String(line[..<slashes.lowerBound])
            }
            kept.append(line)
        }
        return kept.joined(separator: "\n")
    }
}

@Suite("도메인 순수성 — 규칙 「도메인은 순수하게」 · V", .enabled(if: PackageLayout.isAvailable))
struct DomainPurityTests {

    /// R2 · 규칙 「도메인은 순수하게」 — 도메인은 Foundation 외에 아무것도 의존하지 않는다.
    @Test("매니페스트에 외부 의존성이 없다")
    func manifestHasNoDependencies() throws {
        let manifest = try String(contentsOf: PackageLayout.manifest, encoding: .utf8)
        let code = PackageLayout.strippingComments(manifest)
        #expect(
            !code.contains(".package("),
            """
            SweatDomain에 외부 의존성이 추가되었습니다.
            규칙 「도메인은 순수하게」을 먼저 개정하지 않으면 추가할 수 없습니다.
            """
        )
    }

    /// 규칙 「도메인은 순수하게」 — 소스에서 Foundation 외 import 금지.
    @Test("Foundation 외의 import가 없다")
    func onlyImportsFoundation() throws {
        let allowed: Set<String> = ["Foundation"]
        for file in try PackageLayout.swiftFiles(in: PackageLayout.sourcesDirectory) {
            let code = PackageLayout.strippingComments(
                try String(contentsOf: file, encoding: .utf8))
            for line in code.split(separator: "\n") where line.hasPrefix("import ") {
                let module = line.dropFirst("import ".count).trimmingCharacters(in: .whitespaces)
                #expect(
                    allowed.contains(module),
                    "\(file.lastPathComponent)가 \(module)을 import합니다 (규칙 「도메인은 순수하게」 위반)"
                )
            }
        }
    }

    /// R5 · 규칙 「경계값은 한 곳에」 — 구간 경계값은 `SweatStage.boundaries` 한 곳에만 존재한다.
    ///
    /// 정규식으로 숫자 "모양"을 찾지 않고, 숫자 리터럴을 뽑아 **값으로** 비교한다.
    /// `33`과 `33.0`은 같은 경계값이고 `33.5`는 아니다. 문자열 매칭으로는
    /// 이 구분이 안 된다 (실제로 첫 구현이 `33.0`을 놓쳤다).
    @Test("경계값 리터럴이 SweatStage 밖에 흩어져 있지 않다")
    func boundaryLiteralsAreNotScattered() throws {
        let boundaries = Set(SweatStage.boundaries)
        let numberPattern = try NSRegularExpression(pattern: #"\d+(?:\.\d+)?"#)
        let singleSource = "SweatStage.swift"

        for file in try PackageLayout.swiftFiles(in: PackageLayout.sourcesDirectory)
        where file.lastPathComponent != singleSource {
            let code = PackageLayout.strippingComments(
                try String(contentsOf: file, encoding: .utf8))
            let range = NSRange(code.startIndex..., in: code)

            let offenders = numberPattern.matches(in: code, range: range)
                .compactMap { Range($0.range, in: code).map { String(code[$0]) } }
                .compactMap(Double.init)
                .filter(boundaries.contains)

            #expect(
                offenders.isEmpty,
                """
                \(file.lastPathComponent)에 구간 경계값 \(Set(offenders).sorted())이 등장합니다.
                경계는 \(singleSource)의 boundaries 배열에만 있어야 합니다 (규칙 「경계값은 한 곳에」).
                """
            )
        }
    }
}
