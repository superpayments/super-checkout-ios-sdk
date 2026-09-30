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
            url: "https://github.com/superpayments/super-checkout-ios-sdk/releases/download/0.3.0/SuperCheckoutSDK.xcframework.zip",
            checksum: "e214ffeb2fa98c559b6ade3f7b980e88eb565e6deb2d99ddc09d1d682954c3b1"
        )
    ]
)
