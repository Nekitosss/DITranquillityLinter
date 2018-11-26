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
	
	let container: FileContainer
	
	private let isTestEnvironment: Bool
	private let validator = GraphValidator()
	private let composer = Composer()
	private let binaryFrameworkParser: BinaryFrameworkParser
	private let implicitDependencyTypeResolver: ImplicitFrameworkDependencyTypesResolver
	
	
	public init(isTestEnvironment: Bool) {
		self.isTestEnvironment = isTestEnvironment
		self.container = FileContainer()
		self.binaryFrameworkParser = BinaryFrameworkParser(fileContainer: self.container)
		self.implicitDependencyTypeResolver = ImplicitFrameworkDependencyTypesResolver(binaryFrameworkParser: self.binaryFrameworkParser)
	}
	
	
	public func process(files: [String]) -> Bool {
		let filteredFiles = files.filter(shouldBeParsed)
		let collectedInfo = collectInfo(files: filteredFiles)
		let parsingContext = ParsingContext(container: container, collectedInfo: collectedInfo)
		let containerBuilder = ContainerInitializatorFinder(parsingContext: parsingContext)
		
		guard let initContainerStructure = containerBuilder.findContainerStructure() else {
			print("Could not find DIContainer creation")
			return false
		}
		guard parsingContext.errors.isEmpty else {
			display(errorList: parsingContext.errors)
			return false
		}

		let errorList = validator.validate(containerPart: initContainerStructure, collectedInfo: collectedInfo)
		display(errorList: errorList)
		return errorList.isEmpty
	}
	
	
	/// Include of exclude file from analyzed file list.
	///
	/// - Parameter fileName: Analyzing file.
	/// - Returns: Should file be analyzed.
	private func shouldBeParsed(fileName: String) -> Bool {
		let parsingExcludedSuffixes = ["generated.swift", "pb.swift"]
		return fileName.hasSuffix(".swift") && !parsingExcludedSuffixes.contains(where: { fileName.hasSuffix($0) })
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
				self.container.set(value: file, for: fileName)
				return try FileParser(contents: file.contents, path: fileName, module: nil).parse()
			})
			TimeRecorder.end(event: .parseSourceAndDependencies)
			
			allResults += try self.binaryFrameworkParser.parseExplicitBinaryModules()
			
			TimeRecorder.start(event: .compose)
			defer { TimeRecorder.end(event: .compose) }
			
			let composedResult = self.composeResult(from: allResults)
			
			let allTypes = self.mergeResult(list: allResults).types
			if let fullyUnresolvedResult = try self.implicitDependencyTypeResolver.resolveTypesFromImplicitDependentBinaryFrameworks(in: allTypes, composedTypes: composedResult) {
				allResults += fullyUnresolvedResult
				return self.composeResult(from: allResults)
			} else {
				return composedResult
			}
			
		} catch {
			print("Error during file parsing", error)
			exit(EXIT_FAILURE)
		}
	}
	
	private func mergeResult(list: [FileParserResult]) -> FileParserResult {
		return list.reduce(into: FileParserResult(path: nil, module: nil, types: [], linterVersion: linterVersion)) {
			$0.typealiases += $1.typealiases
			$0.types += $1.types
		}
	}
	
	private func composeResult(from fileParserList: [FileParserResult]) -> [String: Type] {
		let parserResult = self.mergeResult(list: fileParserList)
		return self.composer.composedTypes(parserResult)
	}
	
	
	/// Prints all founded errors to XCode
	private func display(errorList: [GraphError]) {
		errorList.forEach {
			print($0.xcodeMessage)
		}
	}
}
