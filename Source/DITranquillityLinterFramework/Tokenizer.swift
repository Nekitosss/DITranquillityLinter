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
import SourceKit

public let linterVersion = "0.0.2"

public class Tokenizer {
	
	private let isTestEnvironment: Bool
	
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
			let validator = GraphValidator()
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
		let paths = files.map({ Path($0) })
		guard let filesParsers: [FileParser?] = try? paths.parallelMap({
			guard let file = File(path: $0.string) else { return nil }
			container[$0.string] = file
			return FileParser(contents: file.contents, path: $0, module: nil)
		}) else { return [:] }
		
		TimeRecorder.start(event: .parseSourceAndDependencies)
		var allResults: [FileParserResult] = []
		do {
			allResults = try filesParsers.parallelMap({ try $0?.parse() }).compactMap({ $0 })
		} catch {
			print("Error during file parsing", error)
			exit(EXIT_FAILURE)
		}
		TimeRecorder.end(event: .parseSourceAndDependencies)
		
		if !isTestEnvironment {
			TimeRecorder.start(event: .parseBinary)
			allResults += parseBinaryModules(fileContainer: container)
			TimeRecorder.end(event: .parseBinary)
		}
		TimeRecorder.start(event: .compose)
		defer {
			TimeRecorder.end(event: .compose)
		}
		let parserResult = allResults.reduce(FileParserResult(path: nil, module: nil, types: [], typealiases: [], linterVersion: linterVersion)) { acc, next in
			acc.typealiases += next.typealiases
			acc.types += next.types
			return acc
		}
		
