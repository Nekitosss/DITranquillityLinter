

import XCTest
@testable import DITranquillityLinterFramework

class ValidatorTests: XCTestCase {

	static var allTests = [
		("testValidateAliasingSuccess", testValidateAliasingSuccess),
		]
	
	override func tearDown() {
		clearTestArtifacts()
	}
	
	// Check intermediate token (alias, injection) adding to registration
	func testRegistrationTokenIntermediateTokenAppending() throws {
		let errorList = try validateGraph(fileName: "TestRegistrationTokenIntermediateTokenAppending")
		XCTAssertTrue(errorList.isEmpty, "Lost alias for registration")
	}
	
	func testValidateAliasingSuccess() throws {
		let errorList = try validateGraph(fileName: "TestValidateAliasingSuccess")
		XCTAssertTrue(errorList.isEmpty)
	}

	// Disabled cause of grabbing protocol implemendation not implemented)
//	func testValidatePlainAliasingError() throws {
//		let errorList = try validateGraph(fileName: "TestValidatePlainAliasingError")
//		XCTAssertFalse(errorList.isEmpty)
//	}
//
//	func testComposedTypealiasError() throws {
//		let errorList = try validateGraph(fileName: "TestComposedTypealiasError")
//		XCTAssertFalse(errorList.isEmpty)
//	}
//
//	func testComposedTypealiasFailure() throws {
//		let errorList = try validateGraph(fileName: "TestComposedTypealiasFailure")
//		XCTAssertFalse(errorList.isEmpty)
//	}
//
//	func testTypealiasedComposedAliasingFailure() throws {
//		let errorList = try validateGraph(fileName: "TestTypealiasedComposedAliasingFailure")
//		XCTAssertFalse(errorList.isEmpty)
//	}
	
	func testTypealiasedAliasingSuccess() throws {
		let errorList = try validateGraph(fileName: "TestTypealiasedAliasingSuccess")
		XCTAssertTrue(errorList.isEmpty)
	}
	
	func testFullTypealiasedAliasingSuccess() throws {
		let errorList = try validateGraph(fileName: "TestFullTypealiasedAliasingSuccess")
		XCTAssertTrue(errorList.isEmpty)
	}
	
	func testComposedTypealiasSuccess() throws {
		let errorList = try validateGraph(fileName: "TestComposedTypealiasSuccess")
		XCTAssertTrue(errorList.isEmpty)
	}
	
	func testTypealiasedComposedTypealiasSuccess() throws {
		let errorList = try validateGraph(fileName: "TestTypealiasedComposedTypealiasSuccess")
		XCTAssertTrue(errorList.isEmpty)
	}
	
	func testFullTypealiasedComposedAliasingSuccess() throws {
		let errorList = try validateGraph(fileName: "TestFullTypealiasedComposedAliasingSuccess")
		XCTAssertTrue(errorList.isEmpty)
	}
	
	func testPlainInjectionValidation() throws {
		let errorList = try validateGraph(fileName: "TestPlainInjectionValidation")
		XCTAssertTrue(errorList.isEmpty)
	}
	
	func testNSObjectProtocolAliasing() throws {
		let errorList = try validateGraph(fileName: "TestNSObjectProtocolAliasing")
		XCTAssertTrue(errorList.isEmpty)
	}
	
	func testSeveralRegistrationError() throws {
		let errorList = try validateGraph(fileName: "TestSeveralRegistrationError")
		XCTAssertTrue(errorList.isEmpty, "We should allow two NOT default registration exists and validate in only during injection")
	}
	
	func testSeveralDefaultRegistrationError() throws {
		let errorList = try validateGraph(fileName: "TestSeveralDefaultRegistrationError")
		XCTAssertEqual(errorList.count, 2, "Should be exact two errors when two equals default registration exists")
	}
	
	func testGraphErrorPrinting() throws {
		let location = Location(file: "filename", line: 2, character: 2)
		let graphError = GraphError(infoString: "Error", location: location, kind: .validation)
		let resultMessage = "filename:2:2: error: Error"
		
		XCTAssertEqual(graphError.xcodeMessage, resultMessage)
	}
	
	func testEmptyFileGraphErrorPrinting() throws {
		let location = Location(file: nil, line: nil, character: nil)
		let graphError = GraphError(infoString: "Error", location: location, kind: .validation)
		let resultMessage = "<nopath>:1: error: Error"
		
		XCTAssertEqual(graphError.xcodeMessage, resultMessage)
	}
}
