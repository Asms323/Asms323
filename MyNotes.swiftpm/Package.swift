// swift-tools-version: 5.9

// This is a Swift Playgrounds app package.
// Open it in Swift Playgrounds on iPad (or Xcode on a Mac) to build and run it.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "MyNotes",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "MyNotes",
            targets: ["AppModule"],
            bundleIdentifier: "com.asms323.mynotes",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .pencil),
            accentColor: .presetColor(.orange),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
