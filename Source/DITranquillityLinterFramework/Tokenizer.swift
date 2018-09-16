//
//  Printer.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 19/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework
import xcodeproj

public class Tokenizer {
	
	typealias SourceKitTuple = (structure: Structure, file: File)
	
	public init() {}
	
	public func process(files: [URL], project: XcodeProj) {
		let skFile = files.compactMap({ File(path: $0.path) })
		print(skFile.count)
		let structures = skFile.compactMap(getStructure)
		var result: [SwiftType] = []
		structures.forEach({ getDIParts(values: $0, result: &result) })
		let dictionary = result.reduce(into: [String: SwiftType]()) { $0[$1.name] = $1 }
		
		if let initContainerStructure = ContainerInitializatorFinder.findContainerStructure(dictionary: dictionary, project: project) {
			print(1)
		}
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
		for ss in (values.structure.dictionary.substructures ?? []) {
			checkDiPart(ss: ss, parentName: "", file: values.file, result: &result)
		}
	}
	
	func checkDiPart(ss: [String: SourceKitRepresentable], parentName: String, file: File, result: inout [SwiftType]) {
		var parentName = parentName
		if let name: String = ss.get(.name),
			let kindString: String = ss.get(.kind) {
			
			if let kind = SwiftType.Kind.init(string: kindString) {
				let inheritedTypes = (ss.get(.inheritedtypes, of: [SourceKitStructure].self) ?? []).compactMap({ $0.get(.name, of: String.self) })
				let substructures = ss.substructures ?? []
				let newName = parentName + (parentName.isEmpty ? "" : ".") + name
				let swiftType = SwiftType(name: newName, kind: kind, inheritedTypes: inheritedTypes, substructure: substructures, file: file)
				parentName += newName
				result.append(swiftType)
			}
		}
		
		for ss in (ss.substructures ?? []) {
			checkDiPart(ss: ss, parentName: parentName, file: file, result: &result)
		}
	}
}


