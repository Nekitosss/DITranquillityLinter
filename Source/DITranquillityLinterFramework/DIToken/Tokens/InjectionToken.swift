//
//  InjectionToken.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 23/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation

struct InjectionToken: DIToken {
	
	let name: String
	var typeName: String {
		didSet {
			// Handle many($0) unwrapping
			let new = typeName.droppedArrayInfo()
			if typeName != new {
				typeName = new
			}
		}
	}
	var plainTypeName: String {
		didSet {
			// Handle many($0) unwrapping
			let new = typeName.droppedArrayInfo()
			if typeName != new {
				typeName = new
			}
		}
	}
	let cycle: Bool
	var optionalInjection: Bool
	let methodInjection: Bool
	let modificators: [InjectionModificator]
	let injectionSubstructureList: [SourceKitStructure]
	let location: Location
	
	func getRegistrationAccessor() -> RegistrationAccessor {
		// Select typeName if its generic. Plain typeName otherwise. TODO: Refactor and make typeName actual
		let preferredType = typeName.contains("<") ? typeName : plainTypeName
		return RegistrationAccessor(typeName: preferredType, tag: tag)
	}
	
	static func isMany(_ modificators: [InjectionModificator]) -> Bool {
		for modificator in modificators {
			switch modificator {
			case .many:
				return true
			default:
				continue
			}
		}
		return false
	}
	
	var isMany: Bool {
		return InjectionToken.isMany(modificators)
	}
	
	var tag: String {
		for modificator in modificators {
			switch modificator {
			case .tagged(let tag):
				return tag
			default:
				break
			}
		}
		return ""
	}
}
