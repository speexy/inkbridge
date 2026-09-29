// swift-tools-version:5.9
// Test-only package: `swift test` runs the unit tests without Xcode.
// The app itself is still built from InkBridge.xcodeproj (XcodeGen).
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
    ]
)
