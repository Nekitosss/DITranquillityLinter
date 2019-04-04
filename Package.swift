// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "DITranquillityLinter",
    products: [
        .executable(name: "ditranquillity", targets: ["DITranquillityLinter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.21.2"),
		.package(url: "https://github.com/tuist/xcodeproj.git", .upToNextMajor(from: "6.0.1")),
		.package(url: "https://github.com/kylef/PathKit.git", .upToNextMajor(from: "0.9.2")),
		.package(url: "https://github.com/Carthage/Commandant.git", from: "0.15.0"),
		.package(url: "https://github.com/jpsim/Yams.git", from: "1.0.1"),
		],
    targets: [
		.target(
			name: "DITranquillityLinter",
			dependencies: [
				"DITranquillityLinterFramework",
				"Commandant",
				"Yams",
			]),
		.target(
			name: "DITranquillityLinterFramework",
			dependencies: [
				"SourceKittenFramework",
				"xcodeproj",
				"PathKit",
			]),
		.testTarget(
			name: "DITranquillityLinterTests",
			dependencies: ["DITranquillityLinterFramework"]),
    ]
)
