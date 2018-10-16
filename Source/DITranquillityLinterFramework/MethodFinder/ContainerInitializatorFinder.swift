//
//  ContainerInitializatorFinder.swift
//  DITranquillityLinter
//
//  Created by Nikita on 16/09/2018.
//

import Foundation
import SourceKittenFramework
import xcodeproj

final class ContainerInitializatorFinder {
	
	static func findContainerStructure(parsingContext: ParsingContext) -> ContainerPart? {
		var possibleContainerValues = parsingContext.collectedInfo.values.filter({ $0.inheritedTypes.contains(DIKeywords.diPart.rawValue) || $0.inheritedTypes.contains(DIKeywords.diFramework.rawValue) })
		
		if let appDelegateClass = parsingContext.collectedInfo[DIKeywords.appDelegate.rawValue] {
			possibleContainerValues.insert(appDelegateClass, at: 0)
		}
		
		for structureInfo in possibleContainerValues {
			guard let file = parsingContext.fileContainer[structureInfo.filePath] else {
				continue
			}
			if let mainContainerPart = recursivelyFindContainerInitialization(list: structureInfo.substructure, file: file, parsingContext: parsingContext) {
				return mainContainerPart
			}
		}
		
		return nil
	}
	
	private static func recursivelyFindContainerInitialization(list: [SourceKitStructure], file: File, parsingContext: ParsingContext) -> ContainerPart? {
		let isContainerInitialization: (SourceKitStructure) -> Bool = {
			let name = $0.get(.name, of: String.self)
			return (name == DIKeywords.initDIContainer.rawValue || name == DIKeywords.diContainer.rawValue)
				&& $0.get(.kind, of: String.self) == SwiftExpressionKind.call.rawValue
		}

		// .init call should be after variable name declaration. So index should be greater than 0
		if let containerInitIndex = list.index(where: isContainerInitialization), containerInitIndex > 0 {
			parsingContext.currentContainerName = list[containerInitIndex - 1].get(.name) ?? DIKeywords.container.rawValue
			return ContainerPart(substructureList: list, file: file, parsingContext: parsingContext, currentPartName: nil)
		}

		for substructureInfo in list {
			if let mainContainerPart = recursivelyFindContainerInitialization(list: substructureInfo.substructures ?? [], file: file, parsingContext: parsingContext) {
				return mainContainerPart
			}
		}
		return nil
	}
}
