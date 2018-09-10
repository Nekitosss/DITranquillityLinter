//
//  InjectionToken.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 23/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework

class InjectionToken: DIToken {
	
	var name: String = ""
	var typeName: String = ""
	var cycle: Bool = false
	var optionalInjection: Bool = false
	var methodInjection = false
	var modificators: [InjectionModificator] = []
	
	init(name: String, typeName: String, optionalInjection: Bool, methodInjection: Bool) {
		self.name = name
		self.typeName = typeName
		self.optionalInjection = optionalInjection
		self.methodInjection = methodInjection
	}
	
	init?(functionName: String, invocationBody: String, argumentStack: [ArgumentInfo]) {
		guard functionName == "injection" else { return nil }
		
		var argumentStack = argumentStack
		if argumentStack.isEmpty {
			argumentStack = AliasToken.parseArgumentList(body: invocationBody)
		}
		
		for argument in argumentStack {
			if argument.name == "cycle" {
				cycle = argument.value == "\(true)"
			} else if argument.name.isEmpty && argument.value.starts(with: "\\.") {
				name = String(argument.value.dropFirst(2))
			} else if let dotIndex = argument.value.index(of: "."), argument.name.isEmpty && argument.value.firstMatch("\\\\[^.]") != nil  {
				name = String(argument.value[argument.value.index(after: dotIndex)...])
			} else if let nameFromPattern = argument.value.firstMatch("\\$0\\.[a-z0-9\\.]+[^= ]") {
				name = String(nameFromPattern.dropFirst(3))
			}
			if let typeFromPattern = argument.value.firstMatch(InjectionToken.forcedTypeRegexp)?.trimmingCharacters(in: .whitespaces) {
				typeName = typeFromPattern
				modificators.append(InjectionModificator.typed(typeFromPattern))
			}
		}
	}
	
	static let forcedTypeRegexp = "\\s[a-zA-Z]+\\s*$"
	
}
