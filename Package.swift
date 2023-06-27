// swift-tools-version:5.3
import PackageDescription

let package = Package(
	name: "Fusion",
	platforms: [
		.macOS(.v11),
		.iOS(.v13),
		.tvOS(.v13),
		.watchOS(.v7)
	],
	products: [
		.library(
			name: "Fusion",
			targets: ["Fusion"]
		)
	],
	dependencies: [
		// No external dependencies specified
	],
	targets: [
		.target(
			name: "Fusion",
			dependencies: ["FusionCore", "FusionUI"],
			path: "Fusion",
			sources: ["Core", "UI"],
			publicHeadersPath: "Core",
			cSettings: [
				.headerSearchPath("Core"),
				.headerSearchPath("UI"),
				.define("GENERATE_INFOPLIST_FILE")
			],
			swiftSettings: [
				.define("GENERATE_INFOPLIST_FILE")
			]
		),
		.target(
			name: "FusionCore",
			dependencies: [],
			path: "Fusion/Core",
			sources: ["**/*.{h,m,swift}"],
			publicHeadersPath: ".",
			linkerSettings: [
				.linkedFramework("Foundation"),
				.linkedFramework("Security"),
				.linkedFramework("CommonCrypto"),
				.linkedFramework("UserNotifications")
			]
		),
		.target(
			name: "FusionUI",
			dependencies: ["FusionCore"],
			path: "Fusion/UI",
			sources: ["**/*.{h,m,swift}"],
			resources: [
				.process("UI/**/*.xib"),
				.process("UI/**/*.xcassets"),
				.process("UI/**/*.storyboard"),
				.process("UI/**/*.json"),
				.process("UI/**/*.lproj"),
				.process("UI/**/*.ttf")
			],
			publicHeadersPath: ".",
			swiftSettings: [
				.define("GENERATE_INFOPLIST_FILE")
			],
			linkerSettings: [
				.linkedFramework("UIKit")
			]
		)
	]
)
