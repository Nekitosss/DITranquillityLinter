//
//  BinaryFrameworkParser.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 22/11/2018.
//

import Foundation

struct BinaryFrameworkInfo {
  let path: String
  let name: String
  
  static let banryFrameworkPathExtension = "framework"
}

final class BinaryFrameworkParser {
	
	private let cacher: ResultCacher
	private let isTestEnvironment: Bool
	private let timeRecorder: TimeRecorder
	private let dependencyCacher: DependencyTokenCacher
	
	init(timeRecorder: TimeRecorder, cacher: ResultCacher, isTestEnvironment: Bool, dependencyCacher: DependencyTokenCacher) {
		self.cacher = cacher
		self.isTestEnvironment = isTestEnvironment
		self.timeRecorder = timeRecorder
		self.dependencyCacher = dependencyCacher
 	}
	
	func parseCachedInfoInExplicitBinaryModules() throws -> [String: ContainerPart] {
		timeRecorder.start(event: .parseCachedContainers)
		defer { timeRecorder.end(event: .parseCachedContainers) }
		
		let userDefinedFrameworks = try self.getUserDefinedBinaryFrameworkNames()
		return self.collectCachedContainerPartsFromBinaryModules(userDefinedFrameworks)
	}
	
	func createCommandLineArgumentInfoForSourceParsing() -> (target: String, sdk: String) {
		var target = EnvVariable.defaultTarget.value()
		var sdk = EnvVariable.defaultSDK.value()
		
		if let arch = XcodeEnvVariable.platformPreferredArch.value(),
			let targetPrefix = XcodeEnvVariable.targetPrefix.value(),
			let deploymentTarget = XcodeEnvVariable.deploymentTarget.value() {
			//		"${PLATFORM_PREFERRED_ARCH}-apple-${SWIFT_PLATFORM_TARGET_PREFIX}${IPHONEOS_DEPLOYMENT_TARGET}"
			target = "\(arch)-apple-\(targetPrefix)\(deploymentTarget)"
			Log.info("Found environment info.")
		} else {
			Log.info("Environment info not found. Will be used default")
		}
		if let sdkRoot = XcodeEnvVariable.sdkRoot.value() {
			sdk = sdkRoot
		}
		return (target, sdk)
	}
	
	
	/// Parse user defined binary frameworks (Carthage + Cooapods-created)
	func getUserDefinedBinaryFrameworkNames() throws -> [BinaryFrameworkInfo] {
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
	
	private func collectCachedContainerPartsFromBinaryModules(_ frameworkInfoList: [BinaryFrameworkInfo]) -> [String: ContainerPart] {
		var result: [String: ContainerPart] = [:]
		for frameworkInfo in frameworkInfoList {
			guard let url = URL(string: frameworkInfo.path)?.appendingPathExtension(".dilintemitted.lintcache") else {
				continue
			}
			for part in self.dependencyCacher.getCachedPartList(from: url) {
				guard let name = part.name else {
					continue
				}
				result[name] = part
			}
		}
		return result
	}
	
	/// Concatenate framework part with framework name for SourceKit parser.
	private func fullFrameworkName(moduleName: String, frameworkName: String) -> String {
		return moduleName == frameworkName ? frameworkName : moduleName + "." + frameworkName
	}
	
	
	/// Collects all framework parts ("*.h" files).
	private func collectFrameworkNames(frameworksURL: URL, explicitNames: Set<String>?) throws -> [String] {
		do {
			let fileURLs = try FileManager.default.contentsOfDirectory(atPath: frameworksURL.path).compactMap(URL.init)
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
