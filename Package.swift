// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TaskSplitter",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "TaskSplitter",
            path: "Sources/TaskSplitter"
        )
    ]
)
