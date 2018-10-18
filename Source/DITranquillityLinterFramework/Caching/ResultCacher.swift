//
//  ResultCacher.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 16/10/2018.
//

import Foundation

final class ResultCacher {
	
	private static let commonCacheDirectory = "/Library/Caches/"
	private static let libraryCacheFolderName = ".ditranquillitylint/"
	
	private let encoder = JSONEncoder()
	private let decoder = JSONDecoder()
	
	func cacheBinaryFiles(list: [FileParserResult], name: String, isCommonCache: Bool) {
		TimeRecorder.common.start(event: .encodeBinary)
		defer { TimeRecorder.common.end(event: .encodeBinary) }
		do {
			let cacheDicectoryPlace = cachePath(isCommonCache: isCommonCache)
			let cacheURLDirectory = URL(fileURLWithPath: cacheDicectoryPlace + ResultCacher.libraryCacheFolderName, isDirectory: true)
			let cacheURL = cacheURLDirectory.appendingPathComponent(cacheName(name: name))
			try FileManager.default.createDirectory(atPath: cacheURLDirectory.path, withIntermediateDirectories: true, attributes: nil)
			let encodedData = try encoder.encode(list)
			try encodedData.write(to: cacheURL)
		} catch {
			print(error)
			exit(EXIT_FAILURE)
		}
	}
	
	func getCachedBinaryFiles(name: String, isCommonCache: Bool) -> [FileParserResult]? {
		TimeRecorder.common.start(event: .decodeBinary)
		defer { TimeRecorder.common.end(event: .decodeBinary) }
		
		let cacheDicectoryPlace = cachePath(isCommonCache: isCommonCache)
		let cacheURLDirectory = URL(fileURLWithPath: cacheDicectoryPlace + ResultCacher.libraryCacheFolderName, isDirectory: true)
		let cacheURL = cacheURLDirectory.appendingPathComponent(cacheName(name: name))
		do {
			let data = try Data(contentsOf: cacheURL, options: [])
			let decodedData = try decoder.decode([FileParserResult].self, from: data)
			decodedData.forEach({ $0.updateRelationshipAfterDecoding() })
			return decodedData
		} catch {
			return nil
		}
	}
	
	func cachePath(isCommonCache: Bool) -> String {
		if isCommonCache {
			return ResultCacher.commonCacheDirectory
		} else if let srcRoot = ProcessInfo.processInfo.environment[XcodeEnvVariable.srcRoot.rawValue] {
			return srcRoot
		} else {
			return FileManager.default.currentDirectoryPath
		}
	}
	
	private func cacheName(name: String) -> String {
		return SHA256.get(from: name) + ".cache"
	}
	
}
