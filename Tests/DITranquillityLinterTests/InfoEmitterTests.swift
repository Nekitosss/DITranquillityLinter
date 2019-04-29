//
//  InfoEmitterTests.swift
//  DITranquillityLinterTests
//
//  Created by Nikita Patskov on 08/04/2019.
//

import XCTest
@testable import DITranquillityLinterFramework

class InfoEmitterTests: XCTestCase {
	
	func testPublicPartParsing() throws {
		let initContainerStructureList = try getContainerInfo(fileName: "TestPublicPartParsing")
		
		XCTAssertFalse(initContainerStructureList.isEmpty, "Public DIPart not handled for info emitter")
		XCTAssertTrue(initContainerStructureList.first?.tokenInfo.isEmpty == false, "Information not extracted from public DIPart")
	}
	
	
	func testPrivatePartNotParsing() throws {
		let initContainerStructureList = try getContainerInfo(fileName: "TestPrivatePartNotParsing")
		XCTAssertTrue(initContainerStructureList.isEmpty, "Non public parts handled for info emitter. It shouldnt.")
	}
	
	
	// One -> Two -> Three -> One
	func testCircularDIPartsErrorEmitting() throws {
		let fileURL = pathToSourceFile(with: "TestCircularDIPartsErrorEmitting")
		
		let moduleParser: ModuleParser = container.resolve()
		let fileContainer: FileContainer = container.resolve()
		let context = try GlobalParsingContext(container: fileContainer, collectedInfo: moduleParser.collectInfo(files: [fileURL]))
		let containerBuilder = ContainerInitializatorFinder(parsingContext: context)
		
		_ = containerBuilder.findContainerStructure(separatlyIncludePublicParts: true)
		
		let hasCircularDependencyError = context.errors.contains(where: { $0.kind == .circularPartAppending })
		XCTAssertTrue(hasCircularDependencyError, "Circular dependency not detected")
	}
	
	// One -> One
	func testSelfAppendDIPartsErrorEmitting() throws {
		let fileURL = pathToSourceFile(with: "TestSelfAppendDIPartsErrorEmitting")
		
		let moduleParser: ModuleParser = container.resolve()
		let fileContainer: FileContainer = container.resolve()
		let context = try GlobalParsingContext(container: fileContainer, collectedInfo: moduleParser.collectInfo(files: [fileURL]))
		let containerBuilder = ContainerInitializatorFinder(parsingContext: context)
		
		_ = containerBuilder.findContainerStructure(separatlyIncludePublicParts: true)
		
		let hasCircularDependencyError = context.errors.contains(where: { $0.kind == .circularPartAppending })
		XCTAssertTrue(hasCircularDependencyError, "Self-dependency not detected")
	}
	
	func testSavingCachedFile() throws {
		let initContainerStructureList = try getContainerInfo(fileName: "TestPublicPartParsing")
		let cacher: DependencyTokenCacher = container.resolve()
		
		let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
			.appendingPathComponent(".testSavingCachedFile")
			.appendingPathExtension("lintcache")
		
		try cacher.cache(partList: initContainerStructureList, outputFilePath: fileURL)
		
		let openedContainerPart = cacher.getCachedPartList(from: fileURL)
		XCTAssertFalse(openedContainerPart.isEmpty)
	}
	
	func testOpeningBigCachedFile() {
		let bundle = Bundle(path: FileManager.default.currentDirectoryPath + "/TestFiles.bundle")!
		let path = bundle.path(forResource: ".dilintemitted", ofType: "lintcache")!
		let cacher: DependencyTokenCacher = container.resolve()
		
		let containerPart = cacher.getCachedPartList(from: URL(fileURLWithPath: path))
		XCTAssertFalse(containerPart.isEmpty)
	}
	
	func testPublicUsingIntegrationTest() throws {
		
		// Create side module public dependency
		let initContainerStructureList = try getContainerInfo(fileName: "TestPublicPartParsing")
		
		// Create main container
		let tokenizer: Tokenizer = container.resolve()
		let usingFileURL = pathToSourceFile(with: "TestPublicUsing")
		let context = try GlobalParsingContext(container: tokenizer.container, collectedInfo: tokenizer.collectInfo(files: [usingFileURL]))
		
		// Set side module dependency
		context.cachedContainers = initContainerStructureList.reduce(into: [:]) {$0[$1.name ?? ""] = $1 }
		let containerBuilder = ContainerInitializatorFinder(parsingContext: context)
		guard let containerInfo = containerBuilder.findContainerStructure(separatlyIncludePublicParts: false).first else {
			XCTFail(TestError.containerInfoNotFound.localizedDescription)
			return
		}
		
		// Validate multimodule graph
		let validator: GraphValidator = container.resolve()
		// Collected info using only for tag checking. We may pass [:] here cause no tags testing
		let errors = validator.validate(containerPart: containerInfo, collectedInfo: [:])
		XCTAssertTrue(errors.isEmpty)
	}
	
	private func getContainerInfo(fileName: String) throws -> [ContainerPart] {
		let fileURL = pathToSourceFile(with: fileName)
		
		let moduleParser: ModuleParser = container.resolve()
		let fileContainer: FileContainer = container.resolve()
		let context = try GlobalParsingContext(container: fileContainer, collectedInfo: moduleParser.collectInfo(files: [fileURL]))
		let containerBuilder = ContainerInitializatorFinder(parsingContext: context)
		
		return containerBuilder.findContainerStructure(separatlyIncludePublicParts: true)
	}
}
