//
//  ContainerPart.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 12.09.2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework
import xcodeproj


// DIPart, DIFramework
/// Trying to collect info from container part and pack it into RegistrationTokens
struct ContainerPart {
	
	let tokenInfo: [RegistrationAccessor: [RegistrationToken]]
	
	init(substructureList: [SourceKitStructure], file: File, parsingContext: ParsingContext, currentPartName: String?) {
		let builer = ContainerPartBuilder(file: file, parsingContext: parsingContext, currentPartName: currentPartName)
		let ti = builer.build(substructureList: substructureList)
		self.tokenInfo = ti
	}
	
}
