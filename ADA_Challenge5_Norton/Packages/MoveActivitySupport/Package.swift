// swift-tools-version: 6.2
import PackageDescription

// 앱과 Live Activity 확장이 같은 속성·상태·갱신 정책을 공유한다.
let package = Package(
    name: "MoveActivitySupport",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "MoveActivitySupport", targets: ["MoveActivitySupport"])
    ],
    dependencies: [
        .package(path: "../SweatDomain")
    ],
    targets: [
        .target(
            name: "MoveActivitySupport",
            dependencies: ["SweatDomain"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "MoveActivitySupportTests",
            dependencies: ["MoveActivitySupport", "SweatDomain"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        )
    ]
)
