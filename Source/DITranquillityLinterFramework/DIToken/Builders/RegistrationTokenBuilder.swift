//
//  RegistrationTokenBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 28/09/2018.
//

import Foundation
import SourceKittenFramework

final class RegistrationTokenBuilder {
	
	typealias RegistrationInfo = (typeName: String, plainTypeName: String, tokenList: [DIToken])
	
	static func build(functionName: String, invocationBody: String, argumentStack: [ArgumentInfo], tokenList: [DIToken], collectedInfo: [String: Type], substructureList: [[String : SourceKitRepresentable]], content: NSString, bodyOffset: Int64, file: File) -> RegistrationToken? {
		guard functionName == DIKeywords.register.rawValue || functionName == DIKeywords.register1.rawValue else {
			return nil
		}
		
		var info: RegistrationInfo = ("", "", tokenList)
		
		// TODO: process generics here
		if let typedRegistration = invocationBody.firstMatch(RegExp.trailingTypeInfo) {
			// container.register(MyClass.self)
			info.typeName = typedRegistration.droppedDotSelf()
		}
		if let plainInfo = extractPlainRegistration(substructureList: substructureList, invocationBody: invocationBody, collectedInfo: collectedInfo, file: file, bodyOffset: bodyOffset) {
			info.typeName = plainInfo.typeName
			info.plainTypeName = plainInfo.plainTypeName
			info.tokenList += plainInfo.tokenList
		} else if let plainInfo = extractClosureRegistration(substructureList: substructureList, collectedInfo: collectedInfo, content: content, file: file, bodyOffset: bodyOffset) {
			info.typeName = plainInfo.typeName
			info.plainTypeName = plainInfo.plainTypeName
			info.tokenList += plainInfo.tokenList
		}
		info.tokenList = fillTokenListWithInfo(input: info.tokenList, typeName: info.typeName, collectedInfo: collectedInfo, content: content, file: file)
		return RegistrationToken(typeName: info.typeName, plainTypeName: info.plainTypeName, tokenList: info.tokenList)
	}
	
	private static func extractPlainRegistration(substructureList: [SourceKitStructure], invocationBody: String, collectedInfo: [String: Type], file: File, bodyOffset: Int64) -> RegistrationInfo? {
		// container.register(MyClass.init)
		guard substructureList.isEmpty && !invocationBody.hasSuffix(".self") else { return nil }
		let (typeName, fullTypeName, genericType) = self.parseTypeName(name: invocationBody)
		guard let dotIndex = invocationBody.reversed().index(of: ".")?.base else { return nil }
		let signatureText = String(invocationBody[invocationBody.index(after: dotIndex)...])
		let methodSignature = MethodSignature(name: signatureText, injectableArgumentInfo: [], injectionModificators: [:])
		
		var tokenList: [DIToken] = []
		if let methodInjection = MethodFinder.findMethodInfo(methodSignature: methodSignature, initialObjectName: typeName, collectedInfo: collectedInfo, file: file, genericType: genericType, methodCallBodyOffset: bodyOffset) {
			tokenList = methodInjection as [DIToken]
		}
		return (fullTypeName, typeName, tokenList)
	}
	
	private static func extractClosureRegistration(substructureList: [SourceKitStructure], collectedInfo: [String: Type], content: NSString, file: File, bodyOffset: Int64)  -> RegistrationInfo? {
		// container.register { MyClass.init($0, $1) }
		guard substructureList.count == 1 else { return nil }
		var substructure = substructureList[0]
		guard let closureKind: String = substructure.get(.kind), closureKind == SwiftExpressionKind.closure.rawValue else { return nil }
		guard let expressionCallInitSubstructure = (substructure.substructures ?? []).first else { return nil }
		substructure = expressionCallInitSubstructure
		
		guard let kind: String = substructure.get(.kind),
			let name: String = substructure.get(.name),
			kind == SwiftExpressionKind.call.rawValue
			else { return nil }
		let (typeName, fullTypeName, genericType) = self.parseTypeName(name: name)
		let argumentsSubstructure = substructure.get(.substructure, of: [SourceKitStructure].self) ?? []
		let methodName = restoreMethodName(registrationName: name)
		let signature = restoreSignature(name: methodName, substructureList: argumentsSubstructure, content: content)
		
		var tokenList: [DIToken] = []
		if let methodInjection = MethodFinder.findMethodInfo(methodSignature: signature, initialObjectName: typeName, collectedInfo: collectedInfo, file: file, genericType: genericType, methodCallBodyOffset: bodyOffset) {
			tokenList = methodInjection as [DIToken]
		}
		return (fullTypeName, typeName, tokenList)
	}
	
