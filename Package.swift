// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "DITranquillityLinter",
    products: [
        .executable(name: "ditranquillitylint", targets: ["DITranquillityLinter"]),
        .library(name: "DITranquillityLinterFramework", targets: ["DITranquillityLinterFramework"])
    ],
    dependencies: [
        .package(url: "https://github.com/Carthage/Commandant.git", from: "0.15.0"),
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.21.1"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "1.0.0"),
		.package(url: "https://github.com/tuist/xcodeproj.git", .upToNextMajor(from: "6.0.1")),
		.package(url: "https://github.com/kylef/PathKit.git", .exact("0.8.0")),
    ],
    targets: [
		.target(
			name: "DITranquillityLinter",
			dependencies: [
				"Commandant",
				"DITranquillityLinterFramework",
			]),
		.target(
			name: "DITranquillityLinterFramework",
			dependencies: [
				"SourceKittenFramework",
				"Yams",
				"xcodeproj",
				"PathKit",
			]),
    ]
)
