//
//  AliasToken.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 22/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation


/// Contains information about aliasing c.register(...).as(MyProtocol.self)
struct AliasToken: Codable {
	
	var isIntermediate: Bool {
		return true
	}
	
	/// Unique type name of injection. With resolved generic constraints and typealiases
	let typeName: String
	
	/// Type name for accessing [String: Type] dicationary for getting all collected info of type
	let plainTypeName: String
	
	/// Unique tag of aliasing. With resolved generic constraints and typealiases
	let tag: String
	
	/// Location of registration token (For printing message in XCode)
	let location: Location
	
	/// (Type1 & Type2) -> [Type1, Type2]
	var decomposedTypes: [String] {
		return AliasToken.decompose(name: plainTypeName)
	}
	
	static func decompose(name: String) -> [String] {
		if name.contains("&") {
			return name
				.split(separator: "&")
				.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
		} else {
			return [name]
		}
	}
	
	init(typeName: String, tag: String, location: Location) {
		self.typeName = typeName
		self.tag = tag
		self.location = location
		self.plainTypeName = TypeFinder.parseTypeName(name: typeName).plainTypeName
	}
	
	func getRegistrationAccessor() -> RegistrationAccessor {
		return RegistrationAccessor(typeName: typeName, tag: tag)
	}
	
}

/// Combination of typeName and tag for unique registration identifying
struct RegistrationAccessor: Hashable, Codable {
	let typeName: String
	let tag: String
	
	init(typeName: String, tag: String) {
		self.typeName = AliasToken.decompose(name: typeName).sorted().joined(separator: " & ")
		self.tag = tag
	}
}
