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
	
	func cacheBinaryFiles(list: [FileParserResult], name: String) {
		do {
			let cacheURLDirectory = URL(fileURLWithPath: ResultCacher.commonCacheDirectory + ResultCacher.libraryCacheFolderName, isDirectory: true)
			let cacheURL = cacheURLDirectory.appendingPathComponent(cacheName(name: name))
			try FileManager.default.createDirectory(atPath: cacheURLDirectory.path, withIntermediateDirectories: true, attributes: nil)
			let encodedData = try encoder.encode(list)
			try encodedData.write(to: cacheURL)
		} catch {
			print(error)
			exit(EXIT_FAILURE)
		}
	}
	
	func getCachedBinaryFiles(name: String) -> [FileParserResult]? {
		let cacheURLDirectory = URL(fileURLWithPath: ResultCacher.commonCacheDirectory + ResultCacher.libraryCacheFolderName, isDirectory: true)
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
	
	private func cacheName(name: String) -> String {
		return SHA256.get(from: name) + ".cache"
	}
	
}
