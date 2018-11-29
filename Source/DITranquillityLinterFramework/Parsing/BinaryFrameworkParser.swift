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
	
	
	private let cacher: ResultCacher
	private let fileContainer: FileContainer
	private let isTestEnvironment: Bool
	
	init(fileContainer: FileContainer, isTestEnvironment: Bool) {
		self.cacher = ResultCacher()
		self.fileContainer = fileContainer
		self.isTestEnvironment = isTestEnvironment
 	}
	
	
	/// Parse frameworks from "FRAMEWORK_SEARCH_PATHS" build setting.
	func parseExplicitBinaryModules() throws -> [FileParserResult] {
		TimeRecorder.start(event: .parseBinary)
		defer { TimeRecorder.end(event: .parseBinary) }
		
		let (target, sdk) = self.createCommandLineArgumentInfoForSourceKitParsing()
		let userDefinedFrameworks = try self.getUserDefinedBinaryFrameworkNames()
		
		return try self.parseFrameworkInfoList(userDefinedFrameworks, target: target, sdk: sdk, isCommon: false, explicitNames: nil)
		
	}
	
	/// Parse OS related bynary frameworks and
	func parseBinaryModules(names: Set<String>) throws -> [FileParserResult]? {
		guard !names.isEmpty else {
			return nil
		}
		let (target, sdk) = self.createCommandLineArgumentInfoForSourceKitParsing()
		let commonFrameworks = self.getImplicitlyDependentBinaryFrameworks(sdk: sdk)
		return try self.parseFrameworkInfoList(commonFrameworks, target: target, sdk: sdk, isCommon: true, explicitNames: names)
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
		let frameworkPaths = frameworkPathsString
			.split(separator: "\"")
			.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
		
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
		commonFrameworkInfoList.append(BinaryFrameworkInfo(path: commonFrameworksPath, name: "Foundation"))
		return commonFrameworkInfoList
	}
	
	
	/// Parse concrete binary framework.
	private func parseFrameworkInfoList(_ frameworkInfoList: [BinaryFrameworkInfo], target: String, sdk: String, isCommon: Bool, explicitNames: Set<String>?) throws -> [FileParserResult] {
		let templateCompilerArguments = ["-target", target, "-sdk", sdk, "-F"]
		
		return try frameworkInfoList.flatMap { (frameworkInfo) -> [FileParserResult] in
			let compilerArguments = templateCompilerArguments + [frameworkInfo.path]
			return try self.parseModule(moduleName: frameworkInfo.name,
										frameworksPath: frameworkInfo.path,
										compilerArguments: compilerArguments,
										explicitNames: explicitNames,
										isCommon: isCommon)
		}
	}
	
	/// Parse Binary framework path. Framework may be separate into several ".h" files. Method parse passed "***.h" file.
	private func parseModule(moduleName: String, frameworksPath: String, compilerArguments: [String], explicitNames: Set<String>?, isCommon: Bool) throws -> [FileParserResult] {
		let frameworksURL = URL(fileURLWithPath: frameworksPath + "/\(moduleName).framework/Headers", isDirectory: true)
		let frameworks = try self.collectFrameworkNames(frameworksURL: frameworksURL, explicitNames: explicitNames)
		return try frameworks.flatMap { (frameworkName) -> [FileParserResult] in
			print("Parse framework: \(frameworkName)")
			
			let fullFrameworkName = self.fullFrameworkName(moduleName: moduleName, frameworkName: frameworkName)
			let fileName = frameworksURL.path + "/" + fullFrameworkName + ".h"
			let cacheName = frameworksPath + moduleName + frameworkName
			
			if let cachedResult = self.cacher.getCachedBinaryFiles(name: cacheName, isCommonCache: isCommon) {
				return cachedResult
				
			} else if let contents = try? self.createSwiftSourcetext(for: fullFrameworkName, use: compilerArguments) {
				// We use "try?" here cause we should "eat" errors in swift source creating from objc
				let parser = FileParser(contents: contents, path: fileName, module: moduleName)
				let fileParserResult = try [parser.parse()]
				self.fileContainer.set(value: parser.file, for: fileName)
				self.cacher.cacheBinaryFiles(list: fileParserResult, name: cacheName, isCommonCache: isCommon)
				return fileParserResult
			}
			
			return []
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
	private func collectFrameworkNames(frameworksURL: URL, explicitNames: Set<String>?) throws -> [String] {
		do {
			let fileURLs = try FileManager.default.contentsOfDirectory(at: frameworksURL, includingPropertiesForKeys: nil)
			return fileURLs.reduce(into: []) { result, url in
				let frameworkName = url.lastPathComponent.droppedSuffix(".h")
				if url.pathExtension == "h" && (explicitNames?.contains(frameworkName) ?? true) {
					result.append(frameworkName)
				}
			}
		} catch {
			if isTestEnvironment {
				return []
			} else {
				throw error
			}
		}
	}
}
