// swift-tools-version: 6.2
import PackageDescription

// 헌법 I — 도메인 순수성.
// dependencies는 비어 있어야 한다. 이 배열에 무언가 추가하려면 헌법을 먼저 고친다.
let package = Package(
    name: "SweatDomain",
    products: [
        .library(name: "SweatDomain", targets: ["SweatDomain"])
    ],
    targets: [
        .target(name: "SweatDomain"),
        .testTarget(name: "SweatDomainTests", dependencies: ["SweatDomain"])
    ]
)
