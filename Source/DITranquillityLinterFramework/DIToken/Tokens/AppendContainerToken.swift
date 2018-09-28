//
//  AppendContainerToken.swift
//  DITranquillityLinter
//
//  Created by Nikita on 12/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation

struct AppendContainerToken: DIToken {
	let location: Location
	let typeName: String
	let containerPart: ContainerPart
}
