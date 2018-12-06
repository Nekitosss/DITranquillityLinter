//
//  HelpersTests.swift
//  DITranquillityLinterTests
//
//  Created by Nikita Patskov on 29/11/2018.
//

import XCTest
@testable import DITranquillityLinterFramework

class HelpersTests: XCTestCase {

	func testParallelArrayErrorThrowing() throws {
		let throwable = NSError(domain: "", code: 0, userInfo: nil)
		do {
			_ = try [1, 2, 3].parallelMap { _ in
				throw throwable
			}
			XCTFail("Parallel map error did not trwowed")
		} catch {
			XCTAssertEqual(error as NSError, throwable)
		}
	}
	
	
	func testBinaryFrameworkParsingNoCache() throws {
		let container = FileContainer()
		let cacher = ResultCacher()
		try cacher.clearCaches(isCommonCache: true)
		
		let parser = BinaryFrameworkParser(fileContainer: container, isTestEnvironment: true)
		let result = try parser.parseBinaryModules(names: ["UIInteraction"])
		
		XCTAssertNotNil(result)
		XCTAssertFalse((result?.isEmpty ?? true))
	}
	
	
	func testProperBinaryParsingErrorHandling() throws {
		let container = FileContainer()
		let parser = BinaryFrameworkParser(fileContainer: container, isTestEnvironment: true)
		let result = try parser.parseBinaryModules(names: ["NSIndexPath+UIKitAdditions"]) // That will not be parsed, but error will not be thrown
		
		XCTAssertNotNil(result)
		XCTAssertTrue((result?.isEmpty ?? true))
	}

	
	func testSkippingEmptyBinaryParsing() throws {
		let container = FileContainer()
		let parser = BinaryFrameworkParser(fileContainer: container, isTestEnvironment: true)
		let result = try parser.parseBinaryModules(names: [])
		
		XCTAssertNil(result)
	}
	
	
	func testFileContainerSuccessRecreation() throws {
		let container = FileContainer()
		let filePath = pathToSourceFile(with: "TestComposedTypealiasError")
		let file = container.getOrCreateFile(by: filePath)
		
		XCTAssertNotNil(file)
	}
	
	func testFileContaienrFailureRecreation() throws {
		let container = FileContainer()
		let file = container.getOrCreateFile(by: "NotExistingFile")
		
		XCTAssertNil(file)
	}
	
	func testProperFileProcessingSequence() throws {
		let filePath = pathToSourceFile(with: "TestComposedTypealiasFailure")
		
		let tokenizer = Tokenizer(isTestEnvironment: true)
		let result = try tokenizer.process(files: [filePath])
		XCTAssertFalse(result)
	}
}
