//
//  AliasToken.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 22/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation

struct AliasToken: DIToken, Hashable {
	
	let typeName: String
	let tag: String
	let location: Location
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(typeName)
		hasher.combine(tag)
	}
	
	static func ==(lhs: AliasToken, rhs: AliasToken) -> Bool {
		return lhs.typeName == rhs.typeName && lhs.tag == rhs.tag
	}
}