	private static func parseTypeName(name: String) -> (typeName: String, fullTypeName: String, genericType: GenericType?) {
		let name = name.droppedDotInit()
		if let genericType = Composer.parseGenericType(name) {
			return (genericType.name, name, genericType)
		} else {
			return (name, name, nil)
		}
	}
	
	private static func restoreMethodName(registrationName: String) -> String {
		if let dotIndex = registrationName.reversed().index(of: ".")?.base {
			return String(registrationName[dotIndex...])
		} else {
			return ""
		}
	}
	
	private static func restoreSignature(name: String, substructureList: [[String: SourceKitRepresentable]], content: NSString) -> MethodSignature {
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
				let body = content.substringUsingByteRange(start: bodyOffset, length: bodyLenght)
				else { continue }
			
			if body.firstMatch(RegExp.implicitClosureArgument) != nil {
				injectableArguments.append((argumentNumber, bodyOffset))
			}
			if let forcedType = body.firstMatch(RegExp.forcedType)?.trimmingCharacters(in: .whitespacesAndNewlines) {
				injectionModificators[argumentNumber, default: []].append(InjectionModificator.typed(forcedType))
			}
			if let taggedInjection = InjectionTokenBuilder.parseTaggedInjection(structure: substucture, content: content) {
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
	
	static func fillTokenListWithInfo(input: [DIToken], typeName: String, collectedInfo: [String: Type], content: NSString, file: File) -> [DIToken] {
		// Recursively walk through all classes and find injection type
		var result = [DIToken]()
		for token in input {
			if var injectionToken = token as? InjectionToken, injectionToken.typeName.isEmpty {
				if let (typeName, optionalInjection) = findArgumentTypeInfo(type: collectedInfo[typeName], tokenName: injectionToken.name) {
					injectionToken.typeName = typeName
					injectionToken.optionalInjection = optionalInjection
					result.append(injectionToken)
				} else {
					// after "findMethodTypeInfo" we not input type info. We write new tokens.
					// so we no need append old
					let methodInjectedTokens = findMethodTypeInfo(typeName: typeName, collectedInfo: collectedInfo, content: content, file: file, token: injectionToken)
					result += methodInjectedTokens
				}
			} else {
				result.append(token)
			}
		}
		
		return result
	}
	
	private static func findMethodTypeInfo(typeName: String, collectedInfo: [String: Type], content: NSString, file: File, token: InjectionToken) -> [DIToken] {
		guard let substructure = token.injectionSubstructureList.last,
			var methodName: String = substructure.get(.name),
			let offset: Int64 = substructure.get(.offset)
			else { return [] }
		
		if let dotIndex = methodName.index(of: ".") {
			methodName = String(methodName[methodName.index(after: dotIndex)...])
		}
		let argumentsSubstructure = substructure.get(.substructure, of: [SourceKitStructure].self) ?? []
		let signature = restoreSignature(name: methodName, substructureList: argumentsSubstructure, content: content)
		// TODO: Method generic type unwrapping
		if let methodInjection = MethodFinder.findMethodInfo(methodSignature: signature, initialObjectName: typeName, collectedInfo: collectedInfo, file: file, genericType: nil, methodCallBodyOffset: offset) {
			return methodInjection
		}
		return []
	}
	
	private static func findArgumentTypeInfo(type: Type?, tokenName: String) -> (typeName: String, optionalInjection: Bool)? {
		guard let ownerType = type else { return nil }
		if let variable = ownerType.variables.first(where: { $0.name == tokenName }) {
			return (variable.unwrappedTypeName, variable.isOptional)
		}
		for parent in ownerType.inherits {
			if let result = findArgumentTypeInfo(type: parent.value, tokenName: tokenName) {
				return result
			}
		}
		return nil
	}
	
}