		return Composer().composedTypes(parserResult)
	}
	
	/// Parse OS related bynary frameworks and frameworks from "FRAMEWORK_SEARCH_PATHS" build setting.
	private func parseBinaryModules(fileContainer: FileContainer) -> [FileParserResult] {
		var target = EnvVariable.defaultTarget.value()
		var sdk = EnvVariable.defaultSDK.value()
		
		if let arch = XcodeEnvVariable.platformPreferredArch.value(),
			let targetPrefix = XcodeEnvVariable.targetPrefix.value(),
			let deploymentTarget = XcodeEnvVariable.deploymentTarget.value() {
			//		"${PLATFORM_PREFERRED_ARCH}-apple-${SWIFT_PLATFORM_TARGET_PREFIX}${IPHONEOS_DEPLOYMENT_TARGET}"
			target = "\(arch)-apple-\(targetPrefix)\(deploymentTarget)"
			print("Found environment info.")
		} else {
			print("Environment info not found. Will be used default")
		}
		if let sdkRoot = XcodeEnvVariable.sdkRoot.value() {
			sdk = sdkRoot
		}
		
		// Parse all binary frameworks (Carthage + Cooapods-created)
		var frameworkInfoList: [(path: String, name: String)] = []
		if let frameworkPathsString = XcodeEnvVariable.frameworkSearchPaths.value() {
			let frameworkPaths = frameworkPathsString.split(separator: "\"").filter({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
			
			for frameworkPath in frameworkPaths {
				let stringedFrameworkPath = String(frameworkPath.trimmingCharacters(in: .whitespacesAndNewlines))
				guard let frameworkURL = URL(string: stringedFrameworkPath) else { continue }
				do {
					// Get the directory contents urls (including subfolders urls)
					let directoryContents = try FileManager.default.contentsOfDirectory(at: frameworkURL, includingPropertiesForKeys: nil, options: [])
					
					for file in directoryContents where file.pathExtension == "framework" {
						frameworkInfoList.append((stringedFrameworkPath, file.deletingPathExtension().lastPathComponent))
					}
					
				} catch {
					print(error.localizedDescription)
					continue
				}
			}
		}
		
		var result: [FileParserResult] = []
		result += parseFrameworkInfoList(frameworkInfoList, target: target, sdk: sdk, fileContainer: fileContainer, isCommon: false)
		
		// Parse common frameworks (UIKit + Cocoa)
		let commonFrameworksPath = sdk + "/System/Library/Frameworks"
		
		var commonFrameworkInfoList: [(path: String, name: String)] = []
		if sdk.range(of: "iPhoneSimulator") != nil || sdk.range(of: "iPhoneOS") != nil {
			commonFrameworkInfoList.append((commonFrameworksPath, "UIKit"))
		}
		if sdk.range(of: "MacOSX") != nil {
			commonFrameworkInfoList.append((commonFrameworksPath, "Cocoa"))
		}
		result += parseFrameworkInfoList(commonFrameworkInfoList, target: target, sdk: sdk, fileContainer: fileContainer, isCommon: true)
		return result
	}
	
	/// Parse concrete binary framework.
	private func parseFrameworkInfoList(_ frameworkInfoList: [(path: String, name: String)], target: String, sdk: String, fileContainer: FileContainer, isCommon: Bool) -> [FileParserResult] {
		
		var result: [FileParserResult] = []
		let cacher = ResultCacher()
		for frameworkInfo in frameworkInfoList {
			let compilerArguments = [
				"-target",
				target,
				"-sdk",
				sdk,
				"-F",
				frameworkInfo.path,
				]
			
			let cacheName = frameworkInfo.path + frameworkInfo.name
			
			if let cachedResult = cacher.getCachedBinaryFiles(name: cacheName, isCommonCache: isCommon) {
				result += cachedResult
			} else {
				let parsedModule = parseModule(moduleName: frameworkInfo.name, frameworksPath: frameworkInfo.path, compilerArguments: compilerArguments, fileContainer: fileContainer)
				result += parsedModule
				cacher.cacheBinaryFiles(list: parsedModule, name: cacheName, isCommonCache: isCommon)
			}
		}
		return result
	}
	
	/// Parse Binary framework path. Framework may be separate into several ".h" files. Method parse passed "***.h" file.
	private func parseModule(moduleName: String, frameworksPath: String, compilerArguments: [String], fileContainer: FileContainer) -> [FileParserResult] {
		print("Parse module: \(moduleName)")
		let frameworksURL = URL(fileURLWithPath: frameworksPath + "/\(moduleName).framework/Headers", isDirectory: true)
		guard let frameworks = try? collectFrameworkNames(frameworksURL: frameworksURL) else { return [] }
		var parsedFilesResults: [FileParserResult] = []
		for frameworkName in frameworks {
			print("Parse framework: \(frameworkName)")
			do {
				let toolchains = ["com.apple.dt.toolchain.XcodeDefault"]
				let fullFrameworkName = self.fullFrameworkName(moduleName: moduleName, frameworkName: frameworkName)
				let skObject: SourceKitObject = [
					"key.request": UID("source.request.editor.open.interface"),
					"key.name": UUID().uuidString,
					"key.compilerargs": compilerArguments,
					"key.modulename": fullFrameworkName,
					"key.toolchains": toolchains,
					"key.synthesizedextensions": 1
				]
				let request = Request.customRequest(request: skObject)
				let result = try request.send()
				guard let contents = result["key.sourcetext"] as? String else { continue }
				let path = Path(frameworksURL.path + "/" + fullFrameworkName + ".h")
				let parser = FileParser(contents: contents, path: path, module: moduleName)
				let fileParserResult = try parser.parse()
				fileContainer[path.string] = parser.file
				parsedFilesResults.append(fileParserResult)
			} catch {
				print(error)
				continue
			}
		}
		return parsedFilesResults
	}
	
	/// Concatenate framework part with framework name for SourceKit parser.
	private func fullFrameworkName(moduleName: String, frameworkName: String) -> String {
		return moduleName == frameworkName ? frameworkName : moduleName + "." + frameworkName
	}
	
	/// Collects all framework parts ("*.h" files).
	private func collectFrameworkNames(frameworksURL: URL) throws -> [String] {
		let fileURLs = try FileManager.default.contentsOfDirectory(at: frameworksURL, includingPropertiesForKeys: nil)
		return fileURLs.filter({ $0.pathExtension == "h" }).map({ $0.lastPathComponent }).map({ $0.droppedSuffix(".h") })
	}
	
}



