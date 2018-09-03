//
//  InjectionToken.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 23/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework

class InjectionToken {
	
	var name: String = ""
	var typeName: String = ""
	var cycle: Bool = false
	
	init(name: String, typeName: String) {
		self.name = typeName
		self.typeName = typeName
	}
	
	init?(functionName: String, invocationBody: String, argumentStack: [ArgumentInfo]) {
		guard functionName == "injection" else { return nil }
		
		var argumentStack = argumentStack
		if argumentStack.isEmpty {
			argumentStack = AliasToken.parseArgumentList(body: invocationBody)
		}
		
		for argument in argumentStack {
			switch argument.name {
			case "cycle":
				cycle = argument.value == "\(true)"
			case "" where argument.value.starts(with: "\\"):
				name = argument.value
			default:
				break
			}
		}
	}
}
