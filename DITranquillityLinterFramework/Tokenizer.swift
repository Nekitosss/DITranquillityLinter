//
//  Printer.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 19/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

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
		print(diParts[0].substructure)
		
		print("End")
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
			checkDiPart(ss: ss, parentName: "", result: &result)
		}
	}
	
	func checkDiPart(ss: [String: SourceKitRepresentable], parentName: String, result: inout [SwiftType]) {
		var parentName = parentName
		if let name = ss[SwiftDocKey.name.rawValue] as? String,
			let kindString = ss[SwiftDocKey.kind.rawValue] as? String {
			
			if let kind = SwiftType.Kind.init(string: kindString) {
				let inheritedTypes = (ss[SwiftDocKey.inheritedtypes.rawValue] as? [[String: SourceKitRepresentable]] ?? []).compactMap({ $0[SwiftDocKey.name.rawValue] as? String })
				let substructures = ss[SwiftDocKey.substructure.rawValue] as? [[String: SourceKitRepresentable]] ?? []
				let newName = parentName + (parentName.isEmpty ? "" : ".") + name
				let swiftType = SwiftType(name: newName, kind: kind, inheritedTypes: inheritedTypes, substructure: substructures)
				parentName += newName
				result.append(swiftType)
			}
		}
		
		for ss in (ss[SwiftDocKey.substructure.rawValue] as? [[String: SourceKitRepresentable]] ?? []) {
			checkDiPart(ss: ss, parentName: parentName, result: &result)
		}
	}
}


