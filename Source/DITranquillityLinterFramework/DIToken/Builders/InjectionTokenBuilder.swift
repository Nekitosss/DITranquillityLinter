//
//  InjectionTokenBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 30/09/2018.
//

import Foundation
import SourceKittenFramework
import xcodeproj

/// Trying to create InjectionToken (without injection type resolving)
final class InjectionTokenBuilder: TokenBuilder {
	
	func build(using info: TokenBuilderInfo) -> DIToken? {
		guard info.functionName == DIKeywords.injection.rawValue else { return nil }
		var cycle = false
		var name = ""
		var modificators: [InjectionModificator] = []
		
		for argument in info.argumentStack {
			self.extractCycleInfo(from: argument, into: &cycle)
			self.extractNameInfo(from: argument, into: &name)
			self.extractModificators(from: argument, info: info, into: &modificators)
		}
		// Type name will be resolved later
		return InjectionToken(name: name,
							  typeName: "",
							  plainTypeName: "",
							  cycle: cycle,
							  optionalInjection: false,
							  methodInjection: false,
							  modificators: modificators,
							  injectionSubstructureList: info.substructureList.last?.substructures ?? info.substructureList,
							  location: info.location)
	}
	
	private func extractCycleInfo(from argument: ArgumentInfo, into cycle: inout Bool) {
		if argument.name == DIKeywords.cycle.rawValue {
			// injection(cycle: true, ...)
			cycle = argument.value == "\(true)"
		}
	}
	
	
	private func extractNameInfo(from argument: ArgumentInfo, into name: inout String) {
		let isEmptyArgumentName = argument.name.isEmpty || argument.name == "_"
		if isEmptyArgumentName && argument.value.starts(with: RegExp.implicitKeyPath.rawValue) {
			// injection(\.myPath)
			name = String(argument.value.dropFirst(2))
			
		} else if let dotIndex = argument.value.index(of: "."), isEmptyArgumentName && argument.value.firstMatch(RegExp.explicitKeyPath.rawValue) != nil {
			// injection(\RegistrationType.myPath)
			name = String(argument.value[argument.value.index(after: dotIndex)...])
			
		} else if let nameFromPattern = argument.value.firstMatch(RegExp.nameFromParameterInjection) {
			// injection { $0.name = $1 }
			name = String(nameFromPattern.dropFirst(3))
		}
	}
	
	
	private func extractModificators(from argument: ArgumentInfo, info: TokenBuilderInfo, into modificators: inout [InjectionModificator]) {
		if let taggedModificators = InjectionTokenBuilder.parseTaggedAndManyInjection(structure: argument.structure, content: info.content) {
			// For tagged variable injection structure always on "closure" level
			modificators += taggedModificators
			
		} else if let closureSubstructure = argument.structure.substructures.first,
			let taggedModificators = InjectionTokenBuilder.parseTaggedAndManyInjection(structure: closureSubstructure, content: info.content) {
			// Tag stores in argument -> closure -> expressionCall
			// parseTaggedInjection can parse sinse "closure" level. So we unwrap single time
			modificators += taggedModificators
		}
		
		if var typeFromPattern = argument.value.firstMatch(.forcedType) {
			// $0 "as String }"
			typeFromPattern = typeFromPattern.filter({ $0 != "}" }).trimmingCharacters(in: .whitespacesAndNewlines)
			modificators.append(.typed(typeFromPattern))
		}
	}
	
	
	static func parseTaggedAndManyInjection(structure: SourceKitStructure, content: NSString) -> [InjectionModificator]? {
		var result: [InjectionModificator] = []
		for substructure in structure.substructures {
			guard let name: String = substructure.get(.name),
				let kind: String = substructure.get(.kind),
				kind == SwiftExpressionKind.call.rawValue
				else { continue }
			
			if name == DIKeywords.by.rawValue {
				let arguments = ContainerPartBuilder.argumentInfo(substructures: substructure.substructures, content: content)
				guard let tagType = arguments.first(where: { $0.name == DIKeywords.tag.rawValue }) else { continue }
				let tagTypeName = tagType.value.droppedDotSelf()
				result.append(.tagged(tagTypeName))
			} else if name == DIKeywords.many.rawValue {
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
