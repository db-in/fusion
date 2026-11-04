// swift-tools-version:6.0
import PackageDescription

let package = Package(
	name: "Fusion",
	platforms: [
		.macOS(.v14),
		.iOS(.v17),
		.tvOS(.v17),
		.watchOS(.v10)
	],
	products: [
		.library(
			name: "Fusion",
			targets: ["Fusion"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/db-in/LocalServer.git", from: "2.1.7")
	],
	targets: [
		.target(
			name: "Fusion",
			dependencies: [],
			path: "Fusion",
			sources: ["Core/Sources", "UI/Sources"],
			resources: [
				.process("PrivacyInfo.xcprivacy")
			],
			swiftSettings: [
				.define("GENERATE_INFOPLIST_FILE")
			],
			linkerSettings: [
				.linkedFramework("Foundation"),
				.linkedFramework("Security"),
				.linkedFramework("UserNotifications"),
				.linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS, .watchOS])),
				.linkedFramework("AppKit", .when(platforms: [.macOS]))
			]
		),
		.testTarget(
			name: "FusionTests",
			dependencies: [
				"Fusion",
				.product(name: "LocalServer", package: "LocalServer")
			],
			path: "Fusion/Tests",
			resources: [
				.process("JSON")
			],
			swiftSettings: [
				.define("GENERATE_INFOPLIST_FILE")
			]
		)
	],
	swiftLanguageModes: [.v5]
)
