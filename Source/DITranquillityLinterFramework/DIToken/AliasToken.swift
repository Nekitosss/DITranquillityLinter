//
//  AliasToken.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 22/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation

class AliasToken {
	
	var typeName: String = ""
	var tag: String = ""
	
	init(typeName: String, tag: String) {
		self.typeName = typeName
		self.tag = tag
	}
	
	init?(functionName: String, invocationBody: String) {
		guard functionName == "as" else { return nil }
		let variables = invocationBody.split(separator: ",")
		let argumentInfo = variables.map(String.init).map(AliasToken.parseArgument)
		
		for (index, argument) in argumentInfo.enumerated() {
			if index == 0 {
				self.typeName = argument.value
			} else if index == 1 {
				self.tag = argument.value
			}
		}
	}
	
	static func parseArgument(argument: String) -> (outerName: String, innerName: String, value: String) {
		let parts = argument.split(separator: ":")
		var result: (outerName: String, innerName: String, value: String) = ("", "", "")
		if parts.count == 0 {
			return result
		} else if parts.count == 1 {
			result.value = String(parts[0])
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
		return result
	}
}
