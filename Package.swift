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
		)
	],
	dependencies: [
	],
	targets: [
		.target(
			name: "Fusion",
			dependencies: ["FusionCore", "FusionUI"],
			path: "Fusion",
			exclude: ["Core", "UI"],
			sources: ["Fusion.swift"],
			resources: [
				.process("PrivacyInfo.xcprivacy")
			],
			swiftSettings: [
				.define("GENERATE_INFOPLIST_FILE")
			]
		),
		.target(
			name: "FusionCore",
			dependencies: [],
			path: "Fusion/Core",
			sources: ["Sources"],
			resources: [
				.process("../PrivacyInfo.xcprivacy")
			],
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
				.linkedLibrary("CommonCrypto", .when(platforms: [.macOS, .iOS, .tvOS, .watchOS])),
				.linkedFramework("UserNotifications")
			]
		),
		.target(
			name: "FusionUI",
			dependencies: ["FusionCore"],
			path: "Fusion/UI",
			sources: ["Sources"],
			publicHeadersPath: ".",
			cSettings: [
				.headerSearchPath(".")
			],
			swiftSettings: [
				.define("GENERATE_INFOPLIST_FILE")
			],
			linkerSettings: [
				.linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS, .watchOS]))
			]
		)
	]
)
