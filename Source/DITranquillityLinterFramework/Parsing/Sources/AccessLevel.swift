//
// Created by Krzysztof Zablocki on 13/09/2016.
// Copyright (c) 2016 Pixle. All rights reserved.
//

import Foundation

/// :nodoc:
enum AccessLevel: String, Codable, Equatable {
    case `internal` = "internal"
    case `private` = "private"
    case `fileprivate` = "fileprivate"
    case `public` = "public"
    case `open` = "open"
    case none = ""
	
	typealias ProtoStructure = Protobuf_AccessLevel
	
	static func fromProtoMessage(_ message: AccessLevel.ProtoStructure) -> AccessLevel {
		switch message {
		case .internal:
			return .internal
		case .private:
			return .private
		case .fileprivate:
			return .fileprivate
		case .public:
			return .public
		case .open:
			return .open
		case .UNRECOGNIZED:
			return .none
		}
	}
	
	var toProtoMessage: AccessLevel.ProtoStructure {
		switch self {
		case .internal:
			return .internal
		case .private:
			return .private
		case .fileprivate:
			return .fileprivate
		case .public:
			return .public
		case .open:
			return .open
		case .none:
			return .UNRECOGNIZED(64)
		}
	}
}

extension AccessLevel {
	var stringValue: String {
		switch self {
		case .internal:
			return "internal"
		case .private:
			return "private"
		case .fileprivate:
			return "fileprivate"
		case .public:
			return "public"
		case .open:
			return "open"
		default:
			return ""
		}
	}
	
	init(value: String) {
		switch value {
		case "internal":
			self = .internal
		case "private":
			self = .private
		case "fileprivate":
			self = .fileprivate
		case "public":
			self = .public
		case "open":
			self = .open
		default:
			self = .none
		}
	}
}
