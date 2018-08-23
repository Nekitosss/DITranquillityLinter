//
//  InjectionToken.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 23/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation

class InjectionToken {
	
	var name: String = ""
	var typeName: String = ""
	
	init(name: String, typeName: String) {
		self.name = typeName
		self.typeName = typeName
	}
	
	init?(functionName: String, invocationBody: String) {
		guard functionName == "injection" else { return nil }
		return nil
//		let variables = invocationBody.split(separator: ",")
//		let argumentInfo = variables.map(String.init).map(AliasToken.parseArgument)
//
//		for (index, argument) in argumentInfo.enumerated() {
//			if index == 0 {
//				self.typeName = argument.value
//			} else if index == 1 {
//				self.tag = argument.value
//			}
//		}
	}
}
