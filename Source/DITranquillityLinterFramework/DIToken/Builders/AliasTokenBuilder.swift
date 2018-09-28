//
//  AliasTokenBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 28/09/2018.
//

import Foundation
import SourceKittenFramework

final class AliasTokenBuilder {
	
	static func build(functionName: String, invocationBody: String, argumentStack: [ArgumentInfo], bodyOffset: Int64, file: File) -> AliasToken? {
		guard functionName == DIKeywords.as.rawValue else { return nil }
		var typeName = ""
		var tag = ""
		let location = Location(file: file, byteOffset: bodyOffset)
		
		var argumentStack = argumentStack
		if argumentStack.isEmpty {
			argumentStack = AliasTokenBuilder.parseArgumentList(body: invocationBody)
		}
		
		for argument in argumentStack {
			switch argument.name {
			case "" where argumentStack.count == 1,
				 "_" where argumentStack.count == 1,
				 DIKeywords.check.rawValue:
				typeName = argument.value.droppedDotSelf()
			case DIKeywords.tag.rawValue:
				tag = argument.value
			default:
				break
			}
		}
		return AliasToken(typeName: typeName, tag: tag, location: location)
	}
	
	static func parseArgumentList(body: String) -> [ArgumentInfo] {
		return body.split(separator: ",").compactMap({ parseArgument(argument: String($0)) })
	}
	
	static func parseArgument(argument: String) -> ArgumentInfo? {
		let parts = argument.split(separator: ":")
		var result: (outerName: String, innerName: String, value: String) = ("", "", "")
		if parts.count == 0 {
			return nil
		} else if parts.count == 1 {
			result.value = String(parts[0])
			result.outerName = "_"
		} else {
			result.value = String(parts[1])
			
			let nameParts = parts[0].split(separator: " ", omittingEmptySubsequences: true)
			if nameParts.count == 1 {
				result.innerName = String(nameParts[0])
				result.outerName = String(nameParts[0])
			} else if nameParts.count == 2 {
				result.innerName = String(nameParts[1])
				result.outerName = String(nameParts[0])
			}
		}
		return ArgumentInfo(name: result.outerName, value: result.value, structure: [:])
	}
	
}