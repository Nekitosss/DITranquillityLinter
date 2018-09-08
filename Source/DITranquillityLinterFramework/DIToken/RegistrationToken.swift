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
	
	init?(functionName: String, invocationBody: String, argumentStack: [ArgumentInfo], tokenList: [DIToken], collectedInfo: [String: SwiftType], substructureList: [[String : SourceKitRepresentable]]) {
		guard functionName == "register" || functionName == "register1" else {
			return nil
		}
		self.tokenList = tokenList
		if let typedRegistration = invocationBody.firstMatch("[a-zA-Z]+\\.self") {
			typeName = String(typedRegistration.dropLast(5))
		}
		extractClosureRegistration(substructureList: substructureList)
		fillTokenListWithInfo(collectedInfo: collectedInfo)
	}
	
	private func extractClosureRegistration(substructureList: [[String : SourceKitRepresentable]]) {
		guard substructureList.count == 1 else { return }
		let substructure = substructureList[0]
		guard let kind = substructure[SwiftDocKey.kind.rawValue] as? String,
			let name = substructure[SwiftDocKey.name.rawValue] as? String,
			kind == SwiftExpressionKind.call.rawValue
			else { return }
		self.typeName = name.hasSuffix(".init") ? String(name.dropLast(5)) : name
		let argumentsSubstructure = substructure[SwiftDocKey.substructure.rawValue] as? [[String : SourceKitRepresentable]] ?? []
		let signature = restoreSignature(name: name, substructureList: argumentsSubstructure)
	}
	
	private func restoreSignature(name: String, substructureList: [[String: SourceKitRepresentable]]) -> String {
		var signature = "init"
		if !substructureList.isEmpty {
			signature.append("(")
		}
		for substucture in substructureList {
			let name = substucture[SwiftDocKey.name.rawValue] as? String ?? "_"
			guard let kind = substucture[SwiftDocKey.kind.rawValue] as? String,
				kind == SwiftExpressionKind.argument.rawValue
				else { continue }
			signature += name + ":"
		}
		if !substructureList.isEmpty {
			signature.append(")")
		}
		return signature
	}
	
	private func fillTokenListWithInfo(collectedInfo: [String: SwiftType]) {
		let injectionTokens = tokenList.compactMap({ $0 as? InjectionToken })
		for token in injectionTokens where token.typeName.isEmpty {
			findTypeInfo(in: collectedInfo, token: token)
		}
	}
	
	private func findTypeInfo(in collectedInfo: [String: SwiftType], token: InjectionToken) {
		guard let ownerType = collectedInfo[typeName] else { return }
		let structuredInfo = ownerType.substructure
		for structure in structuredInfo {
			guard let declarationKind = structure[SwiftDocKey.kind.rawValue] as? String,
				let name = structure[SwiftDocKey.name.rawValue] as? String,
				var typeName = structure[SwiftDocKey.typeName.rawValue] as? String,
				declarationKind == SwiftDeclarationKind.varInstance.rawValue,
				name == token.name else {
					continue
			}
			token.optionalInjection = typeName.contains("?")
			if typeName.hasSuffix("?") || typeName.hasSuffix("!") {
				typeName = String(typeName.dropLast())
			}
			token.typeName = typeName
			return
		}
	}
	
}
