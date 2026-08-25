// swift-tools-version: 6.2
import PackageDescription

// WeatherKit 호출을 감싸고 캐시와 실패 경로를 책임진다.
// 화면은 이 패키지 너머를 모른다.
let package = Package(
    name: "WeatherData",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "WeatherData", targets: ["WeatherData"])
    ],
    dependencies: [
        .package(path: "../SweatDomain")
    ],
    targets: [
        .target(name: "WeatherData", dependencies: ["SweatDomain"]),
        .testTarget(name: "WeatherDataTests", dependencies: ["WeatherData"])
    ]
)
