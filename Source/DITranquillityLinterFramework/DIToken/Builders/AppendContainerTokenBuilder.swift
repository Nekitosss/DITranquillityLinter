//
//  AppendContainerTokenBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 28/09/2018.
//

import Foundation
import SourceKittenFramework

final class AppendContainerTokenBuilder {
	
	static func build(functionName: String, collectedInfo: [String : Type], argumentStack: [ArgumentInfo], bodyOffset: Int64, file: File, currentPartName: String?) -> AppendContainerToken? {
		guard functionName == DIKeywords.append.rawValue,
			let appendInfo = argumentStack.first,
			argumentStack.count == 1 else { return nil }
		
		let location = Location(file: file, byteOffset: bodyOffset)
		
		let value = String(appendInfo.value.dropLast(5)) // .self
		let isDIPart: (ArgumentInfo) -> Bool = {
			return ($0.name == "part" && (collectedInfo[value]?.inheritedTypes ?? []).contains(DIKeywords.diPart.rawValue))
				|| ($0.name == "framework" && (collectedInfo[value]?.inheritedTypes ?? []).contains(DIKeywords.diFramework.rawValue))
		}
		let typeName = value
		guard isDIPart(appendInfo),
			typeName != currentPartName // Circular append block. TODO: Throw XCode error
			else { return nil }
		guard let swiftType = collectedInfo[typeName],
			let loadContainerStructure = swiftType.substructure.first(where: { $0.get(.name, of: String.self) == DIKeywords.loadContainer.rawValue })
			else { return nil }
		
		let anotherFile = File(path: swiftType.path!.string)!
		let containerPart = ContainerPart(substructureList: (loadContainerStructure.substructures ?? []), file: anotherFile, collectedInfo: collectedInfo, currentPartName: typeName)
		
		return AppendContainerToken(location: location, typeName: typeName, containerPart: containerPart)
	}
	
}
