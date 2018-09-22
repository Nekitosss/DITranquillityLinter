//
//  InjectionToken.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 23/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework
import xcodeproj

class InjectionToken: DIToken {
	
	var name: String = ""
	var typeName: String = ""
	var cycle: Bool = false
	var optionalInjection: Bool = false
	var methodInjection = false
	var modificators: [InjectionModificator] = []
	var injectionSubstructureList: [[String : SourceKitRepresentable]] = []
	let location: Location
	
	init(name: String, typeName: String, optionalInjection: Bool, methodInjection: Bool, location: Location) {
		self.name = name
		self.typeName = typeName
		self.optionalInjection = optionalInjection
		self.methodInjection = methodInjection
		self.location = location
	}
	
	init?(functionName: String, invocationBody: String, argumentStack: [ArgumentInfo], bodyOffset: Int64, file: File, substructureList: [[String : SourceKitRepresentable]]) {
		guard functionName == DIKeywords.injection.rawValue else { return nil }
		
		var argumentStack = argumentStack
		if argumentStack.isEmpty {
			argumentStack = AliasToken.parseArgumentList(body: invocationBody)
		}
		
		for argument in argumentStack {
			if argument.name == DIKeywords.cycle.rawValue {
				cycle = argument.value == "\(true)"
			} else if argument.name.isEmpty && argument.value.starts(with: RegExp.implicitKeyPath.rawValue) {
				name = String(argument.value.dropFirst(2))
			} else if let dotIndex = argument.value.index(of: "."), argument.name.isEmpty && argument.value.firstMatch("\\\\[^.]") != nil  {
				// I forgot what it is :(
				name = String(argument.value[argument.value.index(after: dotIndex)...])
			} else if let nameFromPattern = argument.value.firstMatch(RegExp.nameFromParameterInjection) {
				name = String(nameFromPattern.dropFirst(3))
			}
			if let typeFromPattern = argument.value.firstMatch(.forcedType)?.trimmingCharacters(in: .whitespaces) {
				typeName = typeFromPattern
				modificators.append(InjectionModificator.typed(typeFromPattern))
			}
		}
		injectionSubstructureList = substructureList
		self.location = Location(file: file, byteOffset: bodyOffset)
	}
	
}
