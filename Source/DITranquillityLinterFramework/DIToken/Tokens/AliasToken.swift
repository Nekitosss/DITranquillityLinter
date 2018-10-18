//
//  AliasToken.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 22/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation

struct AliasToken: DIToken {
	
	let typeName: String
	let plainTypeName: String
	let tag: String
	let location: Location
	
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
		self.plainTypeName = TypeFinder.parseTypeName(name: typeName).typeName
	}
	
	func getRegistrationAccessor() -> RegistrationAccessor {
		return RegistrationAccessor(typeName: typeName, tag: tag)
	}
	
}

struct RegistrationAccessor: Hashable {
	let typeName: String
	let tag: String
	
	init(typeName: String, tag: String) {
		self.typeName = AliasToken.decompose(name: typeName).sorted().joined(separator: " & ")
		self.tag = tag
	}
}
