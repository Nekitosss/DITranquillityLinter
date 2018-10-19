//
//  RegistrationTokenBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 28/09/2018.
//

import Foundation
import SourceKittenFramework

/// Trying to create RegsitrationToken. Resolves containing InjectionToken types.
final class RegistrationTokenBuilder {
	
	typealias RegistrationInfo = (typeName: String, plainTypeName: String, tokenList: [DIToken])
	
	static func build(functionName: String, invocationBody: String, tokenList: [DIToken], parsingContext: ParsingContext, substructureList: [[String : SourceKitRepresentable]], content: NSString, bodyOffset: Int64, file: File) -> RegistrationToken? {
		guard functionName == DIKeywords.register.rawValue || functionName == DIKeywords.register1.rawValue else {
			return nil
		}
		
		var info: RegistrationInfo = ("", "", tokenList)
		
		// TODO: process generics here
		if let typedRegistration = invocationBody.firstMatch(RegExp.trailingTypeInfo) {
			// container.register(MyClass.self)
			info.typeName = typedRegistration.droppedDotSelf()
			info.plainTypeName = TypeFinder.parseTypeName(name: info.typeName).typeName
		}
		let plainInfo = extractPlainRegistration(substructureList: substructureList, invocationBody: invocationBody, parsingContext: parsingContext, file: file, bodyOffset: bodyOffset)
			?? extractClosureRegistration(substructureList: substructureList, parsingContext: parsingContext, content: content, file: file, bodyOffset: bodyOffset)
		if let plainInfo = plainInfo {
			info.typeName = plainInfo.typeName
			info.plainTypeName = plainInfo.plainTypeName
			info.tokenList += plainInfo.tokenList
		}
		info.typeName = parsingContext.collectedInfo[info.typeName]?.name ?? info.typeName
		info.typeName = info.typeName.trimmingCharacters(in: .whitespacesAndNewlines)
		info.plainTypeName = info.plainTypeName.trimmingCharacters(in: .whitespacesAndNewlines)
		
		// Class registration by default available by its own type without tag.
		let location = Location(file: file, byteOffset: bodyOffset)
		let aliasToken = AliasToken(typeName: info.typeName, tag: "", location: location)
		info.tokenList.append(aliasToken)
		
		info.tokenList = fillTokenListWithInfo(input: info.tokenList, registrationTypeName: info.typeName, parsingContext: parsingContext, content: content, file: file)
		return RegistrationToken(typeName: info.typeName, plainTypeName: info.plainTypeName, location: location, tokenList: info.tokenList)
	}
	
	private static func extractPlainRegistration(substructureList: [SourceKitStructure], invocationBody: String, parsingContext: ParsingContext, file: File, bodyOffset: Int64) -> RegistrationInfo? {
		// container.register(MyClass.init)
		guard substructureList.isEmpty && !invocationBody.hasSuffix(".self") else { return nil }
		let (typeName, fullTypeName, genericType) = TypeFinder.parseTypeName(name: invocationBody)
		guard let dotIndex = invocationBody.lastIndex(of: ".") else { return nil }
		let signatureText = String(invocationBody[invocationBody.index(after: dotIndex)...])
		let methodSignature = MethodSignature(name: signatureText, injectableArgumentInfo: [], injectionModificators: [:])
		
		var tokenList: [DIToken] = []
		if let methodInjection = TypeFinder.findMethodInfo(methodSignature: methodSignature, initialObjectName: typeName, parsingContext: parsingContext, file: file, genericType: genericType, methodCallBodyOffset: bodyOffset, forcedAllInjection: true) {
			tokenList = methodInjection as [DIToken]
		}
		return (fullTypeName, typeName, tokenList)
	}
	
	private static func extractClosureRegistration(substructureList: [SourceKitStructure], parsingContext: ParsingContext, content: NSString, file: File, bodyOffset: Int64)  -> RegistrationInfo? {
		// container.register { MyClass.init($0, $1) }
		guard substructureList.count == 1 else { return nil }
		var substructure = substructureList[0]
		guard let closureKind: String = substructure.get(.kind), closureKind == SwiftExpressionKind.closure.rawValue else { return nil }
		if let expressionCallInitSubstructure = substructure.substructures.first {
			substructure = expressionCallInitSubstructure
			
			guard let kind: String = substructure.get(.kind),
				let name: String = substructure.get(.name),
				kind == SwiftExpressionKind.call.rawValue
				else { return nil }
			let (typeName, fullTypeName, genericType) = TypeFinder.parseTypeName(name: name)
			let argumentsSubstructure = substructure.get(.substructure, of: [SourceKitStructure].self) ?? []
			
			// Handle MyClass.NestedClass()
			// NestedClass can be class name, but it also can be expression call. So we check is MyClass.NestedClass available class name
			// and if if exists, adds ".init" at the end of initialization call
			let nameWithInitializer = parsingContext.collectedInfo[name] != nil && !name.hasSuffix(".init") ? name + ".init" : name
			let methodName = TypeFinder.restoreMethodName(registrationName: nameWithInitializer)
			let signature = TypeFinder.restoreSignature(name: methodName, substructureList: argumentsSubstructure, content: content)
			
			var tokenList: [DIToken] = []
			if let methodInjection = TypeFinder.findMethodInfo(methodSignature: signature, initialObjectName: typeName, parsingContext: parsingContext, file: file, genericType: genericType, methodCallBodyOffset: bodyOffset, forcedAllInjection: false) {
				tokenList = methodInjection as [DIToken]
			}
			return (fullTypeName, typeName, tokenList)
			
		} else if let bodyOffset: Int64 = substructure.get(.bodyOffset),
			let bodyLength: Int64 = substructure.get(.bodyLength),
			let body = content.substringUsingByteRange(start: bodyOffset, length: bodyLength)?.trimmingCharacters(in: .whitespacesAndNewlines),
			let lastDotIndex = body.lastIndex(of: ".") {
			// Static variable registration
			
			let typeContainerName = String(body[..<lastDotIndex])
			let staticVariableName = String(body[body.index(after: lastDotIndex)...])
			if let (typeName, plainTypeName, _) = TypeFinder.findArgumentTypeInfo(typeName: typeContainerName, tokenName: staticVariableName, parsingContext: parsingContext, modificators: []) {
				return (typeName, plainTypeName, [])
			}
		}
		
		return nil
	}
	
	static func fillTokenListWithInfo(input: [DIToken], registrationTypeName: String, parsingContext: ParsingContext, content: NSString, file: File) -> [DIToken] {
		// Recursively walk through all classes and find injection type
		var result = [DIToken]()
		for token in input {
			// injectionToken.typeName.isEmpty always really empty here (in alpha at least)
			if var injectionToken = token as? InjectionToken, injectionToken.typeName.isEmpty {
				if let foundedInfo = TypeFinder.findArgumentTypeInfo(typeName: registrationTypeName, tokenName: injectionToken.name, parsingContext: parsingContext, modificators: injectionToken.modificators) {
					injectionToken.typeName = foundedInfo.typeName
					injectionToken.plainTypeName = foundedInfo.plainTypeName
					injectionToken.optionalInjection = foundedInfo.optionalInjection
					result.append(injectionToken)
				} else {
					// after "findMethodTypeInfo" we not input type info. We write new tokens.
					// so we no need append old
					let methodInjectedTokens = TypeFinder.findMethodTypeInfo(typeName: registrationTypeName, parsingContext: parsingContext, content: content, file: file, token: injectionToken)
					result += methodInjectedTokens
				}
			} else {
				result.append(token)
			}
		}
		
		return result
	}
	
}
