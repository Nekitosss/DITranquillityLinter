//
//  GraphValidator.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 28/09/2018.
//

import Foundation


class GraphValidator {
	
	@discardableResult
	func validate(containerPart: ContainerPart, collectedInfo: [String: Type]) -> [String] {
		var errors: [String] = []
		
		for (registrationName, registrations) in containerPart.tokenInfo {
			if registrations.count > 1 {
				errors.append("Too many registrations for type")
			}
			for registration in registrations {
				errors += validate(registration: registration, collectedInfo: collectedInfo)
			}
		}
		
		return errors
	}
	
	func validate(registration: RegistrationToken, collectedInfo: [String: Type]) -> [String] {
		var errors: [String] = []
		guard let typeInfo = collectedInfo[registration.plainTypeName] else { return errors }
		
		for token in registration.tokenList {
			switch token {
			case let alias as AliasToken:
				if typeInfo.implements[alias.typeName] == nil && typeInfo.inherits[alias.typeName] == nil {
					errors.append("Does not inherits or conforms to \(alias.typeName)")
				}
			case let injection as InjectionToken:
				break
			default:
				break
			}
		}
		
		return errors
	}
	
	
	
}
