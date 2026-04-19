// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SlackMenuBadge",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "SlackMenuBadge",
            targets: ["SlackMenuBadge"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "SlackMenuBadge"
        ),
    ]
)
