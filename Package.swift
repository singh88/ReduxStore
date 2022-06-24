// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "ReduxStore",
    platforms: [
            .iOS(.v13)
        ],
    products: [
        .library(
            name: "ReduxStore",
            targets: ["ReduxStore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.5.0"),
        .package(url: "https://github.com/RxSwiftCommunity/RxDataSources.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "ReduxStore",
            dependencies: ["RxSwift",
                .product(name: "RxCocoa",
                         package: "RxSwift"),
                           "RxDataSources"]),
        .testTarget(name: "ReduxStoreTests",
                    dependencies: ["ReduxStore"])
    ]
)
