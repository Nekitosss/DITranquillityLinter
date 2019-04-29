//
//  ModuleParser.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 03/04/2019.
//

import Foundation
import SourceKittenFramework
import PathKit

final class ModuleParser {
	
	private let composer: Composer
	private let binaryFrameworkParser: BinaryFrameworkParser
	private let implicitDependencyTypeResolver: ImplicitFrameworkDependencyTypesResolver
	private let container: FileContainer
	
	public init(composer: Composer, container: FileContainer, binaryFrameworkParser: BinaryFrameworkParser, implicitDependencyTypeResolver: ImplicitFrameworkDependencyTypesResolver) {
		self.composer = composer
		self.container = container
		self.binaryFrameworkParser = binaryFrameworkParser
		self.implicitDependencyTypeResolver = implicitDependencyTypeResolver
	}
	
	/// Include of exclude file from analyzed file list.
	///
	/// - Parameter fileName: Analyzing file.
	/// - Returns: Should file be analyzed.
	func shouldBeParsed(fileName: String) -> Bool {
		let parsingExcludedSuffixes = ["generated.swift", "pb.swift"]
		return fileName.hasSuffix(".swift") && !parsingExcludedSuffixes.contains(where: { fileName.hasSuffix($0) })
	}
	
	
	/// Parse source files to Type info map. Also, parse necessary bynary frameworks under the hood.
	/// Cococapod source code parse as a binary framework.
	///
	/// - Parameter files: Input source files.
	/// - Returns: All collected information dictionary. With as much as possible resolved types.
	func collectInfo(files: [String]) throws -> [String: Type] {
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
	}
	
	func getCachedContainers() throws -> [String: ContainerPart] {
		return try self.binaryFrameworkParser.parseCachedInfoInExplicitBinaryModules()
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
	
	
}
