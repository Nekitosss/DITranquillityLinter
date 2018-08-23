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
		
		
		let settingsPart = diParts.first(where: { $0.name == "SettingsUIDIPart" })!
		let loadContainerStructure = settingsPart.substructure.first(where: { $0[SwiftDocKey.name.rawValue] as! String == "load(container:)" })!
		processLoadContainerFunction(loadContainerStructure: loadContainerStructure, file: settingsPart.file)
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
		guard let name = loadContainerBodyPart[SwiftDocKey.name.rawValue] as? String,
			let bodyOffset = loadContainerBodyPart[SwiftDocKey.bodyOffset.rawValue] as? Int64,
			let bodyLength = loadContainerBodyPart[SwiftDocKey.bodyLength.rawValue] as? Int64
			else { return }
		let body = content.substringWithByteRange(start: Int(bodyOffset), length: Int(bodyLength))!
		let actualName = extractActualFuncionInvokation(name: name)
		print(actualName)
		print(body)
		if let alias = AliasToken(functionName: actualName, invocationBody: body) {
			print(alias)
		} else if let injection = InjectionToken(functionName: actualName, invocationBody: body) {
			print(injection)
		}
		
		let substructureList = loadContainerBodyPart[SwiftDocKey.substructure.rawValue] as? [[String: SourceKitRepresentable]] ?? []
		for substructure in substructureList {
			processLoadContainerBodyPart(loadContainerBodyPart: substructure, content: content)
		}
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


