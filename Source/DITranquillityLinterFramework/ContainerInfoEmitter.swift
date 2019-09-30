//
//  ContainerInfoEmitter.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 03/04/2019.
//

import Foundation

public final class ContainerInfoEmitter {
	
	private let isTestEnvironment: Bool
	private let tokenCacher: DependencyTokenCacher
  private let astEmitter: ASTEmitter
	
	init(isTestEnvironment: Bool, tokenCacher: DependencyTokenCacher, astEmitter: ASTEmitter) {
		self.isTestEnvironment = isTestEnvironment
		self.tokenCacher = tokenCacher
    self.astEmitter = astEmitter
	}
	
	public func process(files: [String], outputFilePath: URL) throws -> Bool {
    let astFiles = try astEmitter.emitAST(from: files)
		let parsingContext = GlobalParsingContext(astFilePaths: astFiles)
		let containerBuilder = ContainerInitializatorFinder(parsingContext: parsingContext)
		
		let initContainerStructureList = containerBuilder.findContainerStructure(separatlyIncludePublicParts: true)
		if initContainerStructureList.isEmpty {
			Log.warning("Could not find DIContainer creation")
			return false
		}
		
		print(xcodePrintable: parsingContext.warnings)
		guard parsingContext.errors.isEmpty else {
			print(xcodePrintable: parsingContext.errors)
			return false
		}
		
		try tokenCacher.cache(partList: initContainerStructureList, outputFilePath: outputFilePath)
		return true
	}
}
