// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DBXCResultParser-Sonar",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(
            url: "git@github.com:dodobrands/DBXCResultParser",
            .upToNextMajor(from: "3.0.0")
        ),
        .package(
            url: "https://github.com/dodobrands/DBThreadSafe-ios",
            .upToNextMajor(from: "2.0.0")
        ),
        .package(
            url: "https://github.com/CoreOffice/XMLCoder",
            .upToNextMajor(from: "0.17.1")
        ),
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            .upToNextMajor(from: "1.0.0")
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "DBXCResultParser-Sonar",
            dependencies: [
                "DBXCResultParser", 
                "XMLCoder",
                .product(
                    name: "DBThreadSafe",
                    package: "DBThreadSafe-ios"
                ),
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
            ]
        ),
        .testTarget(
            name: "DBXCResultParser-SonarTests",
            dependencies: [
                .product(name: "DBXCResultParser", package: "DBXCResultParser"),
                .product(name: "DBXCResultParserTestHelpers", package: "DBXCResultParser"),
                "DBXCResultParser-Sonar"
            ]
        ),
    ]
)
