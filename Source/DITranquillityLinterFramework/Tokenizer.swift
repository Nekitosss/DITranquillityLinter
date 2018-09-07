//
//  Printer.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 19/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework

public class Tokenizer {
	
	typealias SourceKitTuple = (structure: Structure, file: File)
	
	public init() {}
	
	public func process(files: [URL]) {
		let skFile = files.compactMap({ File(path: $0.path) })
		print(skFile.count)
		
		let structures = skFile.compactMap(getStructure)
		var result: [SwiftType] = []
		structures.forEach({ getDIParts(values: $0, result: &result) })
		let dictionary = result.reduce(into: [String: SwiftType]()) { $0[$1.name] = $1 }
		print(dictionary.keys.count)
		let diParts = dictionary.values.filter({ $0.inheritedTypes.contains("DIPart") })
		
		
		let mainPart = diParts.first(where: { $0.name == "MainDIPart" })!
		let loadContainerStructure = mainPart.substructure.first(where: { $0[SwiftDocKey.name.rawValue] as! String == "load(container:)" })!
		processLoadContainerFunction(loadContainerStructure: loadContainerStructure, file: mainPart.file)
		print("End")
	}
	
	private func processLoadContainerFunction(loadContainerStructure: [String : SourceKitRepresentable], file: File) {
		let content = file.contents.bridge()
		let substructureList = loadContainerStructure[SwiftDocKey.substructure.rawValue] as? [[String: SourceKitRepresentable]] ?? []
		for substructure in substructureList {
			processLoadContainerBodyPart(loadContainerBodyPart: substructure, content: content)
		}
	}
	
	private func processLoadContainerBodyPart(loadContainerBodyPart: [String : SourceKitRepresentable], content: NSString) {
		guard let kind = loadContainerBodyPart[SwiftDocKey.kind.rawValue] as? String else { return }
		
		switch kind {
		case SwiftExpressionKind.call.rawValue:
			guard let name = loadContainerBodyPart[SwiftDocKey.name.rawValue] as? String,
				let bodyOffset = loadContainerBodyPart[SwiftDocKey.bodyOffset.rawValue] as? Int64,
				let bodyLength = loadContainerBodyPart[SwiftDocKey.bodyLength.rawValue] as? Int64
				else { return }
			let body = content.substringWithByteRange(start: Int(bodyOffset), length: Int(bodyLength))!
			let actualName = extractActualFuncionInvokation(name: name)
			
			let substructureList = loadContainerBodyPart[SwiftDocKey.substructure.rawValue] as? [[String: SourceKitRepresentable]] ?? []
			let argumentStack = argumentInfo(substructures: substructureList, content: content)
			
			if let alias = AliasToken(functionName: actualName, invocationBody: body, argumentStack: argumentStack) {
				print(alias)
			} else if let injection = InjectionToken(functionName: actualName, invocationBody: body, argumentStack: argumentStack) {
				print(injection)
			}
			
			for substructure in substructureList {
				processLoadContainerBodyPart(loadContainerBodyPart: substructure, content: content)
			}
			
		default:
			break
		}
	}
	
	func argumentInfo(substructures: [[String: SourceKitRepresentable]], content: NSString) -> [ArgumentInfo] {
		var argumentStack = [ArgumentInfo]()
		let substructures = substructures.filter({ ($0[SwiftDocKey.kind.rawValue] as? String) == SwiftExpressionKind.argument.rawValue })
		
		for structure in substructures {
			guard let bodyOffset = structure[SwiftDocKey.bodyOffset.rawValue] as? Int64,
				let bodyLength = structure[SwiftDocKey.bodyLength.rawValue] as? Int64,
				let nameLength = structure[SwiftDocKey.nameLength.rawValue] as? Int64,
				let nameOffset = structure[SwiftDocKey.nameOffset.rawValue] as? Int64
				else { continue }
			let body = content.substringUsingByteRange(start: bodyOffset, length: bodyLength) ?? ""
			let name = nameLength > 0 ? content.substringUsingByteRange(start: nameOffset, length: nameLength) ?? "" : ""
			let argument = ArgumentInfo(name: name, value: body, structure: structure)
			argumentStack.append(argument)
		}
		return argumentStack
	}
	
	func extractActualFuncionInvokation(name: String) -> String {
		guard let dotIndex = name.reversed().index(of: ".") else {
			return name
		}
		return String(name[dotIndex.base...])
	}
	
	private func getStructure(file: File) -> SourceKitTuple? {
		do {
			let structure = try Structure(file: file)
			return (structure, file)
		} catch {
			return nil
		}
	}
	
	func getDIParts(values: SourceKitTuple, result: inout [SwiftType]) {
		for ss in (values.structure.dictionary[SwiftDocKey.substructure.rawValue] as? [[String: SourceKitRepresentable]] ?? []) {
			checkDiPart(ss: ss, parentName: "", file: values.file, result: &result)
		}
	}
	
	func checkDiPart(ss: [String: SourceKitRepresentable], parentName: String, file: File, result: inout [SwiftType]) {
		var parentName = parentName
		if let name = ss[SwiftDocKey.name.rawValue] as? String,
			let kindString = ss[SwiftDocKey.kind.rawValue] as? String {
			
			if let kind = SwiftType.Kind.init(string: kindString) {
				let inheritedTypes = (ss[SwiftDocKey.inheritedtypes.rawValue] as? [[String: SourceKitRepresentable]] ?? []).compactMap({ $0[SwiftDocKey.name.rawValue] as? String })
				let substructures = ss[SwiftDocKey.substructure.rawValue] as? [[String: SourceKitRepresentable]] ?? []
				let newName = parentName + (parentName.isEmpty ? "" : ".") + name
				let swiftType = SwiftType(name: newName, kind: kind, inheritedTypes: inheritedTypes, substructure: substructures, file: file)
				parentName += newName
				result.append(swiftType)
			}
		}
		
		for ss in (ss[SwiftDocKey.substructure.rawValue] as? [[String: SourceKitRepresentable]] ?? []) {
			checkDiPart(ss: ss, parentName: parentName, file: file, result: &result)
		}
	}
}


