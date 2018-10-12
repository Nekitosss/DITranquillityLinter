//
//  MethodFinder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 10/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import SourceKittenFramework

class MethodFinder {
	
	static func findMethodInfo(methodSignature: MethodSignature, initialObjectName: String, collectedInfo: [String: Type], file: File, genericType: GenericType?, methodCallBodyOffset: Int64, forcedAllInjection: Bool) -> [InjectionToken]? {
		guard let swiftType = collectedInfo[initialObjectName] else { return [] }
		let isPlainSignature = !methodSignature.name.contains("(")
		
		let extractInfoBlock: (Method) -> [InjectionToken]? = {
			return extractArgumentInfo(swiftType: swiftType, methodSignature: methodSignature, parameters: $0.parameters, file: file, methodCallBodyOffset: methodCallBodyOffset, genericType: genericType, collectedInfo: collectedInfo, forcedAllInjection: forcedAllInjection)
		}
		if let method = swiftType.allMethods.first(where: { $0.selectorName == methodSignature.name }) {
			return extractInfoBlock(method)
		} else if isPlainSignature {
			// Extracting from reg(MyClass.init) and reg(MyClass.init(foo:bar:))
			// TODO: Implement for NOT initializers (other static functions)
			let signatureMatchers = swiftType.methods.filter({ $0.selectorName.hasPrefix(methodSignature.name) })
			if let singleInitializer = signatureMatchers.first, signatureMatchers.count == 1 {
				return extractInfoBlock(singleInitializer)
			} else if let simpliestInitializer = signatureMatchers.first(where: { $0.selectorName == methodSignature.name }) { // This scenatio not compiled? Check later
				return extractInfoBlock(simpliestInitializer)
			}
		}
		return nil
	}
	
	static func extractArgumentInfo(swiftType: Type, methodSignature: MethodSignature, parameters: [MethodParameter], file: File, methodCallBodyOffset: Int64, genericType: GenericType?, collectedInfo: [String: Type], forcedAllInjection: Bool) -> [InjectionToken] {
		var argumentInfo: [InjectionToken] = []
		var argumentIndex = -1
		for parameter in parameters {
			argumentIndex += 1
			
			let injectableArgInfo = methodSignature.injectableArgumentInfo.first(where: { $0.argumentCount == argumentIndex }) ?? (-1, methodCallBodyOffset)
			guard forcedAllInjection || injectableArgInfo.argumentCount == argumentIndex else { continue }
			
			var plainTypeName = parameter.unwrappedTypeName
			var typeName = TypeName.onlyDroppedOptional(name: parameter.typeName.name)
			if let genericTypeIndex = swiftType.genericTypeParameters.index(where: { $0.typeName.unwrappedTypeName == parameter.unwrappedTypeName }),
				let resolvedGenericType = genericType {
				if swiftType.genericTypeParameters.count == resolvedGenericType.typeParameters.count {
					let actualType = resolvedGenericType.typeParameters[genericTypeIndex]
					plainTypeName = actualType.typeName.unwrappedTypeName
					typeName = TypeName.onlyDroppedOptional(name: actualType.typeName.name)
				} else {
					// TODO: Throw error. Different generic argument counts not supported (Generic inheritance)
				}
			}
			
			if let typealiased = collectedInfo[plainTypeName]?.name {
				if !typeName.contains("<") {
					// Type name should not be only if its typealias, not generic
					typeName = TypeName.onlyDroppedOptional(name: typealiased)
				}
				plainTypeName = typealiased
			}
			let location = Location(file: file, byteOffset: injectableArgInfo.argumentBodyOffset)
			let modificators = methodSignature.injectionModificators[argumentIndex] ?? []
			var injection = InjectionToken(name: parameter.name,
										   typeName: typeName,
										   plainTypeName: plainTypeName,
										   cycle: false,
										   optionalInjection: parameter.isOptional,
										   methodInjection: true,
										   modificators: modificators,
										   injectionSubstructureList: [],
										   location: location)
			for modificator in injection.modificators {
				switch modificator {
				case .typed(let forcedType):
					injection.typeName = forcedType
					injection.plainTypeName = TypeName.unwrapTypeName(name: forcedType).unwrappedTypeName
				case .tagged:
					break
				case .many:
					fatalError("Not implemented")
				}
			}
			argumentInfo.append(injection)
		}
		return argumentInfo
	}
	
}
