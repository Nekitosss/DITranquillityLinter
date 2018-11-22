//
//  AliasTokenBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 28/09/2018.
//

import Foundation
import SourceKittenFramework

/// Trying to create AliasToken
final class AliasTokenBuilder: TokenBuilder {
	
	private let parsingContext: ParsingContext
	
	init(parsingContext: ParsingContext) {
		self.parsingContext = parsingContext
	}
	
	func build(using info: TokenBuilderInfo) -> DIToken? {
		guard info.functionName == DIKeywords.as.rawValue else { return nil }
		var typeName = ""
		var tag = ""
		
		for argument in info.argumentStack {
			switch argument.name {
			case "" where argument.value.hasSuffix(".self"),
				 "_" where argument.value.hasSuffix(".self"),
				 DIKeywords.check.rawValue:
				typeName = argument.value.droppedDotSelf().bracketsBalancing()
				if let type = parsingContext.collectedInfo[typeName] {
					typeName = type.name
				}
			case DIKeywords.tag.rawValue:
				tag = argument.value.droppedDotSelf().bracketsBalancing()
			default:
				break
			}
		}
		return AliasToken(typeName: typeName, tag: tag, location: info.location)
	}
	
}
