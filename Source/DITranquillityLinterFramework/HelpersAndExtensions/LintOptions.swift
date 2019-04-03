//
//  LintOptions.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 18/01/2019.
//

public struct LintOptions {
	
	public static var shared = LintOptions(logLevel: Log.Level.info.rawValue, commonCachePath: "/Library/Caches/", localCachePath: "./.ditranquillitylint/", shouldRecordTime: false, outputPath: nil)
	
	let logLevel: Log.Level
	let commonCachePath: String
	let localCachePath: String
	let shouldRecordTime: Bool
	let outputPath: String?
	
	public init(logLevel: String?, commonCachePath: String?, localCachePath: String?, shouldRecordTime: Bool, outputPath: String?) {
		self.logLevel = logLevel.flatMap(Log.Level.init(rawValue:)) ?? .warnings
		self.commonCachePath = commonCachePath ?? "/Library/Caches/"
		self.localCachePath = localCachePath ?? "./.ditranquillitylint/"
		self.shouldRecordTime = shouldRecordTime
		self.outputPath = outputPath
	}
}
