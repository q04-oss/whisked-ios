// swift-tools-version: 5.9
//
// NOT a buildable package — the actual app lives inside an Xcode project
// (`Whisked.xcodeproj`, created on a Mac per the README). This manifest
// documents the third-party SPM dependencies the Xcode project must add:
//
//   File → Add Package Dependencies →
//     https://github.com/stripe/stripe-ios
//   Add product `StripePaymentSheet` to the Whisked target.
//
// Keeping the manifest in the repo lets `swift package show-dependencies`
// and Renovate / Dependabot reason about the dep, even though
// `swift build` won't produce a runnable artifact here.
import PackageDescription

let package = Package(
    name: "Whisked",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(
            url: "https://github.com/stripe/stripe-ios",
            from: "25.16.0"
        ),
    ],
    targets: [
        .target(
            name: "Whisked",
            dependencies: [
                .product(name: "StripePaymentSheet", package: "stripe-ios"),
            ],
            path: "Whisked"
        ),
    ]
)
