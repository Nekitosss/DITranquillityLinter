//
//  MethodFinder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 10/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import SourceKittenFramework

class MethodFinder {
	
	static func findMethodInfo(methodSignature: MethodSignature, initialObjectName: String, collectedInfo: [String: SwiftType]) -> [InjectionToken]? {
		guard let swiftType = collectedInfo[initialObjectName] else { return [] }
		for substructure in swiftType.substructure {
			if let kind = substructure[SwiftDocKey.kind.rawValue] as? String,
				let name = substructure[SwiftDocKey.name.rawValue] as? String,
				let methodSubstructureList = substructure[SwiftDocKey.substructure.rawValue] as? [[String: SourceKitRepresentable]],
				kind == SwiftExpressionKind.call.rawValue || kind == SwiftExpressionKind.instance.rawValue,
				name == methodSignature.name {
				return extractArgumentInfo(methodSignature: methodSignature, methodSubstructureList: methodSubstructureList)
			}
		}
		for inheritedType in swiftType.inheritedTypes {
			return findMethodInfo(methodSignature: methodSignature, initialObjectName: inheritedType, collectedInfo: collectedInfo)
		}
		return nil
	}
	
	static func extractArgumentInfo(methodSignature: MethodSignature, methodSubstructureList: [[String: SourceKitRepresentable]]) -> [InjectionToken] {
		var argumentInfo: [InjectionToken] = []
		var argumentIndex = -1
		for substucture in methodSubstructureList {
			guard let kind: String = substucture.get(.kind),
				kind == SwiftExpressionKind.parameter.rawValue else { continue }
			argumentIndex += 1
			guard let name: String = substucture.get(.name),
				let typeName: String = substucture.get(.typeName),
				methodSignature.injectableArgumentNumbers.contains(argumentIndex)
				else { continue }
			
			let injection = InjectionToken(name: name, typeName: typeName, optionalInjection: typeName.contains("?"), methodInjection: true)
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
