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
	
	let autoimplementedTypes: Set<String> = ["AnyObject", "Any"]
	
	func validate(containerPart: ContainerPart, collectedInfo: [String: Type]) -> [GraphError] {
		var errors: [GraphError] = []
		
		for (_, registrations) in containerPart.tokenInfo {
			for registration in registrations {
				errors += validate(registration: registration, collectedInfo: collectedInfo, containerPart: containerPart)
				if let severalRegistrationErr = validateSeveralRegistrationsForType(registrations: registrations, validatingRegistration: registration) {
					errors.append(severalRegistrationErr)
				}
			}
		}
		
		return compose(errorList: errors)
	}
	
	private func validateSeveralRegistrationsForType(registrations: [RegistrationToken], validatingRegistration: RegistrationToken) -> GraphError? {
		guard registrations.count > 1 else { return nil }
		let defaultCount = registrations.filter({ registration in
			registration.tokenList.contains(where: { $0 is IsDefaultToken })
		}).count
		
		if defaultCount == 0 {
			// Its ok to have just many registrations for one type. Error can be thrown in not many injection
			return nil
		} else if defaultCount > 1 {
			let info = buildHaseMoreThanOneDefaultRegistratioinsForType(registrationName: validatingRegistration.typeName)
			return GraphError(infoString: info, location: validatingRegistration.location)
		} else {
			return nil
		}
	}
	
	private func buildTooManyRegistrationsForType(registrationName: String) -> String {
		return "Too many registrations for \"\(registrationName)\" type. Make one of registration as default or delete redundant registration."
	}
	
	private func buildHaseMoreThanOneDefaultRegistratioinsForType(registrationName: String) -> String {
		return "Too many default registrations for \"\(registrationName)\" type. Make exact one of registration as default or delete redundant registration."
	}
	
	private func validate(registration: RegistrationToken, collectedInfo: [String: Type], containerPart: ContainerPart) -> [GraphError] {
		var errors: [GraphError] = []
		guard let typeInfo = collectedInfo[registration.plainTypeName] else { return errors }
		
		for token in registration.tokenList {
			switch token {
			case let alias as AliasToken:
				if !alias.tag.isEmpty && collectedInfo[alias.tag] == nil {
					let info = buildTagTypeNotFoundMessage(tagName: alias.tag)
					errors.append(GraphError(infoString: info, location: alias.location))
				}
				guard alias.typeName != registration.typeName && !autoimplementedTypes.contains(alias.typeName) else { continue }
				let inheritanceAndImplementations = typeInfo.inheritanceAndImplementations
				for aliasType in alias.decomposedTypes {
					let aliasTypeName = nsObjectProtocolConvert(aliasType)
					guard inheritanceAndImplementations[aliasTypeName] == nil && !typeInfo.inheritedTypes.contains(aliasTypeName) else { continue }
					let info = buildNotFoundAliasMessage(alias: alias)
					errors.append(GraphError(infoString: info, location: alias.location))
				}
				
			case let injection as InjectionToken:
				let accessor = injection.getRegistrationAccessor()
				if !accessor.tag.isEmpty && collectedInfo[accessor.tag] == nil {
					let info = buildTagTypeNotFoundMessage(tagName: accessor.tag)
					errors.append(GraphError(infoString: info, location: injection.location))
				} else if let registrations = containerPart.tokenInfo[accessor] {
					let defaultCount = registrations.filter({ registration in
						registration.tokenList.contains(where: { $0 is IsDefaultToken })
					}).count
					if registrations.count > 1 && !injection.isMany && defaultCount != 1 {
						let info = buildTooManyRegistrationsForType(injection: injection, accessor: accessor)
						errors.append(GraphError(infoString: info, location: injection.location))
					}
				} else if !injection.optionalInjection {
					let info = buildNotFoundRegistrationMessage(injection: injection, accessor: accessor)
					errors.append(GraphError(infoString: info, location: injection.location))
				}
				
			default:
				break
			}
		}
		
		return errors
	}
	
	private func nsObjectProtocolConvert(_ name: String) -> String {
		return name == "NSObjectProtocol" ? "NSObject" : name
	}
	
	private func buildTagTypeNotFoundMessage(tagName: String) -> String {
		return "Could not resolve \"\(tagName)\" type"
	}
	
	private func buildNotFoundAliasMessage(alias: AliasToken) -> String {
		if alias.plainTypeName != alias.typeName {
			return "Does not inherits from \"\(alias.plainTypeName)\" or not conforms to \"\(alias.typeName)\""
		} else {
			return "Does not inherits nor conforms to \"\(alias.typeName)\""
		}
	}
	
	private func buildNotFoundRegistrationMessage(injection: InjectionToken, accessor: RegistrationAccessor) -> String {
		let injectionType = injection.methodInjection ? "method" : "variable"
		var info = "Not found registration with \"\(accessor.typeName)\" type"
		if !accessor.tag.isEmpty {
			info += ", tag: \"\(accessor.tag)\""
		}
		info += " for \"\(injection.name)\" \"\(injectionType)\" injection"
		return info
	}
	
	
	private func buildTooManyRegistrationsForType(injection: InjectionToken, accessor: RegistrationAccessor) -> String {
		let injectionType = injection.methodInjection ? "method" : "variable"
		var info = "Too many registration with \"\(accessor.typeName)\" type"
		if !accessor.tag.isEmpty {
			info += ", tag: \"\(accessor.tag)\""
		}
		info += " for \"\(injection.name)\" \"\(injectionType)\" injection"
		return info
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
