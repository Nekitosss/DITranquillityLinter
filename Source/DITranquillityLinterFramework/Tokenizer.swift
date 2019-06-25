//
//  Printer.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 19/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework
import PathKit
import ASTVisitor

public let linterVersion = "0.0.3"

public class Tokenizer {
	
	let container: FileContainer
	
	private let validator: GraphValidator
	private let moduleParser: ModuleParser
	private let astEmitter: ASTEmitter
	
	init(container: FileContainer, validator: GraphValidator, moduleParser: ModuleParser, astEmitter: ASTEmitter) {
		self.container = container
		self.validator = validator
		self.moduleParser = moduleParser
		self.astEmitter = astEmitter
	}
	
	
	public func process(files: [String]) throws -> Bool {
		let filteredFiles = files.filter(moduleParser.shouldBeParsed)
		let astFiles = try astEmitter.emitAST(from: files)
		let collectedInfo = try moduleParser.collectInfo(files: filteredFiles)
		let parsingContext = GlobalParsingContext(container: container, collectedInfo: collectedInfo, astFilePaths: astFiles)
		parsingContext.cachedContainers = try moduleParser.getCachedContainers()
		let containerBuilder = ContainerInitializatorFinder(parsingContext: parsingContext)
		
		let initContainerStructureList = containerBuilder.findContainerStructure(separatlyIncludePublicParts: false)
		if initContainerStructureList.isEmpty {
			Log.warning("Could not find DIContainer creation")
			return false
		}
		
		print(xcodePrintable: parsingContext.warnings)
		guard parsingContext.errors.isEmpty else {
			print(xcodePrintable: parsingContext.errors)
			return false
		}
		let errorList = initContainerStructureList
			.flatMap { self.validator.validate(containerPart: $0, collectedInfo: collectedInfo) }
		
		print(xcodePrintable: errorList)
		return errorList.isEmpty
	}
	
	// TODO: Needs only for test proxy. Remove later
	func collectInfo(files: [String]) throws -> [String: Type] {
		return try moduleParser.collectInfo(files: files)
	}
}

