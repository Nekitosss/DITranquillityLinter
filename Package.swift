// swift-tools-version:5.0
import PackageDescription

let package = Package(
	name: "DITranquillityLinter",
	products: [
		.executable(name: "dilinter", targets: ["DITranquillityLinter"]),
	],
	dependencies: [
		.package(url: "https://github.com/tuist/xcodeproj.git", .upToNextMajor(from: "7.0.0")),
		.package(url: "https://github.com/kylef/PathKit.git", .upToNextMajor(from: "1.0.0")),
		.package(url: "https://github.com/Carthage/Commandant.git", from: "0.17.0"),
		.package(url: "https://github.com/jpsim/Yams.git", .upToNextMajor(from: "2.0.0")),
		.package(url: "https://github.com/ivlevAstef/DITranquillity", .upToNextMajor(from: "3.0.0")),
		.package(url: "https://github.com/Nekitosss/swift-ast-visitor.git", from: "0.0.1"),
	],
	targets: [
		.target(
			name: "DITranquillityLinter",
			dependencies: [
				"DITranquillityLinterFramework",
				"Commandant",
				"Yams",
				"DITranquillity",
			]),
		.target(
			name: "DITranquillityLinterFramework",
			dependencies: [
				"XcodeProj",
				"PathKit",
				"DITranquillity",
				"ASTVisitor",
			]),
		.testTarget(
			name: "DITranquillityLinterTests",
			dependencies: ["DITranquillityLinterFramework"]),
	]
)



