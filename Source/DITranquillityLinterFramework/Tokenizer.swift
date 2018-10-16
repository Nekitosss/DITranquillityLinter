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

public class Tokenizer {
	
	typealias SourceKitTuple = (structure: Structure, file: File)
	
	public init() {}
	
	let container = FileContainer()
	public func process(files: [URL]) -> Bool {
		
		let collectedInfo = collectInfo(files: files)
		if let initContainerStructure = ContainerInitializatorFinder.findContainerStructure(dictionary: collectedInfo, fileContainer: container) {
			let validator = GraphValidator()
			let errorList = validator.validate(containerPart: initContainerStructure, collectedInfo: collectedInfo)
			
			errorList.forEach {
				print($0.xcodeMessage)
			}
			return errorList.isEmpty
		}
		
		return true
	}
	
	func parseBinaryModules(fileContainer: FileContainer) -> [FileParserResult] {
		let enironment = ProcessInfo.processInfo.environment
		var target = "x86_64-apple-ios11.4"
		var sdk = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator12.0.sdk"
		
		if let arch = enironment["PLATFORM_PREFERRED_ARCH"],
			let targetPrefix = enironment["SWIFT_PLATFORM_TARGET_PREFIX"],
			let deploymentTarget = enironment["IPHONEOS_DEPLOYMENT_TARGET"] {
			//		"${PLATFORM_PREFERRED_ARCH}-apple-${SWIFT_PLATFORM_TARGET_PREFIX}${IPHONEOS_DEPLOYMENT_TARGET}"
			target = "\(arch)-apple-\(targetPrefix)\(deploymentTarget)"
			print("Found environment info.")
		} else {
			print("Environment info not found. Will be used default")
		}
		if let sdkRoot = enironment["SDKROOT"] {
			sdk = sdkRoot
		}
		let frameworksPath = sdk + "/System/Library/Frameworks"
		
		let compilerArguments = [
			"-target",
			target,
			"-sdk",
			sdk,
			"-F",
			frameworksPath,
			]
		
		var commonFrameworkNames = [String]()
		if sdk.range(of: "iPhoneSimulator") != nil || sdk.range(of: "iPhoneOS") != nil {
			commonFrameworkNames = ["UIKit", "Foundation"]
		}
		if sdk.range(of: "MacOSX") != nil {
			commonFrameworkNames = ["Cocoa", "Foundation"]
		}
		return commonFrameworkNames.flatMap {
			parseModule(moduleName: $0, frameworksPath: frameworksPath, compilerArguments: compilerArguments, fileContainer: fileContainer)
		}
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
	
	func collectInfo(files: [URL]) -> [String: Type] {
		let paths = files.map({ Path($0.path) })
		let filesParsers: [FileParser] = paths.compactMap({
			guard let file = File(path: $0.string) else { return nil }
			container[$0.string] = file
			return FileParser(contents: file.contents, path: $0, module: nil)
		})
		let allResults = filesParsers.map({ try! $0.parse() }) //+ parseBinaryModules(fileContainer: container)
		let parserResult = allResults.reduce(FileParserResult(path: nil, module: nil, types: [], typealiases: [])) { acc, next in
			acc.typealiases += next.typealiases
			acc.types += next.types
			return acc
		}
		
		return Composer().composedTypes(parserResult)
	}
	
}



