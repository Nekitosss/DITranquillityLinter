//
//  MethodFinder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 10/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import SourceKittenFramework

class MethodFinder {
	
	static func findMethodInfo(methodSignature: MethodSignature, initialObjectName: String, collectedInfo: [String: Type], file: File) -> [InjectionToken]? {
		guard let swiftType = collectedInfo[initialObjectName] else { return [] }
		if let method = swiftType.methods.first(where: { $0.selectorName == methodSignature.name }) {
			return extractArgumentInfo(methodSignature: methodSignature, parameters: method.parameters, file: file)
		}
		for inheritedType in swiftType.inherits {
			return findMethodInfo(methodSignature: methodSignature, initialObjectName: inheritedType.key, collectedInfo: collectedInfo, file: file)
		}
		return nil
	}
	
	static func extractArgumentInfo(methodSignature: MethodSignature, parameters: [MethodParameter], file: File) -> [InjectionToken] {
		var argumentInfo: [InjectionToken] = []
		var argumentIndex = -1
		for parameter in parameters {
			argumentIndex += 1
			guard let injectableArgInfo = methodSignature.injectableArgumentInfo.first(where: { $0.argumentCount == argumentIndex }),
				injectableArgInfo.argumentCount == argumentIndex
				else { continue }
			
			let location = Location(file: file, byteOffset: injectableArgInfo.argumentBodyOffset)
			let injection = InjectionToken(name: parameter.name, typeName: parameter.unwrappedTypeName, optionalInjection: parameter.isOptional, methodInjection: true, location: location)
			if let modificators = methodSignature.injectionModificators[argumentIndex] {
				injection.modificators.append(contentsOf: modificators)
				for modificator in modificators {
					switch modificator {
					case .typed(let forcedType):
						injection.typeName = forcedType
					case .tagged:
						fatalError("Not implemented")
					case .many:
						fatalError("Not implemented")
					}
				}
			}
			argumentInfo.append(injection)
		}
		return argumentInfo
	}
	
}
