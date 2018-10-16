import XCTest
@testable import DITranquillityLinterFramework


// Helpers
func extractAliasInfo(registrationToken: RegistrationToken, maximumAliasCount: Int = 1) throws -> AliasToken {
	// Aliases +1 by default cause of implicitly alias to self-registration class name. So we filter that
	let aliases = registrationToken.tokenList.compactMap({ $0 as? AliasToken }).filter({ $0.typeName != registrationToken.typeName || !$0.tag.isEmpty })
	XCTAssertEqual(aliases.count, maximumAliasCount)
	guard let alias = aliases.first else {
		throw TestError.aliasTokenNotFound
	}
	return alias
}

func extractInjectionInfo(registrationToken: RegistrationToken, maximumInjectionCount: Int = 1) throws -> InjectionToken {
	let injections = registrationToken.tokenList.compactMap({ $0 as? InjectionToken })
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
	let tokenizer = Tokenizer()
	let collectedInfo = tokenizer.collectInfo(files: [fileURL])
	guard let containerInfo = ContainerInitializatorFinder.findContainerStructure(dictionary: collectedInfo, fileContainer: tokenizer.container) else {
		throw TestError.containerInfoNotFound
	}
	XCTAssertFalse(containerInfo.tokenInfo.isEmpty)
	let validator = GraphValidator()
	return validator.validate(containerPart: containerInfo, collectedInfo: collectedInfo)
}

func findContainerStructure(fileName: String) throws -> ContainerPart {
	let tokenizer = Tokenizer()
	let fileURL = pathToSourceFile(with: fileName)
	guard let containerInfo = ContainerInitializatorFinder.findContainerStructure(dictionary: tokenizer.collectInfo(files: [fileURL]), fileContainer: tokenizer.container) else {
		throw TestError.containerInfoNotFound
	}
	return containerInfo
}

func pathToSourceFile(with name: String) -> URL {
	let pathToTestableSource = "/Users/nikitapatskov/Develop/DITranquillityLinter/LintableProject/LintableProject/Testable/"
	return URL(fileURLWithPath: pathToTestableSource + name + ".swift", isDirectory: false)
}
