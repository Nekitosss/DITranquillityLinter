// swift-tools-version:5.0
import PackageDescription

let package = Package(
	name: "DITranquillityLinter",
	products: [
		.executable(name: "ditranquillity", targets: ["DITranquillityLinter"]),
	],
	dependencies: [
		.package(url: "https://github.com/tuist/xcodeproj.git", .upToNextMajor(from: "6.0.1")),
		.package(url: "https://github.com/kylef/PathKit.git", .upToNextMajor(from: "0.9.2")),
		.package(url: "https://github.com/Carthage/Commandant.git", from: "0.15.0"),
		.package(url: "https://github.com/jpsim/Yams.git", from: "1.0.1"),
		.package(url: "https://github.com/ivlevAstef/DITranquillity", from: "3.6.3"),
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
				"xcodeproj",
				"PathKit",
				"DITranquillity",
				"ASTVisitor",
			]),
		.testTarget(
			name: "DITranquillityLinterTests",
			dependencies: ["DITranquillityLinterFramework"]),
	]
)



