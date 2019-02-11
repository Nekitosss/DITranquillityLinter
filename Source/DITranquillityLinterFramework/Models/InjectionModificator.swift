//
//  InjectionModificator.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 10/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

enum InjectionModificator {
	case tagged(String)
	case typed(String)
	case many
	
	
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
	
	static func forcedType(_ modificators: [InjectionModificator]) -> String? {
		for modificator in modificators {
			switch modificator {
			case .typed(let forcedType):
				return forcedType
			default:
				continue
			}
		}
		return nil
	}
	
	private enum CodingKeys: String, CodingKey {
		case tagged
		case typed
		case many
	}
	
	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		if let value = try? values.decode(String.self, forKey: .tagged) {
			self = .tagged(value)
		} else if let value = try? values.decode(String.self, forKey: .typed) {
			self = .typed(value)
		} else if (try? values.decode(String.self, forKey: .many)) != nil {
			self = .many
		} else {
			let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Could not decode modificator")
			throw DecodingError.valueNotFound(String.self, context)
		}
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case .tagged(let tag):
			try container.encode(tag, forKey: .tagged)
		case .typed(let type):
			try container.encode(type, forKey: .typed)
		case .many:
			try container.encode("", forKey: .many)
		}
	}
	
}
