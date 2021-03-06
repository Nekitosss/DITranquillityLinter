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
}

public enum EnvVariable: String {
	case defaultTarget = "DI_LINTER_DEFAULT_TARGET"
	case defaultSDK = "DI_LINTER_DEFAULT_SDK"
	case currentProjectFolder = "DI_LINTER_PROJECT_FOLDER"
	case testableProjectFolder = "DI_LINTER_TESTABLE_PROJECT_FOLDER"
	case testableProjectName = "DI_LINTER_TESTABLE_PROJECT_NAME"
	
	public var defaultValue: String {
		switch self {
		case .defaultTarget:
			return "x86_64-apple-ios11.4"
		case .defaultSDK:
			return "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator12.1.sdk"
		case .testableProjectFolder:
			return "/Users/nikitapatskov/Develop/fooddly/Fooddly/"
		case .testableProjectName:
			return "Fooddly.xcodeproj"
		case .currentProjectFolder:
			return "/Users/nikita/development/DITranquillityLinter"
		}
	}
	
	public func value() -> String {
		return ProcessInfo.processInfo.environment[rawValue] ?? defaultValue
	}
}
