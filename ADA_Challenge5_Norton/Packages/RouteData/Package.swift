// swift-tools-version: 6.2
import PackageDescription

// 장소 검색·도보 경로·노출 분석 공급자를 화면에서 분리한다.
// MapKit 타입은 이 패키지 밖으로 내보내지 않는다.
let package = Package(
    name: "RouteData",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "RouteData", targets: ["RouteData"])
    ],
    dependencies: [
        .package(path: "../SweatDomain")
    ],
    targets: [
        .target(
            name: "RouteData",
            dependencies: ["SweatDomain"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "RouteDataTests",
            dependencies: ["RouteData", "SweatDomain"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        )
    ]
)
