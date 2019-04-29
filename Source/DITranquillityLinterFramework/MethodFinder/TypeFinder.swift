//
//  TypeFinder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 10/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import SourceKittenFramework
import Foundation

final class TypeFinder {
	
	static func parseTypeName(name: String) -> (plainTypeName: String, typeName: String, genericType: GenericType?) {
		var name = name
		if let bracketIndex = name.firstIndex(of: "(") {
			name = String(name[..<bracketIndex])
		}
		name = name.droppedDotInit()
		if let genericType = Composer.parseGenericType(name) {
			return (genericType.name, name, genericType)
		} else {
			return (name, name, nil)
		}
	}
	
	
	static func restoreMethodName(initial name: String, defaultMethodName: String = "init") -> String {
		guard let dotIndex = name.lastIndex(of: ".") else {
			return defaultMethodName
		}
		return String(name[name.index(after: dotIndex)...])
	}
	
	
	func restoreSignature(name: String, substructureList: [[String: SourceKitRepresentable]], content: NSString) -> MethodSignature {
		var signatureName = name
		var injectableArguments: [(Int, Int64)] = []
		var injectionModificators: [Int: [InjectionModificator]] = [:]
		if !substructureList.isEmpty {
			signatureName.append("(")
		}
		var argumentNumber = 0
		for substucture in substructureList {
			
			let name = substucture.get(.name, of: String.self) ?? "_"
			guard
				let bodyOffset = substucture.getBodyInfo()?.offset,
				substucture.isKind(of: SwiftExpressionKind.argument),
				let body = substucture.body(using: content)?.bracketsBalancing()
				else { continue }
			
			if body.firstMatch(RegExp.implicitClosureArgument) != nil {
				injectableArguments.append((argumentNumber, bodyOffset))
			}
			if let forcedType = body.firstMatch(RegExp.forcedType)?.trimmingCharacters(in: .whitespacesAndNewlines) {
				injectionModificators[argumentNumber, default: []].append(.typed(forcedType))
			}
			if let taggedInjection = InjectionTokenBuilder.parseTaggedAndManyInjection(structure: substucture, content: content) {
				injectionModificators[argumentNumber, default: []].append(contentsOf: taggedInjection)
			}
			
			signatureName += name + ":"
			argumentNumber += 1
		}
		if !substructureList.isEmpty {
			signatureName.append(")")
		}
		return MethodSignature(name: signatureName, injectableArgumentInfo: injectableArguments, injectionModificators: injectionModificators)
	}
	
	
	func findArgumentTypeInfo(typeName: String, tokenName: String, parsingContext: GlobalParsingContext, modificators: [InjectionModificator]) -> (typeName: String, plainTypeName: String, optionalInjection: Bool)? {
		let (plainTypeName, _, genericType) = TypeFinder.parseTypeName(name: typeName)
		if let ownerType = parsingContext.collectedInfo[plainTypeName],
			let variable = ownerType.allVariables.first(where: { $0.name == tokenName }) {
			let (typeName, plainTypeName) = extractTypeName(parameter: variable, swiftType: ownerType, genericType: genericType, parsingContext: parsingContext, modificators: modificators)
			return (typeName, plainTypeName, variable.isOptional)
		}
		return nil
	}
	
	
	func findMethodTypeInfo(typeName: String, parsingContext: GlobalParsingContext, content: NSString, file: File, token: InjectionToken) -> [DITokenConvertible] {
		guard let substructure = token.injectionSubstructureList.last,
			var methodName: String = substructure.get(.name),
			let offset: Int64 = substructure.get(.offset)
			else { return [] }
		methodName = TypeFinder.restoreMethodName(initial: methodName, defaultMethodName: methodName)
		let signature = restoreSignature(name: methodName, substructureList: substructure.substructures, content: content)
		
		let (plainTypeName, _, genericType) = TypeFinder.parseTypeName(name: typeName)
		return findMethodInfo(methodSignature: signature, initialObjectName: plainTypeName, parsingContext: parsingContext, file: file, genericType: genericType, methodCallBodyOffset: offset, forcedAllInjection: false) ?? []
	}
	
	
	func findMethodInfo(methodSignature: MethodSignature, initialObjectName: String, parsingContext: GlobalParsingContext, file: File, genericType: GenericType?, methodCallBodyOffset: Int64, forcedAllInjection: Bool) -> [InjectionToken]? {
		guard let swiftType = parsingContext.collectedInfo[initialObjectName] else {
			return []
		}
		
		func extractInfo(_ method: Method) -> [InjectionToken]? {
			return extractArgumentInfo(swiftType: swiftType, methodSignature: methodSignature, parameters: method.parameters, file: file, methodCallBodyOffset: methodCallBodyOffset, genericType: genericType, parsingContext: parsingContext, forcedAllInjection: forcedAllInjection)
		}
		
		let isPlainSignature = !methodSignature.name.contains("(")
		if let method = swiftType.allMethods.first(where: { $0.selectorName == methodSignature.name }) {
			return extractInfo(method)
		} else if isPlainSignature {
			// Extracting from reg(MyClass.init) and reg(MyClass.init(foo:bar:))
			// TODO: Implement for NOT initializers (other static functions)
			let signatureMatchers = swiftType.methods.filter({ $0.selectorName.hasPrefix(methodSignature.name) })
			if let singleInitializer = signatureMatchers.first, signatureMatchers.count == 1 {
				return extractInfo(singleInitializer)
			} else if let simpliestInitializer = signatureMatchers.first(where: { $0.selectorName == methodSignature.name }) {
				// This scenatio not compiled? Check later. Scenario: We have two initializers and write register(MyClass.init). So we have ambiguos in init?
				return extractInfo(simpliestInitializer)
			}
		}
		return nil
	}
	
	
	private func extractArgumentInfo(swiftType: Type, methodSignature: MethodSignature, parameters: [MethodParameter], file: File, methodCallBodyOffset: Int64, genericType: GenericType?, parsingContext: GlobalParsingContext, forcedAllInjection: Bool) -> [InjectionToken] {
		
		return parameters.enumerated().compactMap { argumentIndex, parameter in
			let injectableArgInfo = methodSignature.injectableArgumentInfo.first(where: { $0.argumentCount == argumentIndex }) ?? (-1, methodCallBodyOffset)
			guard forcedAllInjection || injectableArgInfo.argumentCount == argumentIndex else {
				return nil
			}
			let modificators = methodSignature.injectionModificators[argumentIndex] ?? []
			let (typeName, plainTypeName) = extractTypeName(parameter: parameter, swiftType: swiftType, genericType: genericType, parsingContext: parsingContext, modificators: modificators)
			let location = Location(file: file, byteOffset: injectableArgInfo.argumentBodyOffset)
			
			return InjectionToken(name: parameter.name,
								  typeName: typeName,
								  plainTypeName: plainTypeName,
								  cycle: false,
								  optionalInjection: parameter.isOptional,
								  methodInjection: true,
								  modificators: modificators,
								  injectionSubstructureList: [],
								  location: location)
		}
	}
	
	
	private func extractTypeName(parameter: Typed, swiftType: Type, genericType: GenericType?, parsingContext: GlobalParsingContext, modificators: [InjectionModificator]) -> (typeName: String, plainTypeName: String) {
		
		var plainTypeName = parameter.unwrappedTypeName
		var typeName = TypeName.onlyDroppedOptional(name: parameter.typeName.name)
		if let genericTypeIndex = swiftType.genericTypeParameters.firstIndex(where: { $0.typeName.unwrappedTypeName == parameter.unwrappedTypeName }),
			let resolvedGenericType = genericType {
			if swiftType.genericTypeParameters.count == resolvedGenericType.typeParameters.count {
				let actualType = resolvedGenericType.typeParameters[genericTypeIndex]
				plainTypeName = actualType.typeName.unwrappedTypeName
				typeName = TypeName.onlyDroppedOptional(name: actualType.typeName.name)
			} else {
				// TODO: Throw error. Different generic argument counts not supported (Generic inheritance)
			}
		}
		if let forcedType = InjectionModificator.forcedType(modificators) {
			typeName = forcedType
			plainTypeName = TypeName.unwrapTypeName(name: forcedType).unwrappedTypeName
		}
		if InjectionModificator.isMany(modificators) {
			typeName = typeName.droppedArrayInfo()
			plainTypeName = plainTypeName.droppedArrayInfo()
		}
		
		// Typealias may be global or nested, so we check both variants
		let fullPossibleTypeName = "\(swiftType.name).\(plainTypeName)"
		let possibleTypealias = parsingContext.collectedInfo[plainTypeName]?.name ?? parsingContext.collectedInfo[fullPossibleTypeName]?.name
		if let typealiased = possibleTypealias {
			if !typeName.contains("<") {
				// Type name should not be only if its typealias, not generic
				typeName = TypeName.onlyDroppedOptional(name: typealiased)
			}
			plainTypeName = typealiased
		}
		return (typeName, plainTypeName)
	}
	
}
