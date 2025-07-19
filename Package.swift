// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PomodoroTodo",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "PomodoroTodo", targets: ["PomodoroTodo"])
    ],
    targets: [
        .executableTarget(
            name: "PomodoroTodo",
            dependencies: [],
            path: "Sources"
        )
    ]
)