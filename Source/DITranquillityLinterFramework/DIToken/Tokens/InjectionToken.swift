//
//  InjectionToken.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 23/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation

/// Injection information for registration
struct InjectionToken: Codable {
	
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

extension InjectionToken {
	
	private enum CodingKeys: String, CodingKey {
		case name
		case typeName
		case plainTypeName
		case cycle
		case optionalInjection
		case methodInjection
		case modificators
		case location
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(name, forKey: .name)
		try container.encode(typeName, forKey: .typeName)
		try container.encode(plainTypeName, forKey: .plainTypeName)
		try container.encode(cycle, forKey: .cycle)
		try container.encode(optionalInjection, forKey: .optionalInjection)
		try container.encode(methodInjection, forKey: .methodInjection)
		try container.encode(modificators, forKey: .modificators)
		try container.encode(location, forKey: .location)
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		name = try container.decode(String.self, forKey: .name)
		typeName = try container.decode(String.self, forKey: .typeName)
		plainTypeName = try container.decode(String.self, forKey: .plainTypeName)
		cycle = try container.decode(Bool.self, forKey: .cycle)
		optionalInjection = try container.decode(Bool.self, forKey: .optionalInjection)
		methodInjection = try container.decode(Bool.self, forKey: .methodInjection)
		modificators = try container.decode([InjectionModificator].self, forKey: .modificators)
		location = try container.decode(Location.self, forKey: .location)
		
		// We need injection substructore only for processing and should not store in after full process
		injectionSubstructureList = []
	}
}
