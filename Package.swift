// swift-tools-version:4.2
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
		.package(url: "https://github.com/apple/swift-protobuf.git", from: "1.2.0"),
		.package(url: "https://github.com/Carthage/Commandant.git", from: "0.15.0"),
		],
    targets: [
		.target(
			name: "DITranquillityLinter",
			dependencies: [
				"DITranquillityLinterFramework",
			]),
		.target(
			name: "DITranquillityLinterFramework",
			dependencies: [
				"SourceKittenFramework",
				"xcodeproj",
				"PathKit",
				"SwiftProtobuf",
				"Commandant",
			]),
		.testTarget(
			name: "DITranquillityLinterTests",
			dependencies: ["DITranquillityLinterFramework"]),
    ]
)
