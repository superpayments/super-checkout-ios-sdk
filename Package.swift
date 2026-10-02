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
            url: "https://github.com/superpayments/super-checkout-ios-sdk/releases/download/1.0.1/SuperCheckoutSDK.xcframework.zip",
            checksum: "fc599d9acbcc77f66c1519a5f830df06bd71cee484ff9aff4f4450fc8afda519"
        )
    ]
)
