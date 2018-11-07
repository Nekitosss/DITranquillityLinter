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

public let linterVersion = "0.0.1"

public class Tokenizer {
	
	typealias SourceKitTuple = (structure: Structure, file: File)
	
	public init() {}
	
	let container = FileContainer()
	public func process(files: [String]) -> Bool {
		let filteredFiles = files.filter({ $0.hasSuffix(".swift") && !$0.hasSuffix("generated.swift") && !$0.hasSuffix("pb.swift") })
		let collectedInfo = collectInfo(files: filteredFiles)
		let parsingContext = ParsingContext(container: container, collectedInfo: collectedInfo)
		TimeRecorder.common.start(event: .createTokens)
		if let initContainerStructure = ContainerInitializatorFinder.findContainerStructure(parsingContext: parsingContext) {
			TimeRecorder.common.end(event: .createTokens)
			guard parsingContext.errors.isEmpty else {
				display(errorList: parsingContext.errors)
				return false
			}
			
			TimeRecorder.common.start(event: .validate)
			let validator = GraphValidator()
			let errorList = validator.validate(containerPart: initContainerStructure, collectedInfo: collectedInfo)
			TimeRecorder.common.end(event: .validate)
			display(errorList: errorList)
			return errorList.isEmpty
		}
		
		return true
	}
	
	func display(errorList: [GraphError]) {
		errorList.forEach {
			print($0.xcodeMessage)
		}
	}
	
	func collectInfo(files: [String]) -> [String: Type] {
		let paths = files.map({ Path($0) })
		guard let filesParsers: [FileParser?] = try? paths.parallelMap({
			guard let file = File(path: $0.string) else { return nil }
			container[$0.string] = file
			return FileParser(contents: file.contents, path: $0, module: nil)
		}) else { return [:] }
		
		TimeRecorder.common.start(event: .parseSourceAndDependencies)
		var allResults = (try? filesParsers.parallelMap({ try! $0?.parse() }).compactMap({ $0 })) ?? []
		TimeRecorder.common.end(event: .parseSourceAndDependencies)
		TimeRecorder.common.start(event: .parseBinary)
		allResults += parseBinaryModules(fileContainer: container)
		TimeRecorder.common.end(event: .parseBinary)
		TimeRecorder.common.start(event: .compose)
		defer {
			TimeRecorder.common.end(event: .compose)
		}
		let parserResult = allResults.reduce(FileParserResult(path: nil, module: nil, types: [], typealiases: [], linterVersion: linterVersion)) { acc, next in
			acc.typealiases += next.typealiases
			acc.types += next.types
			return acc
		}
		
		return Composer().composedTypes(parserResult)
	}
	
	private func parseBinaryModules(fileContainer: FileContainer) -> [FileParserResult] {
		let enironment = ProcessInfo.processInfo.environment
		
		var target = "x86_64-apple-ios11.4"
		var sdk = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator12.1.sdk"
		
		if let arch = enironment[XcodeEnvVariable.platformPreferredArch.rawValue],
			let targetPrefix = enironment[XcodeEnvVariable.targetPrefix.rawValue],
			let deploymentTarget = enironment[XcodeEnvVariable.deploymentTarget.rawValue] {
			//		"${PLATFORM_PREFERRED_ARCH}-apple-${SWIFT_PLATFORM_TARGET_PREFIX}${IPHONEOS_DEPLOYMENT_TARGET}"
			target = "\(arch)-apple-\(targetPrefix)\(deploymentTarget)"
			print("Found environment info.")
		} else {
			print("Environment info not found. Will be used default")
		}
		if let sdkRoot = enironment[XcodeEnvVariable.sdkRoot.rawValue] {
			sdk = sdkRoot
		}
		
		// Parse all binary frameworks (Carthage + Cooapods-created)
		var frameworkInfoList: [(path: String, name: String)] = []
		if let frameworkPathsString = enironment[XcodeEnvVariable.frameworkSearchPaths.rawValue] {
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
		
		// Parse common frameworks (UIKit + Foundation)
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
	
	func parseFrameworkInfoList(_ frameworkInfoList: [(path: String, name: String)], target: String, sdk: String, fileContainer: FileContainer, isCommon: Bool) -> [FileParserResult] {
		
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
	
	private func fullFrameworkName(moduleName: String, frameworkName: String) -> String {
		return moduleName == frameworkName ? frameworkName : moduleName + "." + frameworkName
	}
	
	private func collectFrameworkNames(frameworksURL: URL) throws -> [String] {
		let fileURLs = try FileManager.default.contentsOfDirectory(at: frameworksURL, includingPropertiesForKeys: nil)
		return fileURLs.filter({ $0.pathExtension == "h" }).map({ $0.lastPathComponent }).map({ $0.droppedSuffix(".h") })
	}
	
}



