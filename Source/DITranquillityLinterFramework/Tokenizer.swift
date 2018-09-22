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
import PathKit

public class Tokenizer {
	
	typealias SourceKitTuple = (structure: Structure, file: File)
	
	public init() {}
	
	public func process(files: [URL], project: XcodeProj) {
		let paths = files.map({ Path.init($0.path) })
		let filesParsers: [FileParser] = paths.compactMap({
			guard let contents = File(path: $0.string)?.contents else { return nil }
			return try? FileParser(contents: contents, path: $0, module: nil)
		})
		let allResults = filesParsers.map({ try! $0.parse() })
		let parserResult = allResults.reduce(FileParserResult(path: nil, module: nil, types: [], typealiases: [])) { acc, next in
			acc.typealiases += next.typealiases
			acc.types += next.types
			return acc
		}
		
		let composed = Composer().uniqueTypes(parserResult)
		
		let structures = files.compactMap({ File(path: $0.path) }).compactMap(getStructure)
		var result: [SwiftType] = []
		let dictionary = composed.reduce(into: [String: Type]()) { $0[$1.name] = $1 }
		
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


