// swift-tools-version:6.0
// Test-only package: `swift test` runs the unit tests without Xcode.
// The app itself is still built from InkBridge.xcodeproj (XcodeGen).
// Tools 6.0 because Swift Testing ships with Swift 6; the app code stays
// in Swift 5 language mode, matching SWIFT_VERSION in project.yml.
import PackageDescription

let package = Package(
    name: "InkBridge",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "InkBridge",
            path: "InkBridge",
            exclude: ["Info.plist", "InkBridge.entitlements", "Resources"]
        ),
        .testTarget(
            name: "InkBridgeTests",
            dependencies: ["InkBridge"],
            path: "Tests/InkBridgeTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
