//
//  GraphValidator.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 28/09/2018.
//

import Foundation

struct GraphError: Error, Equatable {
	let infoString: String
	let location: Location
	
	var xcodeMessage: String {
		return [
			"\(location): ",
			"error: ",
			infoString
			].joined()
	}
}

final class GraphValidator {
	
	func validate(containerPart: ContainerPart, collectedInfo: [String: Type]) -> [GraphError] {
		var errors: [GraphError] = []
		
		for (_, registrations) in containerPart.tokenInfo {
			for registration in registrations {
				errors += validate(registration: registration, collectedInfo: collectedInfo, containerPart: containerPart)
				if registrations.count > 1 {
					let info = "Too many registrations for type: \(registration.typeName)"
					errors.append(GraphError(infoString: info, location: registration.location))
				}
			}
		}
		
		return compose(errorList: errors)
	}
	
	
	private func validate(registration: RegistrationToken, collectedInfo: [String: Type], containerPart: ContainerPart) -> [GraphError] {
		var errors: [GraphError] = []
		guard let typeInfo = collectedInfo[registration.plainTypeName] else { return errors }
		
		for token in registration.tokenList {
			switch token {
			case let alias as AliasToken:
				let inheritanceAndImplementations = typeInfo.inheritanceAndImplementations
				if alias.typeName != registration.typeName && inheritanceAndImplementations[alias.typeName] == nil && inheritanceAndImplementations[alias.plainTypeName] == nil {
					let info = "Does not inherits from \(alias.plainTypeName) or not conforms to \(alias.typeName)"
					errors.append(GraphError(infoString: info, location: alias.location))
				}
			case let injection as InjectionToken:
				let accessor = injection.registrationAccessor
				if containerPart.tokenInfo[accessor] == nil {
					var info = "injection not found registration with type: \(accessor.typeName)"
					if !accessor.tag.isEmpty {
						info += ", tag: \(accessor.tag)"
					}
					errors.append(GraphError(infoString: info, location: injection.location))
				}
				
			default:
				break
			}
		}
		
		return errors
	}
	

	private func compose(errorList: [GraphError]) -> [GraphError] {
		var result: [GraphError] = []
		for error in errorList {
			if !result.contains(error) {
				result.append(error)
			}
		}
		return result
	}
	
	
}
