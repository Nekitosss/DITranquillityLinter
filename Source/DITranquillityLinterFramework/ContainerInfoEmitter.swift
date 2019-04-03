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
	private let tokenCacher = DependencyTokenCacher()
	
	public init(isTestEnvironment: Bool) {
		self.isTestEnvironment = isTestEnvironment
		self.container = FileContainer()
		self.moduleParser = ModuleParser(container: container, isTestEnvironment: isTestEnvironment)
	}
	
	public func process(files: [String], outputFilePath: URL) throws -> Bool {
		let filteredFiles = files.filter(moduleParser.shouldBeParsed)
		let collectedInfo = try moduleParser.collectInfo(files: filteredFiles)
		let parsingContext = ParsingContext(container: container, collectedInfo: collectedInfo)
		let containerBuilder = ContainerInitializatorFinder(parsingContext: parsingContext)
		
		let initContainerStructureList = containerBuilder.findContainerStructure()
		if initContainerStructureList.isEmpty {
			Log.warning("Could not find DIContainer creation")
			return false
		}
		
		guard parsingContext.errors.isEmpty else {
			GraphError.display(errorList: parsingContext.errors)
			return false
		}
		
		try tokenCacher.cache(partList: initContainerStructureList, outputFilePath: outputFilePath)
		return true
	}
}
