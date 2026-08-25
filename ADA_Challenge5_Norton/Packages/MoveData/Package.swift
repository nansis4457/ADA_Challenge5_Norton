// swift-tools-version: 6.2
import PackageDescription

// 위치·백그라운드 활동·로컬 알림을 화면과 도메인에서 분리한다.
let package = Package(
    name: "MoveData",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "MoveData", targets: ["MoveData"])
    ],
    dependencies: [
        .package(path: "../SweatDomain")
    ],
    targets: [
        .target(
            name: "MoveData",
            dependencies: ["SweatDomain"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "MoveDataTests",
            dependencies: ["MoveData", "SweatDomain"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        )
    ]
)
