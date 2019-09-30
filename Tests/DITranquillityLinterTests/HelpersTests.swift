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
	
	override func tearDown() {
		clearTestArtifacts()
	}
	
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
				
			} catch TestError.containerInfoNotFound {
				continue
      } catch let error as GraphError where error.kind == .parsing {
          continue
			} catch {
				XCTFail(error.localizedDescription + "\nTest file: " + sourceFile)
			}
		}
	}
}
