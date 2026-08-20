// swift-tools-version: 6.2
import PackageDescription

// 프로필은 키-값에, 기록은 SwiftData에 둔다.
// 이렇게 나누면 001에서 005로 넘어갈 때 마이그레이션이 생기지 않는다.
let package = Package(
    name: "SweatPersistence",
    products: [
        .library(name: "SweatPersistence", targets: ["SweatPersistence"])
    ],
    dependencies: [
        .package(path: "../SweatDomain")
    ],
    targets: [
        .target(name: "SweatPersistence", dependencies: ["SweatDomain"]),
        .testTarget(name: "SweatPersistenceTests", dependencies: ["SweatPersistence"])
    ]
)
