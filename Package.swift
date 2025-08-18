// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WallyHub",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "WallyHub",
            targets: ["WallyHub"]),
    ],
    dependencies: [
        .package(url: "https://github.com/uber/RIBs.git", from: "0.16.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.29.0"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.0.0")
    ],
    targets: [
        .target(
            name: "WallyHub",
            dependencies: [
                .product(name: "RIBs", package: "RIBs"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxRelay", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift")
            ],
            path: "WallyHub"
        ),
        .testTarget(
            name: "WallyHubTests",
            dependencies: ["WallyHub"])
    ]
)