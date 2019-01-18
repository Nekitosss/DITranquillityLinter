//
//  ContainerInitializatorFinder.swift
//  DITranquillityLinter
//
//  Created by Nikita on 16/09/2018.
//

import Foundation
import SourceKittenFramework

final class ContainerInitializatorFinder {
	
	private let parsingContext: ParsingContext
	
	init(parsingContext: ParsingContext) {
		self.parsingContext = parsingContext
	}
	
	/// Trying to find container initialization and parse dependency praph.
	func findContainerStructure() -> ContainerPart? {
		TimeRecorder.start(event: .createTokens)
		defer { TimeRecorder.end(event: .createTokens) }
		
		let possibleContainerValues = getProssibleContainerTypeHolders()
		for structureInfo in possibleContainerValues {
			guard let file = parsingContext.fileContainer.getOrCreateFile(by: structureInfo.filePath) else {
				continue
			}
			if let mainContainerPart = self.recursivelyFindContainerAndBuildGraph(list: structureInfo.substructure, file: file) {
				return mainContainerPart
			}
		}
		
		return nil
	}
	
	
	private func getProssibleContainerTypeHolders() -> [Type] {
		var possibleContainerValues = parsingContext.collectedInfo.values.filter {
			$0.inheritedTypes.contains(DIKeywords.diPart.rawValue) || $0.inheritedTypes.contains(DIKeywords.diFramework.rawValue)
		}
		if let appDelegateClass = parsingContext.collectedInfo[DIKeywords.appDelegate.rawValue] {
			possibleContainerValues.insert(appDelegateClass, at: 0)
		}
		return possibleContainerValues
	}
	
	
	private func recursivelyFindContainerAndBuildGraph(list: [SourceKitStructure], file: File) -> ContainerPart? {
		// .init call should be after variable name declaration. So index should be greater than 0
		if let containerInitIndex = list.index(where: self.isContainerInitialization), containerInitIndex > 0 {
			parsingContext.currentContainerName = list[containerInitIndex - 1].get(.name) ?? DIKeywords.container.rawValue
			return ContainerPart(substructureList: list, file: file, parsingContext: parsingContext, currentPartName: nil)
		}

		for substructureInfo in list {
			if let mainContainerPart = self.recursivelyFindContainerAndBuildGraph(list: substructureInfo.substructures, file: file) {
				return mainContainerPart
			}
		}
		return nil
	}
	
	
	private func isContainerInitialization(structure: SourceKitStructure) -> Bool {
		let isDiContainerInitializerMethodName = structure.nameIs(DIKeywords.initDIContainer) || structure.nameIs(DIKeywords.diContainer)
		return isDiContainerInitializerMethodName && structure.isKind(of: SwiftExpressionKind.call)
	}
}
