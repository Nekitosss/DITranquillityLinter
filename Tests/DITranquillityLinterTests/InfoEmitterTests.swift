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
	
	func testCircularDIPartsErrorEmitting() throws {
		let fileURL = pathToSourceFile(with: "TestCircularDIPartsErrorEmitting")
		
		let moduleParser: ModuleParser = container.resolve()
		let fileContainer: FileContainer = container.resolve()
		let context = try ParsingContext(container: fileContainer, collectedInfo: moduleParser.collectInfo(files: [fileURL]))
		let containerBuilder = ContainerInitializatorFinder(parsingContext: context)
		
//		_ = containerBuilder.findContainerStructure(separatlyIncludePublicParts: true)
		
		let hasCircularDependencyError = context.errors.contains(where: { $0.kind == .circularPartAppending })
		XCTAssertTrue(hasCircularDependencyError, "Circular dependency not detected")
	}
	
	private func getContainerInfo(fileName: String) throws -> [ContainerPart] {
		let fileURL = pathToSourceFile(with: fileName)
		
		let moduleParser: ModuleParser = container.resolve()
		let fileContainer: FileContainer = container.resolve()
		let context = try ParsingContext(container: fileContainer, collectedInfo: moduleParser.collectInfo(files: [fileURL]))
		let containerBuilder = ContainerInitializatorFinder(parsingContext: context)
		
		return containerBuilder.findContainerStructure(separatlyIncludePublicParts: true)
	}
}
