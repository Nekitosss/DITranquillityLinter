//
//  InjectionTokenBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 30/09/2018.
//

import Foundation
import ASTVisitor

/// Trying to create InjectionToken (without injection type resolving)
final class InjectionTokenBuilder: TokenBuilder {
	
	func build(using info: TokenBuilderInfo) -> DITokenConvertible? {
        if info.functionName == DIKeywords.injection.rawValue {
            guard
                let declrefExpr = info.node[.dotSyntaxCallExpr][.declrefExpr].getSeveral()?.first?.typedNode.unwrap(DeclrefExpression.self),
                let astLocation = declrefExpr.location
                else { return nil }
            
            let location = Location(visitorLocation: astLocation)
            var name = ""
            var typeName = ""
            
            for substitution in declrefExpr.substitution {
                if substitution.key == "Property" {
                    typeName = substitution.value
                }
            }
            let unwrappedName = TypeName.unwrapTypeName(name: typeName)
            
            var cycle = false
            if let cycleCall = info.node[.tupleShuffleExpr][.tupleExpr][.callExpr][.tupleExpr][.booleanLiteralExpr].getOne(),
                let value = cycleCall[tokenKey: .value].getOne()?.value {
                cycle = value == "true"
            }
            
            return InjectionToken(name: "",
                                  typeName: TypeName.onlyDroppedOptional(name: typeName),
                                  plainTypeName: unwrappedName.unwrappedTypeName,
                                  cycle: cycle,
                                  optionalInjection: unwrappedName.isOptional,
                                  methodInjection: false,
                                  modificators: [],
                                  location: location)
            
        } else if info.functionName == DIKeywords.modifiedInjection.rawValue {
            guard
                let declrefExpr = info.node[.dotSyntaxCallExpr][.declrefExpr].getSeveral()?.first?.typedNode.unwrap(DeclrefExpression.self),
                let astLocation = declrefExpr.location
                else { return nil }
            
            let location = Location(visitorLocation: astLocation)
            var name = ""
            var modificators: [InjectionModificator] = []
            var typeName = ""
            
            for substitution in declrefExpr.substitution {
                if substitution.key == "P" {
                    typeName = substitution.value
                }
            }
            let unwrappedName = TypeName.unwrapTypeName(name: typeName)
            
            var cycle = false
            if let cycleCall = info.node[.tupleShuffleExpr][.tupleExpr][.callExpr][.tupleExpr][.booleanLiteralExpr].getOne(),
                let value = cycleCall[tokenKey: .value].getOne()?.value {
                cycle = value == "true"
            }
            
            if let tag = info.node[.tupleShuffleExpr][.tupleExpr][.closureExpr][.callExpr][.declrefExpr].getOne()?.typedNode.unwrap(DeclrefExpression.self) {
                
                for substitution in tag.substitution {
                    if substitution.key == "Tag" {
                        modificators.append(.tagged(substitution.value))
                    }
                }
            }
            
            if info.node[.tupleShuffleExpr][.tupleExpr][.functionConversionExpr][.closureExpr][.callExpr][.declrefExpr].getOne()?[tokenKey: .decl].getOne()?.value == DIKeywords.many.rawValue {
                modificators.append(.many)
            }
            
            return InjectionToken(name: "",
                                  typeName: TypeName.onlyDroppedOptional(name: typeName),
                                  plainTypeName: unwrappedName.unwrappedTypeName,
                                  cycle: cycle,
                                  optionalInjection: unwrappedName.isOptional,
                                  methodInjection: false,
                                  modificators: modificators,
                                  location: location)
        }
        
        return nil

//
//		for argument in info.argumentStack {
//			cycle = self.extractCycleInfo(from: argument) ?? cycle
//			name = self.extractNameInfo(from: argument) ?? name
//			modificators += self.extractModificators(from: argument, info: info)
//		}
//		// Type name will be resolved later
//		return InjectionToken(name: name,
//							  typeName: "",
//							  plainTypeName: "",
//							  cycle: cycle,
//							  optionalInjection: false,
//							  methodInjection: false,
//							  modificators: modificators,
//							  injectionSubstructureList: info.substructureList.last?.substructures ?? info.substructureList,
//							  location: info.location)
	}
	
//	private func extractCycleInfo(from argument: ArgumentInfo) -> Bool? {
//		if argument.name == DIKeywords.cycle.rawValue {
//			// injection(cycle: true, ...)
//			return argument.value == "\(true)"
//		}
//		return nil
//	}
//
//
//	private func extractNameInfo(from argument: ArgumentInfo) -> String? {
//		var name: String?
//		let isEmptyArgumentName = argument.name.isEmpty || argument.name == "_"
//		if isEmptyArgumentName && argument.value.starts(with: RegExp.implicitKeyPath.rawValue) {
//			// injection(\.myPath)
//			name = String(argument.value.dropFirst(2))
//
//		} else if let dotIndex = argument.value.firstIndex(of: "."), isEmptyArgumentName && argument.value.firstMatch(RegExp.explicitKeyPath.rawValue) != nil {
//			// injection(\RegistrationType.myPath)
//			name = String(argument.value[argument.value.index(after: dotIndex)...])
//
//		} else if let nameFromPattern = argument.value.firstMatch(RegExp.nameFromParameterInjection) {
//			// injection { $0.name = $1 }
//			name = String(nameFromPattern.dropFirst(3))
//		}
//		return name
//	}
//
//
//	private func extractModificators(from argument: ArgumentInfo, info: TokenBuilderInfo) -> [InjectionModificator] {
//		var modificators: [InjectionModificator] = []
//		if let taggedModificators = InjectionTokenBuilder.parseTaggedAndManyInjection(structure: argument.structure, content: info.content) {
//			// For tagged variable injection structure always on "closure" level
//			modificators += taggedModificators
//
//		}
//		if let closureSubstructure = argument.structure.substructures.first,
//			let taggedModificators = InjectionTokenBuilder.parseTaggedAndManyInjection(structure: closureSubstructure, content: info.content) {
//			// Tag stores in argument -> closure -> expressionCall
//			// parseTaggedInjection can parse sinse "closure" level. So we unwrap single time
//			modificators += taggedModificators
//		}
//
//		if var typeFromPattern = argument.value.firstMatch(.forcedType) {
//			// $0 "as String }"
//			typeFromPattern = typeFromPattern.filter({ $0 != "}" }).trimmingCharacters(in: .whitespacesAndNewlines)
//			modificators.append(.typed(typeFromPattern))
//		}
//		return modificators
//	}
	
	
	static func parseTaggedAndManyInjection(structure: SourceKitStructure, content: NSString) -> [InjectionModificator]? {
		let result = structure.substructures.reduce(into: [InjectionModificator]()) { result, substructure in
			guard substructure.isKind(of: SwiftExpressionKind.call) else {
				return
			}
			
			if substructure.nameIs(DIKeywords.by) {
				let arguments = ContainerPartBuilder.argumentInfo(substructures: substructure.substructures, content: content)
				guard let tagType = arguments.first(where: { $0.name == DIKeywords.tag.rawValue }) else {
					return
				}
				let tagTypeName = tagType.value.droppedDotSelf()
				result.append(.tagged(tagTypeName))
			} else if substructure.nameIs(DIKeywords.many) {
				result.append(.many)
			}
		}
		if result.isEmpty {
			return nil
		} else {
			return result
		}
	}
	
}
