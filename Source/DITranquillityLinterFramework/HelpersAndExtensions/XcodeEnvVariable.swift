//
//  XcodeEnvVariable.swift
//  DITranquillityLinter
//
//  Created by Nikita Patskov on 01/10/2018.
//

import Foundation

public enum XcodeEnvVariable: String {
	case podsRoot = "PODS_ROOT"
	case projectFilePath = "PROJECT_FILE_PATH"
	case srcRoot = "SRCROOT"
	case sdkRoot = "SDKROOT"
	case platformPreferredArch = "PLATFORM_PREFERRED_ARCH"
	case targetPrefix = "SWIFT_PLATFORM_TARGET_PREFIX"
	case deploymentTarget = "IPHONEOS_DEPLOYMENT_TARGET"
	case frameworkSearchPaths = "FRAMEWORK_SEARCH_PATHS"
	case productName = "PRODUCT_NAME"
	
	public func value() -> String? {
		return ProcessInfo.processInfo.environment[self.rawValue]
	}
	
	public var defaultValue: String {
		switch self {
		case .srcRoot:
			return EnvVariable.testableProjectFolder.value()
		case .projectFilePath:
			return EnvVariable.testableProjectFolder.value() + EnvVariable.testableProjectName.value()
		default:
			return ""
		}
	}
}

public enum EnvVariable: String {
	case defaultTarget = "DI_LINTER_DEFAULT_TARGET"
	case defaultSDK = "DI_LINTER_DEFAULT_SDK"
	case testableProjectFolder = "DI_LINTER_TESTABLE_PROJECT_FOLDER"
	case testableProjectName = "DI_LINTER_TESTABLE_PROJECT_NAME"
	
	public var defaultValue: String {
		switch self {
		case .defaultTarget:
			return "x86_64-apple-macosx10.10"
		case .defaultSDK:
			let commandLineToolsPath = shell(command: "xcode-select -p")?.trimmingCharacters(in: .whitespacesAndNewlines)
				?? "/Applications/Xcode.app/Contents/Developer"
			return commandLineToolsPath + "/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
		case .testableProjectFolder:
			return "/Users/nikitapatskov/Develop/fooddly/Fooddly/"
		case .testableProjectName:
			return "Fooddly.xcodeproj"
		}
	}
	
	public func value() -> String {
		return ProcessInfo.processInfo.environment[rawValue] ?? defaultValue
	}
}
