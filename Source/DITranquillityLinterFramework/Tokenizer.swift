//
//  Printer.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 19/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import PathKit
import ASTVisitor

public let linterVersion = "0.0.3"

public class Tokenizer {
	
	private let validator: GraphValidator
	private let astEmitter: ASTEmitter
	
	init(validator: GraphValidator, astEmitter: ASTEmitter) {
		self.validator = validator
		self.astEmitter = astEmitter
	}
	
	
	public func process(files: [String]) throws -> Bool {
		let astFiles = try astEmitter.emitAST(from: files)
		let parsingContext = GlobalParsingContext(astFilePaths: astFiles)
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
			.flatMap { self.validator.validate(containerPart: $0) }
		
		print(xcodePrintable: errorList)
		return errorList.isEmpty
	}
}
