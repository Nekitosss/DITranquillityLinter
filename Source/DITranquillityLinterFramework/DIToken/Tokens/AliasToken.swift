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
	
	init(typeName: String, tag: String, location: Location) {
		self.typeName = typeName
		self.tag = tag
		self.location = location
		self.plainTypeName = RegistrationTokenBuilder.extractPlainTypeName(typeName: typeName)
	}
	
	func getRegistrationAccessor() -> RegistrationAccessor {
		return RegistrationAccessor(typeName: typeName, tag: tag)
	}
	
}

struct RegistrationAccessor: Hashable {
	let typeName: String
	let tag: String
	
	init(typeName: String, tag: String) {
		var justifiedTypeName: String
		if typeName.contains("&") {
			justifiedTypeName = typeName
				.split(separator: "&")
				.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
				.sorted()
				.joined(separator: " & ")
		} else {
			justifiedTypeName = typeName
		}
		
		self.typeName = justifiedTypeName
		self.tag = tag
	}
}
