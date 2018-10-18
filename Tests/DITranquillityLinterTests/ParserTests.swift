import XCTest
@testable import DITranquillityLinterFramework

final class ParserTests: XCTestCase {
	
	
	static var allTests = [
		("testDefaultMakingRegistration", testDefaultMakingRegistration),
		]
	
	// .default()
	func testDefaultMakingRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestDefaultMakingRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let containsDefault = registration.tokenList.contains(where: { $0 is IsDefaultToken })
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
		let tokenizer = Tokenizer()
		let fileURL = pathToSourceFile(with: "TestInvalidMethodCallingRegistration")
		let context = ParsingContext(container: tokenizer.container, collectedInfo: tokenizer.collectInfo(files: [fileURL]))
		guard let _ = ContainerInitializatorFinder.findContainerStructure(parsingContext: context) else {
			throw TestError.containerInfoNotFound
		}
		XCTAssertFalse(context.errors.isEmpty, "Should not allow container passing between methods")
	}
	
	// invalidInjectionMethod(c: container) in static let container: DIContainer = { ... }
	func testInitialDefinitionInvalidMethodCallingRegistration() throws {
		let tokenizer = Tokenizer()
		let fileURL = pathToSourceFile(with: "TestInitialDefinitionInvalidMethodCallingRegistration")
		let context = ParsingContext(container: tokenizer.container, collectedInfo: tokenizer.collectInfo(files: [fileURL]))
		guard let _ = ContainerInitializatorFinder.findContainerStructure(parsingContext: context) else {
			throw TestError.containerInfoNotFound
		}
		XCTAssertFalse(context.errors.isEmpty, "Should not allow container passing between methods")
	}
	
	// Space in file name
	func testSpacedPlainRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: " TestSpacedPlainRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass")
	}
	
}
