//
//  AliasToken.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 22/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework

class AliasToken: DIToken {
	
	var typeName: String = ""
	var tag: String = ""
	let location: Location
	
	init?(functionName: String, invocationBody: String, argumentStack: [ArgumentInfo], bodyOffset: Int64, file: File) {
		guard functionName == DIKeywords.as.rawValue else { return nil }
		
		var argumentStack = argumentStack
		if argumentStack.isEmpty {
			argumentStack = AliasToken.parseArgumentList(body: invocationBody)
		}
		
		for argument in argumentStack {
			switch argument.name {
			case "", DIKeywords.check.rawValue:
				self.typeName = argument.value
			case DIKeywords.tag.rawValue:
				self.tag = argument.value
			default:
				break
			}
		}
		location = Location(file: file, byteOffset: bodyOffset)
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
