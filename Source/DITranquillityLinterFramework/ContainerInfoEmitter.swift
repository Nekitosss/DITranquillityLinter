//
//  ContainerInfoEmitter.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 03/04/2019.
//

import Foundation

public final class ContainerInfoEmitter {
	
	let container: FileContainer
	
	private let isTestEnvironment: Bool
	private let moduleParser: ModuleParser
	private let tokenCacher: DependencyTokenCacher
	
	init(isTestEnvironment: Bool, fileContainer: FileContainer, moduleParser: ModuleParser, tokenCacher: DependencyTokenCacher) {
		self.isTestEnvironment = isTestEnvironment
		self.moduleParser = moduleParser
		self.container = fileContainer
		self.tokenCacher = tokenCacher
	}
	
	public func process(files: [String], outputFilePath: URL) throws -> Bool {
		let filteredFiles = files.filter(moduleParser.shouldBeParsed)
		let collectedInfo = try moduleParser.collectInfo(files: filteredFiles)
		let parsingContext = GlobalParsingContext(container: container, collectedInfo: collectedInfo)
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
