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
            url: "https://github.com/superpayments/super-checkout-ios-sdk/releases/download/1.0.0/SuperCheckoutSDK.xcframework.zip",
            checksum: "a13c1c1a331f9f45c7dd395898ebb628a3ae0bb0ed40f82f07de4d955fab743d"
        )
    ]
)
