


import Foundation


final class GraphValidator {
	
	let autoimplementedTypes: Set<String> = ["AnyObject", "Any"]
	
	func validate(containerPart: ContainerPart) -> [GraphError] {
		TimeRecorder.start(event: .validate)
		defer { TimeRecorder.end(event: .validate) }
		var errors: [GraphError] = []
		
		for (_, registrations) in containerPart.tokenInfo {
			for registration in registrations {
				errors += validate(registration: registration, containerPart: containerPart)
				if let severalRegistrationErr = validateSeveralRegistrationsForType(registrations: registrations, validatingRegistration: registration) {
					errors.append(severalRegistrationErr)
				}
			}
		}
		
		return compose(errorList: errors)
	}
	
	
	private func validateSeveralRegistrationsForType(registrations: [RegistrationToken], validatingRegistration: RegistrationToken) -> GraphError? {
		guard registrations.count > 1 else {
			return nil
		}
		let defaultCount = registrations.filter({ registration in
			registration.tokenList.contains(where: { $0.underlyingValue is IsDefaultToken })
		}).count
		
		if defaultCount == 0 {
			// Its ok to have just many registrations for one type. Error can be thrown in not many injection
			// TODO: Check real type in many registrations. We should not allow use two exact same registration which is same class, not same protocol?
			return nil
		} else if defaultCount > 1 {
			let info = buildHaseMoreThanOneDefaultRegistratioinsForType(registrationName: validatingRegistration.typeName)
			return GraphError(infoString: info, location: validatingRegistration.location, kind: .validation)
		} else {
			return nil
		}
	}
	
	
	private func validate(registration: RegistrationToken, containerPart: ContainerPart) -> [GraphError] {
		var errors: [GraphError] = []
		for token in registration.tokenList {
			switch token.underlyingValue {
			case let alias as AliasToken:
				errors += self.findErrors(inAlias: alias, registration: registration)
				
			case let injection as InjectionToken:
				errors += self.findErrors(inInjection: injection, containerPart: containerPart)
				
			default:
				break
			}
		}
		
		return errors
	}
	
	
	private func findErrors(inAlias token: AliasToken, registration: RegistrationToken) -> [GraphError] {
		let errors: [GraphError] = []
		guard token.typeName != registration.typeName && !autoimplementedTypes.contains(token.typeName) else {
			return errors
		}
//		let inheritanceAndImplementations = typeInfo.inheritanceAndImplementations
//		for aliasType in token.decomposedTypes {
//			let aliasTypeName = nsObjectProtocolConvert(aliasType)
//			guard inheritanceAndImplementations[aliasTypeName] == nil && !typeInfo.inheritedTypes.contains(aliasTypeName) else { continue }
//			let info = buildNotFoundAliasMessage(alias: token)
//			errors.append(GraphError(infoString: info, location: token.location, kind: .validation))
//		}
		return errors
	}
	
	
	private func findErrors(inInjection token: InjectionToken, containerPart: ContainerPart) -> [GraphError] {
		var errors: [GraphError] = []
		let accessor = token.getRegistrationAccessor()
		if let registrations = containerPart.tokenInfo[accessor] {
			let defaultCount = registrations.filter({ registration in
				registration.tokenList.contains(where: { $0.underlyingValue is IsDefaultToken })
			}).count
			if registrations.count > 1 && !token.isMany && defaultCount != 1 {
				// More than one registration for requested type+tag
				let info = buildTooManyRegistrationsForType(injection: token, accessor: accessor)
				errors.append(GraphError(infoString: info, location: token.location, kind: .validation))
			}
		} else if !token.optionalInjection {
			// Not found at lease one registration for requested type+tag
			let info = buildNotFoundRegistrationMessage(injection: token, accessor: accessor)
			errors.append(GraphError(infoString: info, location: token.location, kind: .validation))
		}
		return errors
	}
	
	
	private func nsObjectProtocolConvert(_ name: String) -> String {
		return name == "NSObjectProtocol" ? "NSObject" : name
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
	
	
	private func buildHaseMoreThanOneDefaultRegistratioinsForType(registrationName: String) -> String {
		return "Too many default registrations for \"\(registrationName)\" type. Make exact one of registration as default or delete redundant registration."
	}
	
	
	private func buildNotFoundAliasMessage(alias: AliasToken) -> String {
		if alias.plainTypeName != alias.typeName {
			return "Does not inherits from \"\(alias.plainTypeName)\" or not conforms to \"\(alias.typeName)\"."
		} else {
			return "Does not inherits nor conforms to \"\(alias.typeName)\"."
		}
	}
	
	
	private func buildNotFoundRegistrationMessage(injection: InjectionToken, accessor: RegistrationAccessor) -> String {
		let injectionType = injection.methodInjection ? "method" : "variable"
		var info = "Not found registration with \"\(accessor.typeName)\" type"
		if !accessor.tag.isEmpty {
			info += ", tag: \"\(accessor.tag)\""
		}
		info += " for \"\(injection.name)\" \"\(injectionType)\" injection."
		return info
	}
	
	
	private func buildTooManyRegistrationsForType(injection: InjectionToken, accessor: RegistrationAccessor) -> String {
		let injectionType = injection.methodInjection ? "method" : "variable"
		var info = "Too many registration with \"\(accessor.typeName)\" type"
		if !accessor.tag.isEmpty {
			info += ", tag: \"\(accessor.tag)\""
		}
		info += " for \"\(injection.name)\" \"\(injectionType)\" injection."
		return info
	}
}
