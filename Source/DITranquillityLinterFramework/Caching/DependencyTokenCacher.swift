//
//  DependencyTokenCacher.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 03/04/2019.
//

import Foundation

final class DependencyTokenCacher {
	
	private let encoder: JSONEncoder
	private let decoder: JSONDecoder
	
	init(encoder: JSONEncoder, decoder: JSONDecoder) {
		self.encoder = encoder
		self.decoder = decoder
	}
	
	func cache(partList: [ContainerPart], outputFilePath: URL) throws {
		let encodedData = try encoder.encode(partList)
		try encodedData.write(to: outputFilePath)
	}
	
	func getCachedPartList(from fileURL: URL) throws -> [ContainerPart] {
		do {
			let data = try Data(contentsOf: fileURL, options: [])
			let decodedContainerInfo = try decoder.decode([ContainerPart].self, from: data)
			return decodedContainerInfo
		} catch let error as DecodingError {
			throw error
		} catch {
			return []
		}
	}
}
