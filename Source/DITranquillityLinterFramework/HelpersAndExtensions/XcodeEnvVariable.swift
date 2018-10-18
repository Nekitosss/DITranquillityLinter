//
//  XcodeEnvVariable.swift
//  DITranquillityLinter
//
//  Created by Nikita Patskov on 01/10/2018.
//

public enum XcodeEnvVariable: String {
	case podsRoot = "PODS_ROOT"
	case projectFilePath = "PROJECT_FILE_PATH"
	case srcRoot = "SRCROOT"
	case sdkRoot = "SDKROOT"
	case platformPreferredArch = "PLATFORM_PREFERRED_ARCH"
	case targetPrefix = "SWIFT_PLATFORM_TARGET_PREFIX"
	case deploymentTarget = "IPHONEOS_DEPLOYMENT_TARGET"
	case frameworkSearchPaths = "FRAMEWORK_SEARCH_PATHS"
}
