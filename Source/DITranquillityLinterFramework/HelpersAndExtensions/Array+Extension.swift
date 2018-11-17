//
//  Array+Extension.swift
//  AEXML
//
//  Created by Nikita Patskov on 06/11/2018.
//

import Foundation

extension Array {
	
	func parallelFlatMap<T>(_ transform: ((Element) throws -> T?)) rethrows -> [T] {
		return try parallelMap(transform).compactMap { $0 }
	}
	
	func parallelFlatMap<T>(_ transform: (Element) throws -> [T]) rethrows -> [T] {
		return try parallelMap(transform).flatMap { $0 }
	}
	
	func parallelMap<T>(_ transform: (Element) throws -> T) rethrows -> [T] {
		var result = ContiguousArray<T?>(repeating: nil, count: count)
		return try result.withUnsafeMutableBufferPointer { buffer in
			var anError: Error?
			DispatchQueue.concurrentPerform(iterations: buffer.count) { idx in
				do {
					buffer[idx] = try transform(self[idx])
				} catch {
					anError = error
				}
			}
			if let error = anError {
				throw error
			}
			return buffer.map { $0! }
		}
	}
}
