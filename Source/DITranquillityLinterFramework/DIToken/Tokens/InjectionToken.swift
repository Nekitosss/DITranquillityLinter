//
//  InjectionToken.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 23/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation

struct InjectionToken: DIToken {
	
	let name: String
	var typeName: String
	let cycle: Bool
	var optionalInjection: Bool
	let methodInjection: Bool
	let modificators: [InjectionModificator]
	let injectionSubstructureList: [SourceKitStructure]
	let location: Location
}
