// swift-tools-version: 6.2
import PackageDescription

// 전부 UI 코드이므로 기본 액터 격리를 MainActor로 둔다.
// 앱 타깃의 SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor 와 동일한 방침이며,
// 로컬 패키지는 Xcode 타깃 설정을 상속하지 않으므로 여기서 명시해야 한다.
let package = Package(
    name: "DesignSystem",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"])
    ],
    targets: [
        .target(
            name: "DesignSystem",
            swiftSettings: [.defaultIsolation(MainActor.self)]
        )
    ]
)
