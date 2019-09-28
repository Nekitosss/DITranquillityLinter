//
//  InjectionTokenBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 30/09/2018.
//

import Foundation
import ASTVisitor
import SourceKittenFramework

/// Trying to create InjectionToken (without injection type resolving)
final class InjectionTokenBuilder: TokenBuilder {
	
	func build(using info: TokenBuilderInfo) -> DITokenConvertible? {

		guard
			let declrefExpr = info.node[.dotSyntaxCallExpr][.declrefExpr].getSeveral()?.first?.typedNode.unwrap(DeclrefExpression.self),
			let astLocation = declrefExpr.location,
			info.functionName == DIKeywords.injection.rawValue || info.functionName == DIKeywords.modifiedInjection.rawValue
			else { return nil }
		let location = Location(visitorLocation: astLocation)
		
		var (typeName, plainTypeName, isOptional, modificators) = InjectionTokenBuilder.unwrapSubstitution(declrefSubstitution: declrefExpr.substitution)
		  
        if info.functionName == DIKeywords.modifiedInjection.rawValue {
            if info.node[.tupleShuffleExpr][.tupleExpr][.functionConversionExpr][.closureExpr][.callExpr][.declrefExpr].getOne()?[tokenKey: .decl].getOne()?.value == DIKeywords.many.rawValue {
                modificators.append(.many)
            }
		}
		
		var cycle = false
		if let possibleCycleValue = info.node[.tupleShuffleExpr][.tupleExpr][.booleanLiteralExpr].getOne()?[tokenKey: .value].getOne()?.value {
			cycle = possibleCycleValue == "true"
		}
		
		return InjectionToken(name: "",
							  typeName: typeName,
							  plainTypeName: plainTypeName,
							  cycle: cycle,
							  optionalInjection: isOptional,
							  methodInjection: false,
							  modificators: modificators,
							  location: location)
	}

	static func unwrapSubstitution(declrefSubstitution: [String : String]) -> (typeName: String, plainTypeName: String, isOptional: Bool, modificators: [InjectionModificator]) {
		
		var modificators: [InjectionModificator] = []
		var astTypeName = ""
		var typeName = ""
		
		for substitution in declrefSubstitution {
			let regexp = try! NSRegularExpression(pattern: "P[0-99]?", options: [])
			let matches = regexp.matches(in: substitution.key, options: [], range: .init(location: 0, length: substitution.key.bridge().length))
			
			if !matches.isEmpty && astTypeName.isEmpty {
				astTypeName = substitution.value
			}
			if substitution.key == "Property" {
				astTypeName = substitution.value
			}
		}
		
		let unwrappedName = TypeName.unwrapTypeName(name: astTypeName)
		var plainTypeName = unwrappedName.unwrappedTypeName
		typeName = TypeName.onlyDroppedOptional(name: astTypeName)
		if let (plainType, modificator) = unwrapByTag(typeName: astTypeName) {
			plainTypeName = plainType
			typeName = plainType
			modificators.append(modificator)
		}
		
		if let (plainType, modificator) = unwrapByMany(typeName: astTypeName) {
			plainTypeName = plainType
			typeName = plainType
			modificators.append(modificator)
		}
		
		return (typeName, plainTypeName, unwrappedName.isOptional, modificators)
	}
	
	private static func unwrapByTag(typeName: String) -> (String, InjectionModificator)? {
		guard let generic = Composer.parseGenericType(typeName),
			generic.name == DIKeywords.diByTag.rawValue,
			generic.typeParameters.count == 2 // Tag + TypeName
			else { return nil }
		
		let tag = generic.typeParameters[0].typeName.unwrappedTypeName
		let type = generic.typeParameters[1].typeName.unwrappedTypeName
		return (type, .tagged(tag))
	}
	
	private static func unwrapByMany(typeName: String) -> (String, InjectionModificator)? {
		guard let generic = Composer.parseGenericType(typeName),
			generic.name == DIKeywords.diMany.rawValue,
			generic.typeParameters.count == 1 // TypeName
			else { return nil }
		
		let type = generic.typeParameters[0].typeName.unwrappedTypeName
		return (type, .many)
	}
	
}
