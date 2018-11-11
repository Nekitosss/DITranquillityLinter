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
	
	func cacheBinaryFiles(list: [FileParserResult], name: String, isCommonCache: Bool) {
		TimeRecorder.common.start(event: .encodeBinary)
		defer { TimeRecorder.common.end(event: .encodeBinary) }
		do {
			let cacheDicectoryPlace = cachePath(isCommonCache: isCommonCache)
			let cacheURLDirectory = URL(fileURLWithPath: cacheDicectoryPlace + ResultCacher.libraryCacheFolderName, isDirectory: true)
			let cacheURL = cacheURLDirectory.appendingPathComponent(cacheName(name: name))
			try FileManager.default.createDirectory(atPath: cacheURLDirectory.path, withIntermediateDirectories: true, attributes: nil)
			
			var listResult = Protobuf_FileParserResultList()
			listResult.value = list.map({ $0.toProtoMessage })
			let encodedData = try listResult.serializedData()
			
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
			let decodedDataNotUnwrapped = try Protobuf_FileParserResultList(serializedData: data).value
			TimeRecorder.common.start(event: .mapBinary)
			let decodedData = decodedDataNotUnwrapped.map { FileParserResult.fromProtoMessage($0) }
			TimeRecorder.common.end(event: .mapBinary)
			decodedData.forEach({ $0.updateRelationshipAfterDecoding() })
			return decodedData
		} catch {
			return nil
		}
	}
	
	func getCachedFileParseResult(contents: String) -> FileParserResult? {
		TimeRecorder.common.start(event: .decodeCachedSource)
		defer { TimeRecorder.common.end(event: .decodeCachedSource) }
		let cacheDicectoryPlace = cachePath(isCommonCache: false)
		let cacheURLDirectory = URL(fileURLWithPath: cacheDicectoryPlace + ResultCacher.libraryCacheFolderName, isDirectory: true)
		let cacheURL = cacheURLDirectory.appendingPathComponent(cacheName(name: contents))
		do {
			let data = try Data(contentsOf: cacheURL, options: [])
			let decodedData = try FileParserResult.fromProtoMessage(FileParserResult.ProtoStructure(serializedData: data))
//			decodedData.updateRelationshipAfterDecoding()
			return decodedData
		} catch {
			return nil
		}
	}
	
	func setCachedFileParseResult(result: FileParserResult, contents: String) {
		defer { TimeRecorder.common.end(event: .encodeBinary) }
		do {
			let cacheDicectoryPlace = cachePath(isCommonCache: false)
			let cacheURLDirectory = URL(fileURLWithPath: cacheDicectoryPlace + ResultCacher.libraryCacheFolderName, isDirectory: true)
			let cacheURL = cacheURLDirectory.appendingPathComponent(cacheName(name: contents))
			try FileManager.default.createDirectory(atPath: cacheURLDirectory.path, withIntermediateDirectories: true, attributes: nil)
			let encodedData = try result.toProtoMessage.serializedData()
			try encodedData.write(to: cacheURL)
		} catch {
			print(error)
		}
	}
	
	func cachePath(isCommonCache: Bool) -> String {
		if isCommonCache {
			return ResultCacher.commonCacheDirectory
		} else if let srcRoot = ProcessInfo.processInfo.environment[XcodeEnvVariable.srcRoot.rawValue] {
			print("SRCROOT: ", srcRoot)
			return srcRoot + "/"
		} else {
			return FileManager.default.currentDirectoryPath
		}
	}
	
	private func cacheName(name: String) -> String {
		return SHA256.get(from: name) + ".cache"
	}
	
}
