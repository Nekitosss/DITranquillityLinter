//
//  RegistrationToken.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 22/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework
import xcodeproj

class RegistrationToken: DIToken {
	
	var typeName: String = ""
	var tokenList: [DIToken] = []
	
	init?(functionName: String, invocationBody: String, argumentStack: [ArgumentInfo], tokenList: [DIToken], collectedInfo: [String: Type], substructureList: [[String : SourceKitRepresentable]], content: NSString, bodyOffset: Int64, file: File) {
		guard functionName == DIKeywords.register.rawValue || functionName == DIKeywords.register1.rawValue else {
			return nil
		}
		self.tokenList = tokenList
		if let typedRegistration = invocationBody.firstMatch(RegExp.typeInfo) {
			typeName = String(typedRegistration.dropLast(5))
		}
		extractClosureRegistration(substructureList: substructureList, collectedInfo: collectedInfo, content: content, file: file)
		fillTokenListWithInfo(collectedInfo: collectedInfo, content: content, file: file)
	}
	
	private func extractClosureRegistration(substructureList: [[String : SourceKitRepresentable]], collectedInfo: [String: Type], content: NSString, file: File) {
		guard substructureList.count == 1 else { return }
		let substructure = substructureList[0]
		guard let kind: String = substructure.get(.kind),
			let name: String = substructure.get(.name),
			let bodyOffset: Int64 = substructure.get(.bodyOffset),
			kind == SwiftExpressionKind.call.rawValue
			else { return }
		self.typeName = name.hasSuffix(".init") ? String(name.dropLast(5)) : name
		let argumentsSubstructure = substructure.get(.substructure, of: [SourceKitStructure].self) ?? []
		let signature = RegistrationToken.restoreSignature(name: name, substructureList: argumentsSubstructure, content: content)
		if let methodInjection = MethodFinder.findMethodInfo(methodSignature: signature, initialObjectName: typeName, collectedInfo: collectedInfo, file: file) {
			self.tokenList += methodInjection as [DIToken]
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
				let body = content.substringUsingByteRange(start: bodyOffset, length: bodyLenght)
				else { continue }
			
			if body.firstMatch(RegExp.implicitClosureArgument) != nil {
				injectableArguments.append((argumentNumber, bodyOffset))
			}
			if let forcedType = body.firstMatch(RegExp.forcedType)?.trimmingCharacters(in: .whitespacesAndNewlines) {
				injectionModificators[argumentNumber, default: []].append(InjectionModificator.typed(forcedType))
			}
			signatureName += name + ":"
			argumentNumber += 1
		}
		if !substructureList.isEmpty {
			signatureName.append(")")
		}
		return MethodSignature(name: signatureName, injectableArgumentInfo: injectableArguments, injectionModificators: injectionModificators)
	}
	
	private func fillTokenListWithInfo(collectedInfo: [String: Type], content: NSString, file: File) {
		let injectionTokens = tokenList.compactMap({ $0 as? InjectionToken })
		for token in injectionTokens where token.typeName.isEmpty {
			findArgumentTypeInfo(type: collectedInfo[typeName], token: token)
		}
		for token in injectionTokens where token.typeName.isEmpty {
			findMethodTypeInfo(collectedInfo: collectedInfo, content: content, file: file, token: token)
		}
	}
	
	private func findMethodTypeInfo(collectedInfo: [String: Type], content: NSString, file: File, token: InjectionToken) {
		if let substructure = token.injectionSubstructureList.last,
			var methodName = substructure.get(.name, of: String.self) {
			if let dotIndex = methodName.index(of: ".") {
				methodName = String(methodName[methodName.index(after: dotIndex)...])
			}
			let argumentsSubstructure = substructure.get(.substructure, of: [SourceKitStructure].self) ?? []
			let signature = RegistrationToken.restoreSignature(name: methodName, substructureList: argumentsSubstructure, content: content)
			if let methodInjection = MethodFinder.findMethodInfo(methodSignature: signature, initialObjectName: typeName, collectedInfo: collectedInfo, file: file) {
				self.tokenList += methodInjection as [DIToken]
			}
		}
	}
	
	@discardableResult
	private func findArgumentTypeInfo(type: Type?, token: InjectionToken) -> Bool {
		guard let ownerType = type else { return false }
		if let variable = ownerType.variables.first(where: { $0.name == token.name }) {
			token.typeName = variable.unwrappedTypeName
			token.optionalInjection = variable.isOptional
			return true
		}
		for parent in ownerType.inherits {
			if findArgumentTypeInfo(type: parent.value, token: token) {
				return true
			}
		}
		return false
	}
	
}
