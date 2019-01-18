//
//  Dictionary+Extension.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 12.09.2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework

typealias SourceKitStructure = [String: SourceKitRepresentable]

extension Dictionary where Value == SourceKitRepresentable, Key == String {
	
	func get<T>(_ key: SwiftDocKey, of type: T.Type = T.self) -> T? {
		return self[key.rawValue] as? T
	}
	
	var substructures: [SourceKitStructure] {
		return get(.substructure) ?? []
	}
	
	func getBodyInfo() -> (offset: Int64, length: Int64)? {
		guard
			let bodyOffset: Int64 = self.get(.bodyOffset),
			let bodyLength: Int64 = self.get(.bodyLength)
			else { return nil }
		return (bodyOffset, bodyLength)
	}
	
	func getNameInfo() -> (offset: Int64, length: Int64)? {
		guard
			let nameLength: Int64 = self.get(.nameLength),
			let nameOffset: Int64 = self.get(.nameOffset)
			else { return nil }
		return (nameOffset, nameLength)
	}
	
	func isKind<Kind: RawRepresentable>(of comparingKind: Kind) -> Bool where Kind.RawValue == String {
		guard let kind: String = self.get(.kind) else {
			return false
		}
		return kind == comparingKind.rawValue
	}
	
	func nameIs<Name: RawRepresentable>(_ comparingName: Name) -> Bool where Name.RawValue == String {
		guard let name: String = self.get(.name) else {
			return false
		}
		return name == comparingName.rawValue
	}
	
	func body(using content: NSString) -> String? {
		guard let (bodyOffset, bodyLength) = self.getBodyInfo() else {
			return nil
		}
		return content.substringUsingByteRange(start: bodyOffset, length: bodyLength)
	}
	
}
