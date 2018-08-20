//
//  SwiftType.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 20.08.2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework

final class SwiftType: Equatable {
	
	enum Kind: Equatable {
		case object
		case structure
		case interface
		case generic([SwiftType])
		case optinal(SwiftType)
		
		init?(string: String) {
			switch string {
			case SwiftDeclarationKind.class.rawValue:
				self = .object
			case SwiftDeclarationKind.enum.rawValue, SwiftDeclarationKind.struct.rawValue:
				self = .structure
			case SwiftDeclarationKind.protocol.rawValue:
				self = .interface
			default:
				return nil
			}
		}
	}
	
	let name: String
	let kind: Kind
	let inheritedTypes: [String]
	let substructure: [[String: SourceKitRepresentable]]
	
	static func ==(lhs: SwiftType, rhs: SwiftType) -> Bool {
		return lhs.name == rhs.name && lhs.kind == rhs.kind && lhs.inheritedTypes == rhs.inheritedTypes
	}
	
	init(name: String, kind: Kind, inheritedTypes: [String], substructure: [[String: SourceKitRepresentable]]) {
		self.name = name
		self.kind = kind
		self.inheritedTypes = inheritedTypes
		self.substructure = substructure
	}
}
