//
//  RegistrationToken.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 22/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework

class RegistrationToken: DIToken {
	
	var typeName: String = ""
	var tokenList: [DIToken] = []
	
	init?(functionName: String, invocationBody: String, argumentStack: [ArgumentInfo], tokenList: [DIToken], collectedInfo: [String: SwiftType], substructureList: [[String : SourceKitRepresentable]], content: NSString) {
		guard functionName == "register" || functionName == "register1" else {
			return nil
		}
		self.tokenList = tokenList
		if let typedRegistration = invocationBody.firstMatch("[a-zA-Z]+\\.self") {
			typeName = String(typedRegistration.dropLast(5))
		}
		extractClosureRegistration(substructureList: substructureList, collectedInfo: collectedInfo, content: content)
		fillTokenListWithInfo(collectedInfo: collectedInfo)
	}
	
	private func extractClosureRegistration(substructureList: [[String : SourceKitRepresentable]], collectedInfo: [String: SwiftType], content: NSString) {
		guard substructureList.count == 1 else { return }
		let substructure = substructureList[0]
		guard let kind = substructure[SwiftDocKey.kind.rawValue] as? String,
			let name = substructure[SwiftDocKey.name.rawValue] as? String,
			kind == SwiftExpressionKind.call.rawValue
			else { return }
		self.typeName = name.hasSuffix(".init") ? String(name.dropLast(5)) : name
		let argumentsSubstructure = substructure.get(.substructure, of: [SourceKitObject].self) ?? []
		let signature = restoreSignature(name: name, substructureList: argumentsSubstructure, content: content)
		if let methodInjection = MethodFinder.findMethodInfo(methodSignature: signature, initialObjectName: typeName, collectedInfo: collectedInfo) {
			self.tokenList += methodInjection as [DIToken]
		}
	}
	
	private func restoreSignature(name: String, substructureList: [[String: SourceKitRepresentable]], content: NSString) -> MethodSignature {
		var signatureName = "init"
		var injectableArguments: [Int] = []
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
			if body.firstMatch("\\$[0-9][0-9]?") != nil {
				injectableArguments.append(argumentNumber)
			}
			if let forcedType = body.firstMatch(InjectionToken.forcedTypeRegexp)?.trimmingCharacters(in: .whitespacesAndNewlines) {
				injectionModificators[argumentNumber, default: []].append(InjectionModificator.typed(forcedType))
			}
			signatureName += name + ":"
			argumentNumber += 1
		}
		if !substructureList.isEmpty {
			signatureName.append(")")
		}
		return MethodSignature(name: signatureName, injectableArgumentNumbers: injectableArguments, injectionModificators: injectionModificators)
	}
	
	private func fillTokenListWithInfo(collectedInfo: [String: SwiftType]) {
		let injectionTokens = tokenList.compactMap({ $0 as? InjectionToken })
		for token in injectionTokens where token.typeName.isEmpty {
			findTypeInfo(in: collectedInfo, typeName: self.typeName, token: token)
		}
	}
	
	@discardableResult
	private func findTypeInfo(in collectedInfo: [String: SwiftType], typeName: String, token: InjectionToken) -> Bool {
		guard let ownerType = collectedInfo[typeName] else { return false }
		let structuredInfo = ownerType.substructure
		for structure in structuredInfo {
			guard let declarationKind: String = structure.get(.kind),
				let name: String = structure.get(.name),
				var typeName: String = structure.get(.typeName),
				declarationKind == SwiftDeclarationKind.varInstance.rawValue,
				name == token.name else {
					continue
			}
			token.optionalInjection = typeName.contains("?")
			if typeName.hasSuffix("?") || typeName.hasSuffix("!") {
				typeName = String(typeName.dropLast())
			}
			token.typeName = typeName
			return true
		}
		for parent in ownerType.inheritedTypes {
			if findTypeInfo(in: collectedInfo, typeName: parent, token: token) {
				return true
			}
		}
		return false
	}
	
}
