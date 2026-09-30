// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SuperCheckoutSDK",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "SuperCheckoutSDK", targets: ["SuperCheckoutSDK"])
    ],
    targets: [
        .binaryTarget(
            name: "SuperCheckoutSDK",
            url: "https://github.com/superpayments/super-checkout-ios-sdk/releases/download/0.1.0/SuperCheckoutSDK.xcframework.zip",
            checksum: "e05b93869791c5071129f932c0dd899910e9babd6bfdd33ede793f54d458af37"
        )
    ]
)
