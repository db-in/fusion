import PackageDescription

let package = Package(
    name: "Fusion",
    products: [
        .library(
            name: "Fusion",
            targets: ["Fusion"]
        ),
    ],
    targets: [
        .target(
            name: "Fusion",
            dependencies: []
        ),
        .testTarget(
            name: "FusionTests",
            dependencies: ["Fusion"]
        ),
    ]
)
