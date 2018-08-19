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
		var result: [[String: SourceKitRepresentable]] = []
		structures.forEach({ getDIParts(values: $0, result: &result) })
		print(result.count)
		
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
	
	func getDIParts(values: SourceKitTuple, result: inout [[String: SourceKitRepresentable]]) {
		for ss in (values.structure.dictionary[SwiftDocKey.substructure.rawValue] as? [[String: SourceKitRepresentable]] ?? []) {
			checkDiPart(ss: ss, result: &result)
		}
	}
	
	func checkDiPart(ss: [String: SourceKitRepresentable], result: inout [[String: SourceKitRepresentable]]) {
		let inheritedTypes = (ss[SwiftDocKey.inheritedtypes.rawValue] as? [[String: SourceKitRepresentable]] ?? []).compactMap({ $0[SwiftDocKey.name.rawValue] as? String })
		
		if inheritedTypes.contains("DIPart") || inheritedTypes.contains("DIFramework") {
			result.append(ss)
		}
		
		for ss in (ss[SwiftDocKey.substructure.rawValue] as? [[String: SourceKitRepresentable]] ?? []) {
			checkDiPart(ss: ss, result: &result)
		}
	}
}


