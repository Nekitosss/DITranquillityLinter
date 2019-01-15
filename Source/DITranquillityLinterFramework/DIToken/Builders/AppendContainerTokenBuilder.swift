//
//  AppendContainerTokenBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 28/09/2018.
//

import Foundation
import SourceKittenFramework

/// Trying to create AppendContainerToken
final class AppendContainerTokenBuilder: TokenBuilder {
	
	func build(using info: TokenBuilderInfo) -> DIToken? {
		guard
			info.functionName == DIKeywords.append.rawValue,
			let appendInfo = info.argumentStack.first,
			info.argumentStack.count == 1
			else { return nil }
		
		let typeName = appendInfo.value.droppedDotSelf()
		guard
			let swiftType = info.parsingContext.collectedInfo[typeName],
			self.isDIPart(appendInfo, swiftType: swiftType),
			typeName != info.currentPartName, // Circular append block. TODO: Throw XCode error
			let loadContainerStructure = swiftType.substructure.first(where: { $0.nameIs(DIKeywords.loadContainer) }),
			let newContainerPartFile = info.parsingContext.fileContainer.getOrCreateFile(by: swiftType.filePath)
			else { return nil }
		
		let oldContainerName = info.parsingContext.currentContainerName
		info.parsingContext.currentContainerName = DIKeywords.container.rawValue
		let containerPart = ContainerPart(substructureList: loadContainerStructure.substructures,
										  file: newContainerPartFile,
										  parsingContext: info.parsingContext,
										  currentPartName: typeName)
		info.parsingContext.currentContainerName = oldContainerName
		
		return AppendContainerToken(location: info.location, typeName: typeName, containerPart: containerPart)
	}
	
	private func isDIPart(_ argumentInfo: ArgumentInfo, swiftType: Type) -> Bool {
		return (argumentInfo.name == "part" && swiftType.inheritedTypes.contains(DIKeywords.diPart.rawValue))
			|| (argumentInfo.name == "framework" && swiftType.inheritedTypes.contains(DIKeywords.diFramework.rawValue))
	}
	
}
