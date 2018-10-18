//
//  TypeFinder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 10/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import SourceKittenFramework
import Foundation

class TypeFinder {
	
	
	static func parseTypeName(name: String) -> (typeName: String, fullTypeName: String, genericType: GenericType?) {
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
	
	static func restoreMethodName(registrationName: String) -> String {
		if let dotIndex = registrationName.reversed().index(of: ".")?.base {
			return String(registrationName[dotIndex...])
		} else {
			return ""
		}
	}
	
	static func restoreSignature(name: String, substructureList: [[String: SourceKitRepresentable]], content: NSString) -> MethodSignature {
		var signatureName = name.isEmpty ? "init" : name
		var injectableArguments: [(Int, Int64)] = []
		var injectionModificators: [Int : [InjectionModificator]] = [:]
		if !substructureList.isEmpty {
			signatureName.append("(")
		}
		var argumentNumber = 0
		for substucture in substructureList {
			
			let name = substucture.get(.name, of: String.self) ?? "_"
			guard let kind: String = substucture.get(.kind),
				let bodyLenght: Int64 = substucture.get(.bodyLength),
				let bodyOffset: Int64 = substucture.get(.bodyOffset),
				kind == SwiftExpressionKind.argument.rawValue,
				let body = content.substringUsingByteRange(start: bodyOffset, length: bodyLenght)?.bracketsBalancing()
				else { continue }
			
			if body.firstMatch(RegExp.implicitClosureArgument) != nil {
				injectableArguments.append((argumentNumber, bodyOffset))
			}
			if let forcedType = body.firstMatch(RegExp.forcedType)?.trimmingCharacters(in: .whitespacesAndNewlines) {
				injectionModificators[argumentNumber, default: []].append(InjectionModificator.typed(forcedType))
			}
			if let taggedInjection = InjectionTokenBuilder.parseTaggedAndManyInjectionInjection(structure: substucture, content: content) {
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
	
	static func findMethodTypeInfo(typeName: String, parsingContext: ParsingContext, content: NSString, file: File, token: InjectionToken) -> [DIToken] {
		guard let substructure = token.injectionSubstructureList.last,
			var methodName: String = substructure.get(.name),
			let offset: Int64 = substructure.get(.offset)
			else { return [] }
		
		if let dotIndex = methodName.index(of: ".") {
			methodName = String(methodName[methodName.index(after: dotIndex)...])
		}
		let argumentsSubstructure = substructure.get(.substructure, of: [SourceKitStructure].self) ?? []
		let signature = restoreSignature(name: methodName, substructureList: argumentsSubstructure, content: content)
		
		let (plainTypeName, _, genericType) = self.parseTypeName(name: typeName)
		if let methodInjection = TypeFinder.findMethodInfo(methodSignature: signature, initialObjectName: plainTypeName, parsingContext: parsingContext, file: file, genericType: genericType, methodCallBodyOffset: offset, forcedAllInjection: false) {
			return methodInjection
		}
		return []
	}
	
	static func findMethodInfo(methodSignature: MethodSignature, initialObjectName: String, parsingContext: ParsingContext, file: File, genericType: GenericType?, methodCallBodyOffset: Int64, forcedAllInjection: Bool) -> [InjectionToken]? {
		guard let swiftType = parsingContext.collectedInfo[initialObjectName] else { return [] }
		let isPlainSignature = !methodSignature.name.contains("(")
		
		let extractInfoBlock: (Method) -> [InjectionToken]? = {
			return extractArgumentInfo(swiftType: swiftType, methodSignature: methodSignature, parameters: $0.parameters, file: file, methodCallBodyOffset: methodCallBodyOffset, genericType: genericType, parsingContext: parsingContext, forcedAllInjection: forcedAllInjection)
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
	
	static func findArgumentTypeInfo(typeName: String, tokenName: String, parsingContext: ParsingContext, modificators: [InjectionModificator]) -> (typeName: String, plainTypeName: String, optionalInjection: Bool)? {
		let (plainTypeName, _, genericType) = self.parseTypeName(name: typeName)
		guard let ownerType = parsingContext.collectedInfo[plainTypeName] else { return nil }
		if let variable = ownerType.allVariables.first(where: { $0.name == tokenName }) {
			let (typeName, plainTypeName) = extractTypeName(parameter: variable, swiftType: ownerType, genericType: genericType, parsingContext: parsingContext, modificators: modificators)
			return (typeName, plainTypeName, variable.isOptional)
		}
		return nil
	}
	
	static func extractArgumentInfo(swiftType: Type, methodSignature: MethodSignature, parameters: [MethodParameter], file: File, methodCallBodyOffset: Int64, genericType: GenericType?, parsingContext: ParsingContext, forcedAllInjection: Bool) -> [InjectionToken] {
		var argumentInfo: [InjectionToken] = []
		var argumentIndex = -1
		for parameter in parameters {
			argumentIndex += 1
			
			let injectableArgInfo = methodSignature.injectableArgumentInfo.first(where: { $0.argumentCount == argumentIndex }) ?? (-1, methodCallBodyOffset)
			guard forcedAllInjection || injectableArgInfo.argumentCount == argumentIndex else { continue }
			let modificators = methodSignature.injectionModificators[argumentIndex] ?? []
			let (typeName, plainTypeName) = extractTypeName(parameter: parameter, swiftType: swiftType, genericType: genericType, parsingContext: parsingContext, modificators: modificators)
			let location = Location(file: file, byteOffset: injectableArgInfo.argumentBodyOffset)
			
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
					break
				}
			}
			argumentInfo.append(injection)
		}
		return argumentInfo
	}
	
	private static func extractTypeName(parameter: Typed, swiftType: Type, genericType: GenericType?, parsingContext: ParsingContext, modificators: [InjectionModificator]) -> (typeName: String, plainTypeName: String) {
		
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
