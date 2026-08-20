// swift-tools-version: 6.2
import PackageDescription

// 화면 코드. 앱 타깃은 얇게 유지한다.
// 전부 UI이므로 기본 액터 격리를 MainActor로 둔다.
let package = Package(
    name: "SweatFeatures",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "SweatFeatures", targets: ["SweatFeatures"])
    ],
    dependencies: [
        .package(path: "../SweatDomain"),
        .package(path: "../SweatPersistence"),
        .package(path: "../DesignSystem")
    ],
    targets: [
        .target(
            name: "SweatFeatures",
            dependencies: ["SweatDomain", "SweatPersistence", "DesignSystem"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "SweatFeaturesTests",
            dependencies: ["SweatFeatures"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        )
    ]
)
