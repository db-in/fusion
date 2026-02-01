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
		),
		.library(
			name: "FusionCore",
			targets: ["FusionCore"]
		),
		.library(
			name: "FusionUI",
			targets: ["FusionUI"]
		)
	],
	dependencies: [
	],
	targets: [
		.target(
			name: "Fusion",
			dependencies: ["FusionCore", "FusionUI"],
			path: "Fusion",
			resources: [
				.process("**/*.xcprivacy")
			],
			swiftSettings: [
				.define("GENERATE_INFOPLIST_FILE")
			]
		),
		.target(
			name: "FusionCore",
			dependencies: [],
			path: "Fusion/Core",
			publicHeadersPath: ".",
			cSettings: [
				.headerSearchPath(".")
			],
			swiftSettings: [
				.define("GENERATE_INFOPLIST_FILE")
			],
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
			publicHeadersPath: ".",
			cSettings: [
				.headerSearchPath(".")
			],
			swiftSettings: [
				.define("GENERATE_INFOPLIST_FILE")
			],
			linkerSettings: [
				.linkedFramework("UIKit")
			]
		)
	]
)
