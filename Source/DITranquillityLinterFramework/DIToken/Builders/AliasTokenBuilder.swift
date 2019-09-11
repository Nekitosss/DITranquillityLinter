//
//  AliasTokenBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 28/09/2018.
//

import Foundation
import ASTVisitor

/// Trying to create AliasToken
final class AliasTokenBuilder: TokenBuilder {
	
	func build(using info: TokenBuilderInfo) -> DITokenConvertible? {
		guard info.functionName == DIKeywords.as.rawValue || info.functionName == DIKeywords.taggedAlias.rawValue,
			let declrefExpr = info.node[.dotSyntaxCallExpr][.declrefExpr].getOne()?.typedNode.unwrap(DeclrefExpression.self),
			let location = declrefExpr.location,
			!declrefExpr.substitution.isEmpty
			else { return nil }
		var typeName = ""
		var tag = ""
		
		for substitution in declrefExpr.substitution {
            switch substitution.key {
            case "Parent":
                typeName = substitution.value
            case "Tag":
                tag = substitution.value
            default:
                continue
            }
		}
		
		return AliasToken(typeName: typeName, tag: tag, location: .init(visitorLocation: location))
		
//
//		for argument in info.argumentStack {
//			switch argument.name {
//			case "" where argument.value.hasSuffix(".self"),
//				 "_" where argument.value.hasSuffix(".self"),
//				 DIKeywords.check.rawValue:
//				typeName = argument.value.droppedDotSelf().bracketsBalancing()
//				if let type = info.parsingContext.collectedInfo[typeName] {
//					typeName = type.name
//				}
//			case DIKeywords.tag.rawValue:
//				tag = argument.value.droppedDotSelf().bracketsBalancing()
//			default:
//				break
//			}
//		}
//		return AliasToken(typeName: typeName, tag: tag, location: info.location)
	}
	
}
