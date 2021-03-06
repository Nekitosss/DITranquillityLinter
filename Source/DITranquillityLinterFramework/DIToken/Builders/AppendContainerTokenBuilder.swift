//
//  AppendContainerTokenBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 28/09/2018.
//

import Foundation
import SourceKittenFramework

/// Trying to create AppendContainerToken
final class AppendContainerTokenBuilder {
	
	static func build(functionName: String, parsingContext: ParsingContext, argumentStack: [ArgumentInfo], currentPartName: String?, location: Location) -> AppendContainerToken? {
		guard functionName == DIKeywords.append.rawValue,
			let appendInfo = argumentStack.first,
			argumentStack.count == 1 else { return nil }
		
		let value = appendInfo.value.droppedDotSelf()
		let isDIPart: (ArgumentInfo) -> Bool = {
			return ($0.name == "part" && (parsingContext.collectedInfo[value]?.inheritedTypes ?? []).contains(DIKeywords.diPart.rawValue))
				|| ($0.name == "framework" && (parsingContext.collectedInfo[value]?.inheritedTypes ?? []).contains(DIKeywords.diFramework.rawValue))
		}
		let typeName = value
		guard isDIPart(appendInfo),
			typeName != currentPartName // Circular append block. TODO: Throw XCode error
			else { return nil }
		guard let swiftType = parsingContext.collectedInfo[typeName],
			let loadContainerStructure = swiftType.substructure.first(where: { $0.get(.name, of: String.self) == DIKeywords.loadContainer.rawValue })
			else { return nil }
		
		let anotherFile = parsingContext.fileContainer[swiftType.filePath]!
		let oldContainerName = parsingContext.currentContainerName
		parsingContext.currentContainerName = DIKeywords.container.rawValue
		let containerPart = ContainerPart(substructureList: loadContainerStructure.substructures, file: anotherFile, parsingContext: parsingContext, currentPartName: typeName)
		parsingContext.currentContainerName = oldContainerName
		
		return AppendContainerToken(location: location, typeName: typeName, containerPart: containerPart)
	}
	
}
