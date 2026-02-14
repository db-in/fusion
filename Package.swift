// swift-tools-version:5.7
import PackageDescription

let package = Package(
	name: "Fusion",
	platforms: [
		.macOS(.v12),
		.iOS(.v15),
		.tvOS(.v15),
		.watchOS(.v9)
	],
	products: [
		.library(
			name: "Fusion",
			targets: ["Fusion"]
		)
	],
	dependencies: [
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
		)
	]
)
