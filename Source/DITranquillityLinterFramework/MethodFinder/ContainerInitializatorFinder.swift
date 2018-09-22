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
	
	static func findContainerStructure(dictionary: [String : Type], project: XcodeProj) -> ContainerPart? {
		var possibleContainerValues = dictionary.values.filter({ $0.inheritedTypes.contains(DIKeywords.diPart.rawValue) || $0.inheritedTypes.contains(DIKeywords.diFramework.rawValue) })
		
		if let appDelegateClass = dictionary["AppDelegate"] {
			possibleContainerValues.insert(appDelegateClass, at: 0)
		}
		
		for structureInfo in possibleContainerValues {
			if let mainContainerPart = recursivelyFindContainerInitialization(list: structureInfo.substructure, file: File.init(path: structureInfo.path!.string)!, contents: structureInfo.file.contents.bridge(), dictionary: dictionary) {
				return mainContainerPart
			}
		}
		
		return nil
	}
	
	private static func recursivelyFindContainerInitialization(list: [SourceKitStructure], file: File, contents: NSString, dictionary: [String : Type]) -> ContainerPart? {
		let isContainerInitialization: (SourceKitStructure) -> Bool = {
			let name = $0.get(.name, of: String.self)
			return (name == "DIContainer.init" || name == "DIContainer") && $0.get(.kind, of: String.self) == SwiftExpressionKind.call.rawValue
		}

		var containerName: String?
		// .init call should be after variable name declaration. So index should be greater than 0
		if let containerInitIndex = list.index(where: isContainerInitialization), containerInitIndex > 0 {
			let containerNameSubstructure = list[containerInitIndex - 1]
			containerName = containerNameSubstructure.get(.name, of: String.self)
			return ContainerPart(substructureList: list, file: file, collectedInfo: dictionary, currentPartName: nil)
		}

		for substructureInfo in list {
			if let mainContainerPart = recursivelyFindContainerInitialization(list: substructureInfo.substructures ?? [], file: file, contents: contents, dictionary: dictionary) {
				return mainContainerPart
			}
		}
		return nil
	}
}
