//
//  ResultCacher.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 16/10/2018.
//

import Foundation
import SourceKittenFramework

final class ResultCacher {
	
	private static let commonCacheDirectory = "/Library/Caches/"
	private static let libraryCacheFolderName = ".ditranquillitylint/"
	
	private let encoder = JSONEncoder()
	private let decoder = JSONDecoder()
	
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
	
	func cacheBinaryFiles(list: [FileParserResult], name: String, isCommonCache: Bool) throws {
		TimeRecorder.start(event: .encodeBinary)
		defer { TimeRecorder.end(event: .encodeBinary) }
		
		var listResult = Protobuf_FileParserResultList()
		listResult.value = list.map({ $0.toProtoMessage })
		let encodedData = try listResult.serializedData()
		let (cacheDirectory, cacheFileName) = self.getCacheURL(name: name, isCommonCache: isCommonCache)
		try FileManager.default.createDirectory(atPath: cacheDirectory.path, withIntermediateDirectories: true, attributes: nil)
		try encodedData.write(to: cacheFileName)
	}
	
	func getCachedBinaryFiles(name: String, isCommonCache: Bool) throws -> [FileParserResult] {
		TimeRecorder.start(event: .decodeBinary)
		defer { TimeRecorder.end(event: .decodeBinary) }
		
		let cacheFileName = self.getCacheURL(name: name, isCommonCache: isCommonCache).fileName
		let data = try Data(contentsOf: cacheFileName, options: [])
		let decodedDataNotUnwrapped = try Protobuf_FileParserResultList(serializedData: data).value
		TimeRecorder.start(event: .mapBinary)
		let decodedData = decodedDataNotUnwrapped.map { FileParserResult.fromProtoMessage($0) }
		TimeRecorder.end(event: .mapBinary)
		decodedData.forEach({ $0.updateRelationshipAfterDecoding() })
		return decodedData
	}
	
	private func getCacheURL(name: String, isCommonCache: Bool) -> (directory: URL, fileName: URL) {
		let cacheDicectoryPlace = cachePath(isCommonCache: isCommonCache)
		let cacheDirectoryURL = URL(fileURLWithPath: cacheDicectoryPlace + ResultCacher.libraryCacheFolderName, isDirectory: true)
		let cacheFileURL = cacheDirectoryURL.appendingPathComponent(cacheName(name: name))
		return (cacheDirectoryURL, cacheFileURL)
	}
	
	private func cachePath(isCommonCache: Bool) -> String {
		if isCommonCache {
			return ResultCacher.commonCacheDirectory + ResultCacher.libraryCacheFolderName
		} else if let srcRoot = XcodeEnvVariable.srcRoot.value() {
			Log.verbose("SRCROOT: " + srcRoot)
			return srcRoot + "/"
		} else {
			return FileManager.default.currentDirectoryPath
		}
	}
	
	private func cacheName(name: String) -> String {
		return SHA256.get(from: name) + ".cache"
	}
	
}
