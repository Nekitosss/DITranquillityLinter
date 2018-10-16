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
	
	private func cacheName(name: String) -> String {
		return "\(abs(name.hashValue))" + ".cache"
	}
	
}
