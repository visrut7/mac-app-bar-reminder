// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TwoDo",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "TwoDo",
            path: "Sources/TwoDo"
        )
    ]
)
