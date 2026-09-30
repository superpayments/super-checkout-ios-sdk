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
            url: "https://github.com/superpayments/super-checkout-ios-sdk/releases/download/0.2.0/SuperCheckoutSDK.xcframework.zip",
            checksum: "52395a35dc4c7c46ee5c40d2c4db915d40e67ca948920e9d2f13f5c401c8d3b0"
        )
    ]
)
