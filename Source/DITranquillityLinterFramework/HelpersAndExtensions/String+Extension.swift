//
//  String+Extension.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 12.09.2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation

extension NSString {
}

extension String {
	func firstMatch(_ regExp: RegExp) -> String? {
		return firstMatch(regExp.rawValue)
	}
	
	func firstMatch(_ pattern: String) -> String? {
		return listMatches(pattern).first
	}
	
	func listMatches(_ pattern: String) -> [String] {
		do {
			let regex = try NSRegularExpression(pattern: pattern, options: [])
			let range = NSRange(location: 0, length: self.count)
			let matches = regex.matches(in: self, options: [], range: range)
			
			return matches.map {
				let range = $0.range
				return (self as NSString).substring(with: range)
			}
		} catch {
			return []
		}
	}
	
	func droppedDotInit() -> String {
		return droppedSuffix(".init")
	}
	
	func droppedArrayInfo() -> String {
		if hasPrefix("Array<") {
			return drop(first: 6, last: 1)
		} else if hasPrefix("[") {
			return dropFirstAndLast()
		} else {
			return self
		}
	}
	
	func droppedDotSelf() -> String {
		return droppedSuffix(".self")
	}
	
	func droppedDotType() -> String {
		return droppedSuffix(".Type")
	}
	
	func droppedDotProtocol() -> String {
		return droppedSuffix(".Protocol")
	}
	
	func droppedSuffix(_ suffix: String) -> String {
		return self.hasSuffix(suffix) ? String(self.dropLast(suffix.count)) : self
	}
}
