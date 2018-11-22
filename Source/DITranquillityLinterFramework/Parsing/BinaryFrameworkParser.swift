//
//  BinaryFrameworkParser.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 22/11/2018.
//

import Foundation
import SourceKittenFramework

final class BinaryFrameworkParser {
	
	private struct BinaryFrameworkInfo {
		let path: String
		let name: String
		
		static let banryFrameworkPathExtension = "framework"
	}
	
	
	private let cacher = ResultCacher()
	
	
	
	/// Parse OS related bynary frameworks and frameworks from "FRAMEWORK_SEARCH_PATHS" build setting.
	func parseBinaryModules(fileContainer: FileContainer) throws -> [FileParserResult] {
		TimeRecorder.start(event: .parseBinary)
		defer { TimeRecorder.end(event: .parseBinary) }
		
		let (target, sdk) = self.createCommandLineArgumentInfoForSourceKitParsing()
		let userDefinedFrameworks = try self.getUserDefinedBinaryFrameworkNames()
		let commonFrameworks = self.getImplicitlyDependentBinaryFrameworks(sdk: sdk)
		
		return
			try self.parseFrameworkInfoList(userDefinedFrameworks, target: target, sdk: sdk, fileContainer: fileContainer, isCommon: false)
			+ self.parseFrameworkInfoList(commonFrameworks, target: target, sdk: sdk, fileContainer: fileContainer, isCommon: true)
	}
	
	
	private func createCommandLineArgumentInfoForSourceKitParsing() -> (target: String, sdk: String) {
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
		return (target, sdk)
	}
	
	
	/// Parse user defined binary frameworks (Carthage + Cooapods-created)
	private func getUserDefinedBinaryFrameworkNames() throws -> [BinaryFrameworkInfo] {
		guard let frameworkPathsString = XcodeEnvVariable.frameworkSearchPaths.value() else {
			return []
		}
		let frameworkPaths = frameworkPathsString.split(separator: "\"").filter({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
		
		var frameworkInfoList: [BinaryFrameworkInfo] = []
		for frameworkPath in frameworkPaths {
			let stringedFrameworkPath = String(frameworkPath.trimmingCharacters(in: .whitespacesAndNewlines))
			guard let frameworkURL = URL(string: stringedFrameworkPath) else {
				continue
			}
			
			// Get the directory contents urls (including subfolders urls)
			let directoryContents = try FileManager.default.contentsOfDirectory(at: frameworkURL, includingPropertiesForKeys: nil, options: [])

			for file in directoryContents where file.pathExtension == BinaryFrameworkInfo.banryFrameworkPathExtension {
				let info = BinaryFrameworkInfo(path: stringedFrameworkPath, name: file.deletingPathExtension().lastPathComponent)
				frameworkInfoList.append(info)
			}
		}
		return frameworkInfoList
	}
	
	/// Parse common frameworks (UIKit + Cocoa)
	private func getImplicitlyDependentBinaryFrameworks(sdk: String) -> [BinaryFrameworkInfo] {
		let commonFrameworksPath = sdk + "/System/Library/Frameworks"
		
		var commonFrameworkInfoList: [BinaryFrameworkInfo] = []
		if sdk.range(of: "iPhoneSimulator") != nil || sdk.range(of: "iPhoneOS") != nil {
			commonFrameworkInfoList.append(BinaryFrameworkInfo(path: commonFrameworksPath, name: "UIKit"))
		}
		if sdk.range(of: "MacOSX") != nil {
			commonFrameworkInfoList.append(BinaryFrameworkInfo(path: commonFrameworksPath, name: "Cocoa"))
		}
		return commonFrameworkInfoList
	}
	
	
	/// Parse concrete binary framework.
	private func parseFrameworkInfoList(_ frameworkInfoList: [BinaryFrameworkInfo], target: String, sdk: String, fileContainer: FileContainer, isCommon: Bool) throws -> [FileParserResult] {
		let templateCompilerArguments = ["-target", target, "-sdk", sdk, "-F"]
		
		return try frameworkInfoList.flatMap { (frameworkInfo) -> [FileParserResult] in
			let compilerArguments = templateCompilerArguments + [frameworkInfo.path]
			let cacheName = frameworkInfo.path + frameworkInfo.name
			
			if let cachedResult = cacher.getCachedBinaryFiles(name: cacheName, isCommonCache: isCommon) {
				return cachedResult
			} else {
				let parsedModule = try parseModule(moduleName: frameworkInfo.name, frameworksPath: frameworkInfo.path, compilerArguments: compilerArguments, fileContainer: fileContainer)
				cacher.cacheBinaryFiles(list: parsedModule, name: cacheName, isCommonCache: isCommon)
				return parsedModule
			}
		}
	}
	
	/// Parse Binary framework path. Framework may be separate into several ".h" files. Method parse passed "***.h" file.
	private func parseModule(moduleName: String, frameworksPath: String, compilerArguments: [String], fileContainer: FileContainer) throws -> [FileParserResult] {
		print("Parse module: \(moduleName)")
		let frameworksURL = URL(fileURLWithPath: frameworksPath + "/\(moduleName).framework/Headers", isDirectory: true)
		let frameworks = try self.collectFrameworkNames(frameworksURL: frameworksURL)
		return try frameworks.map { frameworkName in
			print("Parse framework: \(frameworkName)")
			let fullFrameworkName = self.fullFrameworkName(moduleName: moduleName, frameworkName: frameworkName)
			let fileName = frameworksURL.path + "/" + fullFrameworkName + ".h"
			
			let contents = try self.createSwiftSourcetext(for: fullFrameworkName, use: compilerArguments)
			let parser = FileParser(contents: contents, path: fileName, module: moduleName)
			let fileParserResult = try parser.parse()
			fileContainer.set(value: parser.file, for: fileName)
			return fileParserResult
		}
	}
	
	/// Get swift source text from binary framework using SourceKit
	private func createSwiftSourcetext(for fullFrameworkName: String, use compilerArguments: [String]) throws -> String {
		let toolchains = ["com.apple.dt.toolchain.XcodeDefault"]
		let skObject: SourceKitObject = [
			"key.request": UID("source.request.editor.open.interface"),
			"key.name": UUID().uuidString,
			"key.compilerargs": compilerArguments,
			"key.modulename": fullFrameworkName,
			"key.toolchains": toolchains,
			"key.synthesizedextensions": 1
		]
		let result = try Request.customRequest(request: skObject).send()
		return (result["key.sourcetext"] as? String) ?? ""
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
