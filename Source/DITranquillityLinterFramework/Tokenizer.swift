//
//  Printer.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 19/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework
import PathKit

public let linterVersion = "0.0.2"

public class Tokenizer {
	
	private let isTestEnvironment: Bool
	private let validator = GraphValidator()
	private let composer = Composer()
	private let binaryFrameworkParser = BinaryFrameworkParser()
	
	public init(isTestEnvironment: Bool) {
		self.isTestEnvironment = isTestEnvironment
	}
	
	let container = FileContainer()
	public func process(files: [String]) -> Bool {
		let filteredFiles = files.filter(shouldBeParsed)
		let collectedInfo = collectInfo(files: filteredFiles)
		let parsingContext = ParsingContext(container: container, collectedInfo: collectedInfo)
		
		TimeRecorder.start(event: .createTokens)
		if let initContainerStructure = ContainerInitializatorFinder.findContainerStructure(parsingContext: parsingContext) {
			TimeRecorder.end(event: .createTokens)
			guard parsingContext.errors.isEmpty else {
				display(errorList: parsingContext.errors)
				return false
			}
			
			TimeRecorder.start(event: .validate)
			let errorList = validator.validate(containerPart: initContainerStructure, collectedInfo: collectedInfo)
			TimeRecorder.end(event: .validate)
			display(errorList: errorList)
			return errorList.isEmpty
		}
		
		return true
	}
	
	/// Include of exclude file from analyzed file list.
	///
	/// - Parameter fileName: Analyzing file.
	/// - Returns: Should file be analyzed.
	private func shouldBeParsed(fileName: String) -> Bool {
		let parsingExcludedSuffixes = ["generated.swift", "pb.swift"]
		return fileName.hasSuffix(".swift") && !parsingExcludedSuffixes.contains(where: { fileName.hasSuffix($0) })
	}
	
	/// Prints all founded errors to XCode
	func display(errorList: [GraphError]) {
		errorList.forEach {
			print($0.xcodeMessage)
		}
	}
	
	/// Parse source files to Type info map. Also, parse necessary bynary frameworks under the hood.
	/// Cococapod source code parse as a binary framework.
	///
	/// - Parameter files: Input source files.
	/// - Returns: All collected information dictionary. With as much as possible resolved types.
	func collectInfo(files: [String]) -> [String: Type] {
		do {
			TimeRecorder.start(event: .parseSourceAndDependencies)
			var allResults = try files.parallelFlatMap({ (fileName) -> FileParserResult? in
				guard let file = File(path: fileName) else { return nil }
				container.set(value: file, for: fileName)
				return try FileParser(contents: file.contents, path: fileName, module: nil).parse()
			})
			TimeRecorder.end(event: .parseSourceAndDependencies)
			
			if !isTestEnvironment {
				allResults += try binaryFrameworkParser.parseBinaryModules(fileContainer: container)
			}
			
			TimeRecorder.start(event: .compose)
			defer { TimeRecorder.end(event: .compose) }
			
			let parserResult = allResults.reduce(into: FileParserResult(path: nil, module: nil, types: [], linterVersion: linterVersion)) {
				$0.typealiases += $1.typealiases
				$0.types += $1.types
			}
			
			return composer.composedTypes(parserResult)
			
		} catch {
			print("Error during file parsing", error)
			exit(EXIT_FAILURE)
		}
	}
}



