import XCTest
@testable import DITranquillityLinterFramework


// Helpers
func extractAliasInfo(registrationToken: RegistrationToken, maximumAliasCount: Int = 1) throws -> AliasToken {
	// Aliases +1 by default cause of implicitly alias to self-registration class name. So we filter that
	let aliases = registrationToken.tokenList.compactMap({ $0.underlyingValue as? AliasToken }).filter({ $0.typeName != registrationToken.typeName || !$0.tag.isEmpty })
	XCTAssertEqual(aliases.count, maximumAliasCount)
	guard let alias = aliases.first else {
		throw TestError.aliasTokenNotFound
	}
	return alias
}

func extractInjectionInfo(registrationToken: RegistrationToken, maximumInjectionCount: Int = 1) throws -> InjectionToken {
	let injections = registrationToken.tokenList.compactMap({ $0.underlyingValue as? InjectionToken })
	XCTAssertLessThanOrEqual(injections.count, maximumInjectionCount)
	guard let firstInjection = injections.first else {
		throw TestError.injectionTokenNotFound
	}
	return firstInjection
}

func extractRegistrationInfo(containerInfo: ContainerPart, maximumRegistrationCount: Int = 1) throws -> RegistrationToken {
	XCTAssertEqual(containerInfo.tokenInfo.count, maximumRegistrationCount)
	guard let registrationList = containerInfo.tokenInfo.first?.value else {
		throw TestError.registrationTokenNotFound
	}
	XCTAssertEqual(registrationList.count, 1)
	guard let registration = registrationList.first else {
		throw TestError.registrationTokenNotFound
	}
	return registration
}

func validateGraph(fileName: String) throws -> [GraphError] {
	let fileURL = pathToSourceFile(with: fileName)
	let tokenizer = Tokenizer(isTestEnvironment: true)
	let collectedInfo = try tokenizer.collectInfo(files: [fileURL])
	let context = try ParsingContext(container: tokenizer.container, collectedInfo: tokenizer.collectInfo(files: [fileURL]))
	let containerBuilder = ContainerInitializatorFinder(parsingContext: context)
	let containerInfoList = containerBuilder.findContainerStructure()
	if containerInfoList.isEmpty {
		throw TestError.containerInfoNotFound
	}
	XCTAssertFalse(containerInfoList.flatMap({ $0.tokenInfo }).isEmpty)
	let validator = GraphValidator()
	return containerInfoList.flatMap {
		validator.validate(containerPart: $0, collectedInfo: collectedInfo)
	}
}

func findContainerStructure(fileName: String) throws -> ContainerPart {
	let fileURL = pathToSourceFile(with: fileName)
	return try findContainerStructure(fullPathToFile: fileURL)
}

func findContainerStructure(fullPathToFile fileURL: String) throws -> ContainerPart {
	let tokenizer = Tokenizer(isTestEnvironment: true)
	let context = try ParsingContext(container: tokenizer.container, collectedInfo: tokenizer.collectInfo(files: [fileURL]))
	let containerBuilder = ContainerInitializatorFinder(parsingContext: context)
	guard let containerInfo = containerBuilder.findContainerStructure().first else {
		throw TestError.containerInfoNotFound
	}
	return containerInfo
}

func pathToSourceFile(with name: String) -> String {
	let bundle = Bundle(path: FileManager.default.currentDirectoryPath + "/TestFiles.bundle")!
	return bundle.path(forResource: name, ofType: "swift")!
}

func pathsToSourceFiles() -> [String] {
	let bundle = Bundle(path: FileManager.default.currentDirectoryPath + "/TestFiles.bundle")!
	return bundle.paths(forResourcesOfType: "swift", inDirectory: nil)
}
