//
//  InjectionTokenBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 30/09/2018.
//

import Foundation
import SourceKittenFramework
import xcodeproj

final class InjectionTokenBuilder {
	
	static func build(functionName: String, invocationBody: String, argumentStack: [ArgumentInfo], bodyOffset: Int64, file: File, content: NSString, substructureList: [SourceKitStructure]) -> InjectionToken? {
		guard functionName == DIKeywords.injection.rawValue else { return nil }
		
		var argumentStack = argumentStack
		if argumentStack.isEmpty {
			argumentStack = AliasTokenBuilder.parseArgumentList(body: invocationBody, substructureList: substructureList)
		}
		var cycle = false
		var name = ""
		var typeName = ""
		var modificators: [InjectionModificator] = []
		let location = Location(file: file, byteOffset: bodyOffset)
		
		
		for argument in argumentStack {
			let isEmptyArgumentName = argument.name.isEmpty || argument.name == "_"
			if argument.name == DIKeywords.cycle.rawValue {
				// injection(cycle: true, ...)
				cycle = argument.value == "\(true)"
			} else if isEmptyArgumentName && argument.value.starts(with: RegExp.implicitKeyPath.rawValue) {
				// injection(\.myPath)
				name = String(argument.value.dropFirst(2))
			} else if let dotIndex = argument.value.index(of: "."), isEmptyArgumentName && argument.value.firstMatch(RegExp.explicitKeyPath.rawValue) != nil  {
				// injection(\RegistrationType.myPath)
				name = String(argument.value[argument.value.index(after: dotIndex)...])
			} else if let nameFromPattern = argument.value.firstMatch(RegExp.nameFromParameterInjection) {
				// injection { $0.name = $1 }
				name = String(nameFromPattern.dropFirst(3))
			}
			if let taggedModificators = InjectionTokenBuilder.parseTaggedInjection(structure: argument.structure, content: content), !taggedModificators.isEmpty {
				// For tagged variable injection structure always on "closure" level
				modificators += taggedModificators
				
			} else if let closureSubstructure = argument.structure.substructures?.first,
				let taggedModificators = InjectionTokenBuilder.parseTaggedInjection(structure: closureSubstructure, content: content), !taggedModificators.isEmpty {
				// Tag stores in argument -> closure -> expressionCall
				// parseTaggedInjection can parse sinse "closure" level. So we unwrap single time
				modificators += taggedModificators
			}
			if var typeFromPattern = argument.value.firstMatch(.forcedType) {
				// $0 "as String }"
				typeFromPattern = typeFromPattern.filter({ $0 != "}" }).trimmingCharacters(in: .whitespacesAndNewlines)
				typeName = typeFromPattern
				modificators.append(.typed(typeFromPattern))
			}
		}
		
		return InjectionToken(name: name, typeName: typeName, plainTypeName: typeName, cycle: cycle, optionalInjection: false, methodInjection: false, modificators: modificators, injectionSubstructureList: substructureList.last?.substructures ?? substructureList, location: location)
	}
	
	static func parseTaggedInjection(structure: SourceKitStructure, content: NSString) -> [InjectionModificator]? {
		let expresstionCallSubstructures = structure.substructures ?? []
		var result: [InjectionModificator] = []
		for substructure in expresstionCallSubstructures {
			guard let name: String = substructure.get(.name),
				let kind: String = substructure.get(.kind),
				kind == SwiftExpressionKind.call.rawValue,
				let argumentsSubstructure = substructure.substructures,
				name == DIKeywords.by.rawValue
				else { continue }
			let arguments = ContainerPart.argumentInfo(substructures: argumentsSubstructure, content: content)
			guard let tagType = arguments.first(where: { $0.name == DIKeywords.tag.rawValue }) else { continue }
			let tagTypeName = tagType.value.droppedDotSelf()
			result.append(.tagged(tagTypeName))
		}
		return result
	}
	
}
