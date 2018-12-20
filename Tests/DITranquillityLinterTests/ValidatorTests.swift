

import XCTest
@testable import DITranquillityLinterFramework

class ValidatorTests: XCTestCase {

	static var allTests = [
		("testValidateAliasingSuccess", testValidateAliasingSuccess),
		]

	func testValidateAliasingSuccess() throws {
		let errorList = try validateGraph(fileName: "TestValidateAliasingSuccess")
		XCTAssertTrue(errorList.isEmpty)
	}
	
	func testValidatePlainAliasingError() throws {
		let errorList = try validateGraph(fileName: "TestValidatePlainAliasingError")
		XCTAssertFalse(errorList.isEmpty)
	}
	
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
	
	func testComposedTypealiasError() throws {
		let errorList = try validateGraph(fileName: "TestComposedTypealiasError")
		XCTAssertFalse(errorList.isEmpty)
	}
	
	func testTypealiasedComposedTypealiasSuccess() throws {
		let errorList = try validateGraph(fileName: "TestTypealiasedComposedTypealiasSuccess")
		XCTAssertTrue(errorList.isEmpty)
	}
	
	func testFullTypealiasedComposedAliasingSuccess() throws {
		let errorList = try validateGraph(fileName: "TestFullTypealiasedComposedAliasingSuccess")
		XCTAssertTrue(errorList.isEmpty)
	}
	
	func testComposedTypealiasFailure() throws {
		let errorList = try validateGraph(fileName: "TestComposedTypealiasFailure")
		XCTAssertFalse(errorList.isEmpty)
	}
	
	func testTypealiasedComposedAliasingFailure() throws {
		let errorList = try validateGraph(fileName: "TestTypealiasedComposedAliasingFailure")
		XCTAssertFalse(errorList.isEmpty)
	}
	
	func testPlainInjectionValidation() throws {
		let errorList = try validateGraph(fileName: "TestPlainInjectionValidation")
		XCTAssertTrue(errorList.isEmpty)
	}
	
	func testNSObjectProtocolAliasing() throws {
		let errorList = try validateGraph(fileName: "TestNSObjectProtocolAliasing")
		XCTAssertTrue(errorList.isEmpty)
	}
	
}
