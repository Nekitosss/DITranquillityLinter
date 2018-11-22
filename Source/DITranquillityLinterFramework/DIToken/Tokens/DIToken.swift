//
//  DIToken.swift
//  DITranquillityLinter
//
//  Created by Nikita on 08/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation

protocol DIToken {
	
	/// For example, AliasToken could be only part of RegistrationToken.
	/// Currently, RegistrationToken and AppendContainerToken are independent, all others are intermediate.
	/// Intermediate tokens could not exists without independent tokens.
	/// AliasToken could not exests without referenced RegistrationToken
	var isIntermediate: Bool { get }
}
