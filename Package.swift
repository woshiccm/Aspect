// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Aspect",
    products: [
        .library(
            name: "Aspect",
            targets: ["Aspect"])
    ],
    targets: [
        .target(
            name: "Aspect",
            path: "Aspect")
    ],
    swiftLanguageVersions: [.v4, .v5]
)
