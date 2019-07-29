//
//  DIToken.swift
//  DITranquillityLinter
//
//  Created by Nikita on 08/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation

protocol DITokenConvertible {
	var diTokenValue: DIToken { get }
}

extension AliasToken: DITokenConvertible {
	var diTokenValue: DIToken { return .alias(self) }
}

extension AppendContainerToken: DITokenConvertible {
	var diTokenValue: DIToken { return .append(self) }
}

extension FutureAppendContainerToken: DITokenConvertible {
	var diTokenValue: DIToken { return .futureAppend(self) }
}

extension InjectionToken: DITokenConvertible {
	var diTokenValue: DIToken { return .injection(self) }
}

extension IsDefaultToken: DITokenConvertible {
	var diTokenValue: DIToken { return .isDefault(self) }
}

extension RegistrationToken: DITokenConvertible {
	var diTokenValue: DIToken { return .registration(self) }
}

enum DIToken: Codable {
	case alias(AliasToken)
	case append(AppendContainerToken)
	case injection(InjectionToken)
	case isDefault(IsDefaultToken)
	case registration(RegistrationToken)
	case futureAppend(FutureAppendContainerToken)
	
	/// For example, AliasToken could be only part of RegistrationToken.
	/// Currently, RegistrationToken, AppendContainerToken and FutureAppendContainerToken are independent, all others are intermediate.
	/// Intermediate tokens could not exists without independent tokens.
	/// AliasToken could not exests without referenced RegistrationToken
	var isIntermediate: Bool {
		switch self {
		case .registration, .append, .futureAppend:
			return false
		default:
			return true
		}
	}
	
	var underlyingValue: DITokenConvertible {
		switch self {
		case .alias(let token):
			return token
		case .append(let token):
			return token
		case .injection(let token):
			return token
		case .isDefault(let token):
			return token
		case .registration(let token):
			return token
		case .futureAppend(let token):
			return token
		}
	}
	
	
	private enum CodingKeys: String, CodingKey {
		case alias
		case append
		case injection
		case isDefault
		case registration
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case .alias(let token):
			try container.encode(token, forKey: .alias)
		case .append(let token):
			try container.encode(token, forKey: .append)
		case .injection(let token):
			try container.encode(token, forKey: .injection)
		case .isDefault(let token):
			try container.encode(token, forKey: .isDefault)
		case .registration(let token):
			try container.encode(token, forKey: .registration)
		case .futureAppend(let token):
			let context = EncodingError.Context.init(codingPath: container.codingPath, debugDescription: "We should not encode FutureDIToken. It should be translated to plain AppendContainerToken.")
			throw EncodingError.invalidValue(token, context)
		}
	}
	
	
	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		if let value = try? values.decode(AliasToken.self, forKey: .alias) {
			self = .alias(value)
		} else if let value = try? values.decode(AppendContainerToken.self, forKey: .append) {
			self = .append(value)
		} else if let value = try? values.decode(InjectionToken.self, forKey: .injection) {
			self = .injection(value)
		} else if let value = try? values.decode(IsDefaultToken.self, forKey: .isDefault) {
			self = .isDefault(value)
		} else if let value = try? values.decode(RegistrationToken.self, forKey: .registration) {
			self = .registration(value)
		} else {
			let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Could not decode modificator")
			throw DecodingError.valueNotFound(String.self, context)
		}
	}
	
	
}
