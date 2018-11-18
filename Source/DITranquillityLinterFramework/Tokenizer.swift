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
	private let validator = GraphValidator()
	private let composer = Composer()
	
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
				TimeRecorder.start(event: .parseBinary)
				allResults += parseBinaryModules(fileContainer: container)
				TimeRecorder.end(event: .parseBinary)
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
		guard let frameworks = try? collectFrameworkNames(frameworksURL: frameworksURL) else {
			return []
		}
		var parsedFilesResults: [FileParserResult] = []
		for frameworkName in frameworks {
			print("Parse framework: \(frameworkName)")
			do {
				let fullFrameworkName = self.fullFrameworkName(moduleName: moduleName, frameworkName: frameworkName)
				let request = createSourceKitRequest(compilerArguments, fullFrameworkName: fullFrameworkName)
				let result = try request.send()
				guard let contents = result["key.sourcetext"] as? String else {
					continue
				}
				let fileName = frameworksURL.path + "/" + fullFrameworkName + ".h"
				let parser = FileParser(contents: contents, path: fileName, module: moduleName)
				let fileParserResult = try parser.parse()
				fileContainer.set(value: parser.file, for: fileName)
				parsedFilesResults.append(fileParserResult)
			} catch {
				print(error)
				continue
			}
		}
		return parsedFilesResults
	}
	
	private func createSourceKitRequest(_ compilerArguments: [String], fullFrameworkName: String) -> Request {
		let toolchains = ["com.apple.dt.toolchain.XcodeDefault"]
		let skObject: SourceKitObject = [
			"key.request": UID("source.request.editor.open.interface"),
			"key.name": UUID().uuidString,
			"key.compilerargs": compilerArguments,
			"key.modulename": fullFrameworkName,
			"key.toolchains": toolchains,
			"key.synthesizedextensions": 1
		]
		return Request.customRequest(request: skObject)
	}
	
	/// Concatenate framework part with framework name for SourceKit parser.
	private func fullFrameworkName(moduleName: String, frameworkName: String) -> String {
		return moduleName == frameworkName ? frameworkName : moduleName + "." + frameworkName
	}
	
	/// Collects all framework parts ("*.h" files).
	private func collectFrameworkNames(frameworksURL: URL) throws -> [String] {
		let fileURLs = try FileManager.default.contentsOfDirectory(at: frameworksURL, includingPropertiesForKeys: nil)
		return fileURLs.filter({ $0.pathExtension == "h" }).map({ $0.lastPathComponent.droppedSuffix(".h") })
	}
}



