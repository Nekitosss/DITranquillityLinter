//
//  ContainerPart.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 12.09.2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework
import ASTVisitor

// DIPart, DIFramework
/// Trying to collect info from container part and pack it into RegistrationTokens
struct ContainerPart: Codable {
	
	let name: String?
	let tokenInfo: [RegistrationAccessor: [RegistrationToken]]
	
	init(substructureList: [ASTNode], parsingContext: GlobalParsingContext, containerParsingContext: ContainerParsingContext, currentPartName: String?, diPartNameStack: [String]) {
		var diPartNameStack = diPartNameStack
		if let name = currentPartName {
			diPartNameStack.append(name)
		}
		let builer = ContainerPartBuilder(parsingContext: parsingContext, containerParsingContext: containerParsingContext, currentPartName: currentPartName, diPartNameStack: diPartNameStack)
		self.name = currentPartName
		self.tokenInfo = builer.build(substructureList: substructureList)
	}
	
}
