//
//  InjectionToken.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 23/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation

/// Injection information for registration
struct InjectionToken: DIToken {
	
	var isIntermediate: Bool {
		return true
	}
	
	/// Injection name. Injecting type variable name or method parameter name
	let name: String
	
	/// Unique type name of injection. With resolved generic constraints and typealiases
	var typeName: String
	
	/// Type name for accessing [String: Type] dicationary for getting all collected info of type
	var plainTypeName: String
	
	/// Is Cycled registration
	let cycle: Bool
	
	/// Is injection optional
	var optionalInjection: Bool
	
	/// Is injection via method
	let methodInjection: Bool
	
	/// "as MyType", "by(tag:on)", "many()"
	let modificators: [InjectionModificator]
	
	/// Source substructure info. For type resolving
	let injectionSubstructureList: [SourceKitStructure]
	
	/// Location of registration token (For printing message in XCode)
	let location: Location
	
	
	/// Creates consistent registration accessor for type accessing.
	func getRegistrationAccessor() -> RegistrationAccessor {
		// Select typeName if its generic. Plain typeName otherwise. TODO: Refactor and make typeName actual
		let preferredType = typeName.contains("<") ? typeName : plainTypeName
		return RegistrationAccessor(typeName: preferredType, tag: tag)
	}
	
	/// Is many injection
	var isMany: Bool {
		return InjectionModificator.isMany(modificators)
	}
	
	/// injection tag
	var tag: String {
		for modificator in modificators {
			switch modificator {
			case .tagged(let tag):
				return tag
			default:
				break
			}
		}
		return ""
	}
}
