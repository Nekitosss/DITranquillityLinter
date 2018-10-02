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
	
	public func process(files: [URL]) -> Bool {
		let collectedInfo = collectInfo(files: files)
		if let initContainerStructure = ContainerInitializatorFinder.findContainerStructure(dictionary: collectedInfo) {
			let validator = GraphValidator()
			let errorList = validator.validate(containerPart: initContainerStructure, collectedInfo: collectedInfo)
			
			errorList.forEach {
				print($0.xcodeMessage)
			}
			return errorList.isEmpty
		}
		
		return true
	}
	
	func collectInfo(files: [URL]) -> [String: Type] {
		let paths = files.map({ Path($0.path) })
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
		return composed.reduce(into: [String: Type]()) { $0[$1.name] = $1 }
	}
	
}


