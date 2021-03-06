//
//  String+Extension.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 12.09.2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension NSString {
	func substringUsingByteRange(start: Int64, length: Int64) -> String? {
		return self.substringWithByteRange(start: Int(start), length: Int(length))
	}
}

extension String {
	func firstMatch(_ regExp: RegExp) -> String? {
		return firstMatch(regExp.rawValue)
	}
	
	func firstMatch(_ pattern: String) -> String? {
		return listMatches(pattern).first
	}
	
	func listMatches(_ pattern: String) -> [String] {
		let regex = try! NSRegularExpression(pattern: pattern, options: [])
		let range = NSMakeRange(0, self.count)
		let matches = regex.matches(in: self, options: [], range: range)
		
		return matches.map {
			let range = $0.range
			return (self as NSString).substring(with: range)
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
	
	func droppedSuffix(_ suffix: String) -> String {
		return self.hasSuffix(suffix) ? String(self.dropLast(suffix.count)) : self
	}
}
