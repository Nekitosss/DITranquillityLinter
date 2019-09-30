//
//  ResultCacher.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 16/10/2018.
//

import Foundation

final class ResultCacher {
	
	static let localCacheDefaultPostfix = "/.ditranquillitylint"
	
	private var commonCacheDirectory: String { return LintOptions.shared.commonCachePath }
	private var libraryCacheFolderName: String { return LintOptions.shared.localCachePath }
	
	private let encoder: JSONEncoder
	private let decoder: JSONDecoder
	private let timeRecorder: TimeRecorder

	init(encoder: JSONEncoder, decoder: JSONDecoder, timeRecorder: TimeRecorder) {
		self.encoder = encoder
		self.decoder = decoder
		self.timeRecorder = timeRecorder
	}
	
	func clearCaches(isCommonCache: Bool) throws {
		let cachePath = self.cachePath(isCommonCache: isCommonCache)
		do {
			try FileManager.default.removeItem(atPath: cachePath)
		} catch {
			if isNoSuchFileOrDirectoryError(error) {
				return
			} else {
				throw error
			}
		}
	}
	
	private func isNoSuchFileOrDirectoryError(_ error: Error) -> Bool {
		if let underlyingError = (error as NSError).userInfo["NSUnderlyingError"] as? NSError,
			underlyingError.domain == "NSPOSIXErrorDomain",
			underlyingError.code == 2 {
			return true
		}
		return false
	}
  
  func saveFiles<T: Encodable>(data: T, fileName: String, isCommonCache: Bool) throws -> URL {
    let encodedData = try encoder.encode(data)
    
    let cacheDirectory = URL(fileURLWithPath: cachePath(isCommonCache: isCommonCache))
    let cachePath = cacheDirectory.appendingPathComponent(fileName)
    
    try FileManager.default.createDirectory(atPath: cacheDirectory.path, withIntermediateDirectories: true, attributes: nil)
    try encodedData.write(to: cachePath)
    return cachePath
  }
	
	private func getCacheURL(name: String, isCommonCache: Bool) -> (directory: URL, fileName: URL) {
		let cacheDicectoryPlace = cachePath(isCommonCache: isCommonCache)
		let cacheDirectoryURL = URL(fileURLWithPath: cacheDicectoryPlace + libraryCacheFolderName, isDirectory: true)
		let cacheFileURL = cacheDirectoryURL.appendingPathComponent(cacheName(name: name))
		return (cacheDirectoryURL, cacheFileURL)
	}
	
	func cachePath(isCommonCache: Bool) -> String {
		if isCommonCache {
			return commonCacheDirectory + libraryCacheFolderName
		} else if let srcRoot = XcodeEnvVariable.srcRoot.value() {
			Log.verbose("SRCROOT: " + srcRoot)
			return "\(srcRoot)/\(libraryCacheFolderName)"
		} else {
			return FileManager.default.currentDirectoryPath + ResultCacher.localCacheDefaultPostfix + "/"
		}
	}
	
	private func cacheName(name: String) -> String {
		return SHA256.get(from: name) + ".cache"
	}
	
}
