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
	
	init?(functionName: String, invocationBody: String, argumentStack: [ArgumentInfo], tokenList: [DIToken], collectedInfo: [String: SwiftType]) {
		guard functionName == "register" || functionName == "register1" else {
			return nil
		}
		self.tokenList = tokenList
		if let typedRegistration = invocationBody.firstMatch("[a-zA-Z]+\\.self") {
			typeName = String(typedRegistration.dropLast(5))
		}
		fillTokenListWithInfo(collectedInfo: collectedInfo)
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
