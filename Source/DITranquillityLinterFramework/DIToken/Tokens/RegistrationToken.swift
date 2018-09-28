//
//  RegistrationToken.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 22/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation

struct RegistrationToken: DIToken {
	
	let typeName: String
	// For generics
	let plainTypeName: String
	let tokenList: [DIToken]
}
