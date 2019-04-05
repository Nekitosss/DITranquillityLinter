//
//  HelpersTests.swift
//  DITranquillityLinterTests
//
//  Created by Nikita Patskov on 29/11/2018.
//

import XCTest
import DITranquillity
@testable import DITranquillityLinterFramework

class HelpersTests: XCTestCase {

	func testContainerValidation() {
		let container = DIContainer()
		DISetting.Log.level = .warning
		container.append(part: LinterDIPart.self)
		
		XCTAssertTrue(container.validate(checkGraphCycles: true))
	}
	
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
		let cacher: ResultCacher = container.resolve()
		try cacher.clearCaches(isCommonCache: true)
		
		let parser: BinaryFrameworkParser = container.resolve()
		let result = try parser.parseBinaryModules(names: ["NSAutoreleasePool"])
		
		XCTAssertNotNil(result)
		XCTAssertFalse((result?.isEmpty ?? true))
	}
	
	
	func testProperBinaryParsingErrorHandling() throws {
		let parser: BinaryFrameworkParser = container.resolve()
		let result = try parser.parseBinaryModules(names: ["NSIndexPath+UIKitAdditions"]) // That will not be parsed, but error will not be thrown
		
		XCTAssertNotNil(result)
		XCTAssertTrue((result?.isEmpty ?? true))
	}

	
	func testSkippingEmptyBinaryParsing() throws {
		let parser: BinaryFrameworkParser = container.resolve()
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
		
		let tokenizer: Tokenizer = container.resolve()
		let result = try tokenizer.process(files: [filePath])
		XCTAssertFalse(result)
	}
	
	// Takes all test source files and encode -> decode them. Change later to constant decoding checking?
	func testAllFilesEncodingDecoding() {
		let encoder = JSONEncoder()
		let decoder = JSONDecoder()
		for sourceFile in pathsToSourceFiles() {
			do {
				let containerInfo = try findContainerStructure(fullPathToFile: sourceFile)
				let data = try encoder.encode(containerInfo)
				_ = try decoder.decode(ContainerPart.self, from: data)
				
			} catch {
				XCTFail(error.localizedDescription + "\nTest file: " + sourceFile)
			}
		}
	}
}
