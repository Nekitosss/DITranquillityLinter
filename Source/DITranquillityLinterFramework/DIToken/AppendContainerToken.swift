//
//  AppendContainerToken.swift
//  DITranquillityLinter
//
//  Created by Nikita on 12/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework
import xcodeproj

class AppendContainerToken: DIToken {
	
	let location: Location
	let typeName: String
	let containerPart: ContainerPart
	
	init?(functionName: String, invocationBody: String, collectedInfo: [String : Type], argumentStack: [ArgumentInfo], bodyOffset: Int64, file: File, currentPartName: String?) {
		guard functionName == DIKeywords.append.rawValue else { return nil }
		guard let appendInfo = argumentStack.first, argumentStack.count == 1 else { return nil }
		let value = String(appendInfo.value.dropLast(5)) // .self
		let isDIPart: (ArgumentInfo) -> Bool = {
			return ($0.name == "part" && (collectedInfo[value]?.inheritedTypes ?? []).contains(DIKeywords.diPart.rawValue))
				|| ($0.name == "framework" && (collectedInfo[value]?.inheritedTypes ?? []).contains(DIKeywords.diFramework.rawValue))
		}
		self.typeName = value
		guard isDIPart(appendInfo),
			typeName != currentPartName // Circular append block. TODO: Throw XCode error
			else { return nil }
		guard let swiftType = collectedInfo[typeName],
			let loadContainerStructure = swiftType.substructure.first(where: { $0.get(.name, of: String.self) == DIKeywords.loadContainer.rawValue })
			else { return nil }
		
		location = Location(file: file, byteOffset: bodyOffset)
		let file = File(path: swiftType.path!.string)!
		containerPart = ContainerPart(substructureList: (loadContainerStructure.substructures ?? []), file: file, collectedInfo: collectedInfo, currentPartName: typeName)
	}
	
	
}
