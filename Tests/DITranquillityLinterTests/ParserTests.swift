import XCTest
@testable import DITranquillityLinterFramework

final class ParserTests: XCTestCase {
	
	
	static var allTests = [
		("testDefaultMakingRegistration", testDefaultMakingRegistration),
		]
	
	override func tearDown() {
		clearTestArtifacts()
	}
	
	// .default()
	func testDefaultMakingRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestDefaultMakingRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let containsDefault = registration.tokenList.contains(where: { $0.underlyingValue is IsDefaultToken })
		XCTAssertTrue(containsDefault, "Could not parse '.default()' token")
	}
	
	// class ParsablePart: DIPart
	// class SecondParsablePart: DIPart
	// class ThirdParsablePart: DIFramework
	func testSeveralDIParts() throws {
		let containerInfo = try findContainerStructure(fileName: "TestSeveralDIParts")
		XCTAssertEqual(containerInfo.tokenInfo.count, 3)
		let registrations = containerInfo.tokenInfo.values.flatMap({ $0 })
		XCTAssertEqual(registrations.count, 3)
		let nameSet = Set(registrations.map({ $0.typeName }))
		XCTAssertEqual(nameSet.count, 3, "We should have 3 different registrations")
	}
	
	// invalidInjectionMethod(c: container)
	func testInvalidMethodCallingRegistration() throws {
		let tokenizer: Tokenizer = container.resolve()
		let fileURL = pathToSourceFile(with: "TestInvalidMethodCallingRegistration")
		let context = try GlobalParsingContext(container: tokenizer.container, collectedInfo: tokenizer.collectInfo(files: [fileURL]), astFilePaths: [])
		let containerBuilder = ContainerInitializatorFinder(parsingContext: context)
		let containerPart = containerBuilder.findContainerStructure(separatlyIncludePublicParts: false)
		
		XCTAssertNotNil(containerPart, TestError.containerInfoNotFound.rawValue)
		XCTAssertFalse(context.errors.isEmpty, "Should not allow container passing between methods")
	}
	
	// invalidInjectionMethod(c: container) in static let container: DIContainer = { ... }
	func testInitialDefinitionInvalidMethodCallingRegistration() throws {
		let tokenizer: Tokenizer = container.resolve()
		let fileURL = pathToSourceFile(with: "TestInitialDefinitionInvalidMethodCallingRegistration")
		let context = try GlobalParsingContext(container: tokenizer.container, collectedInfo: tokenizer.collectInfo(files: [fileURL]), astFilePaths: [])
		let containerBuilder = ContainerInitializatorFinder(parsingContext: context)
		let containerPart = containerBuilder.findContainerStructure(separatlyIncludePublicParts: false)
		
		XCTAssertNotNil(containerPart, TestError.containerInfoNotFound.rawValue)
		XCTAssertFalse(context.errors.isEmpty, "Should not allow container passing between methods")
	}
	
	// Space in file name
	func testSpacedPlainRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: " TestSpacedPlainRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass")
	}
	
	// Two containers in single file
	func testSeveralContainerCreation() throws {
		let astEmitter: ASTEmitter = container.resolve()
		let tokenizer: Tokenizer = container.resolve()
		let fileURL = pathToSourceFile(with: "TestSeveralContainerCreation")
		let astFilePath = try astEmitter.emitAST(from: [fileURL]).first!
		let context = try GlobalParsingContext(container: tokenizer.container, collectedInfo: tokenizer.collectInfo(files: [fileURL]), astFilePaths: [astFilePath])
		let containerBuilder = ContainerInitializatorFinder(parsingContext: context)
		let containerInfo = containerBuilder.findContainerStructure(separatlyIncludePublicParts: false)
		
		XCTAssertEqual(containerInfo.count, 2, "Could not find several containers in single file")
	}
	
	// Two containers in two files
	func testSeveralContainerCreationSeveralFiles() throws {
		let astEmitter: ASTEmitter = container.resolve()
		let tokenizer: Tokenizer = container.resolve()
		// Remember to check part and class unique in two provided swift files.
		// If you stuck and think WTF is happening, check two provided files proper compilation
		let fileURL1 = pathToSourceFile(with: "TestInitialDefinitionInvalidMethodCallingRegistration")
		let fileURL2 = pathToSourceFile(with: "TestInvalidMethodCallingRegistration")
		let astFilePath = try astEmitter.emitAST(from: [fileURL1, fileURL2])
		let context = try GlobalParsingContext(container: tokenizer.container, collectedInfo: tokenizer.collectInfo(files: [fileURL1, fileURL2]), astFilePaths: astFilePath)
		let containerBuilder = ContainerInitializatorFinder(parsingContext: context)
		let containerInfo = containerBuilder.findContainerStructure(separatlyIncludePublicParts: false)
		
		XCTAssertEqual(containerInfo.count, 2, "Could not find several containers in several files")
	}
	
}
