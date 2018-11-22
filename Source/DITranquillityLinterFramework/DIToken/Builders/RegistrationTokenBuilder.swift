//
//  RegistrationTokenBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 28/09/2018.
//

import Foundation
import SourceKittenFramework

/// Trying to create RegsitrationToken. Resolves containing InjectionToken types.
final class RegistrationTokenBuilder: TokenBuilder {
	
	typealias RegistrationInfo = (typeName: String, plainTypeName: String, tokenList: [DIToken])
	
	private let parsingContext: ParsingContext
	private let content: NSString
	private let file: File
	
	init(parsingContext: ParsingContext, content: NSString, file: File) {
		self.parsingContext = parsingContext
		self.content = content
		self.file = file
	}
	
	func build(using info: TokenBuilderInfo) -> DIToken? {
		guard info.functionName == DIKeywords.register.rawValue || info.functionName == DIKeywords.register1.rawValue else {
			return nil
		}
		
		var registrationInfo: RegistrationInfo = ("", "", info.tokenList)
		
		// TODO: process generics here
		if let typedRegistration = info.invocationBody.firstMatch(RegExp.trailingTypeInfo) {
			// container.register(MyClass.self)
			registrationInfo.typeName = typedRegistration.droppedDotSelf()
			registrationInfo.plainTypeName = TypeFinder.parseTypeName(name: registrationInfo.typeName).typeName
		}
		let plainInfo = extractPlainRegistration(substructureList: info.substructureList, invocationBody: info.invocationBody, parsingContext: parsingContext, file: file, bodyOffset: info.bodyOffset)
			?? extractClosureRegistration(substructureList: info.substructureList, parsingContext: parsingContext, content: content, file: file, bodyOffset: info.bodyOffset)
		if let plainInfo = plainInfo {
			registrationInfo.typeName = plainInfo.typeName
			registrationInfo.plainTypeName = plainInfo.plainTypeName
			registrationInfo.tokenList += plainInfo.tokenList
		}
		registrationInfo.typeName = parsingContext.collectedInfo[registrationInfo.typeName]?.name ?? registrationInfo.typeName
		registrationInfo.typeName = registrationInfo.typeName.trimmingCharacters(in: .whitespacesAndNewlines)
		registrationInfo.plainTypeName = registrationInfo.plainTypeName.trimmingCharacters(in: .whitespacesAndNewlines)
		
		// Class registration by default available by its own type without tag.
		let location = Location(file: file, byteOffset: info.bodyOffset)
		let aliasToken = AliasToken(typeName: registrationInfo.typeName, tag: "", location: location)
		registrationInfo.tokenList.append(aliasToken)
		
		registrationInfo.tokenList = RegistrationTokenBuilder.fillTokenListWithInfo(input: registrationInfo.tokenList, registrationTypeName: registrationInfo.typeName, parsingContext: parsingContext, content: content, file: file)
		return RegistrationToken(typeName: registrationInfo.typeName, plainTypeName: registrationInfo.plainTypeName, location: location, tokenList: registrationInfo.tokenList)
	}
	
	private func extractPlainRegistration(substructureList: [SourceKitStructure], invocationBody: String, parsingContext: ParsingContext, file: File, bodyOffset: Int64) -> RegistrationInfo? {
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
	
	private func extractClosureRegistration(substructureList: [SourceKitStructure], parsingContext: ParsingContext, content: NSString, file: File, bodyOffset: Int64)  -> RegistrationInfo? {
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
