//
//  RegistrationToken.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 22/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation

/// Total collected info about registration
struct RegistrationToken: DIToken {
	
	/// Unique type name of registration. With resolved generic constraints and typealiases
	let typeName: String
	
	/// Type name for accessing [String: Type] dicationary for getting all collected info of type
	let plainTypeName: String
	
	/// Location of registration token (For printing message in XCode)
	let location: Location
	
	/// Collected tokens of registration. Injection info, isDefault component info
	let tokenList: [DIToken]
}
