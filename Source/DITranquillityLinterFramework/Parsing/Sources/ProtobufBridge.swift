//
//  ProtobufBridge.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 11/11/2018.
//

import Foundation
import SwiftProtobuf

protocol ProtobufBridgable {
	associatedtype ProtoStructure: Message
	
	var toProtoMessage: ProtoStructure { get }
	
	static func fromProtoMessage(_ message: ProtoStructure) -> Self
}

protocol ProtobufNullable {
	
	associatedtype ActualValue
	
	var toValue: ActualValue? { get }
	init(value: ActualValue?)
}

extension Protobuf_StructureWrapper: ProtobufNullable {
	
	var toValue: Protobuf_Structure? {
		switch self.value ?? .none(.init()) {
		case .none:
			return nil
		case .some(let value):
			return value
		}
	}
	
	init(value: Protobuf_Structure?) {
		switch value {
		case .some(let value):
			self.value = Protobuf_StructureWrapper.OneOf_Value.some(value)
		case .none:
			self.value = Protobuf_StructureWrapper.OneOf_Value.none(.init())
		}
	}
}

extension Protobuf_GenericTypeWrapper: ProtobufNullable {
	
	var toValue: Protobuf_GenericType? {
		switch self.value ?? .none(.init()) {
		case .none:
			return nil
		case .some(let value):
			return value
		}
	}
	
	init(value: Protobuf_GenericType?) {
		switch value {
		case .some(let value):
			self.value = Protobuf_GenericTypeWrapper.OneOf_Value.some(value)
		case .none:
			self.value = Protobuf_GenericTypeWrapper.OneOf_Value.none(.init())
		}
	}
}

extension Protobuf_TypeNameWrapper: ProtobufNullable {
	
	var toValue: Protobuf_TypeName? {
		switch self.value ?? .none(.init()) {
		case .none:
			return nil
		case .some(let value):
			return value
		}
	}
	
	init(value: Protobuf_TypeName?) {
		switch value {
		case .some(let value):
			self.value = Protobuf_TypeNameWrapper.OneOf_Value.some(value)
		case .none:
			self.value = Protobuf_TypeNameWrapper.OneOf_Value.none(.init())
		}
	}
}


extension Protobuf_TypeWrapper: ProtobufNullable {
	
	var toValue: Protobuf_Type? {
		switch self.value ?? .none(.init()) {
		case .none:
			return nil
		case .some(let value):
			return value
		}
	}
	
	init(value: Protobuf_Type?) {
		switch value {
		case .some(let value):
			self.value = Protobuf_TypeWrapper.OneOf_Value.some(value)
		case .none:
			self.value = Protobuf_TypeWrapper.OneOf_Value.none(.init())
		}
	}
}


extension Protobuf_TupleTypeWrapper: ProtobufNullable {
	
	var toValue: Protobuf_TupleType? {
		switch self.value ?? .none(.init()) {
		case .none:
			return nil
		case .some(let value):
			return value
		}
	}
	
	init(value: Protobuf_TupleType?) {
		switch value {
		case .some(let value):
			self.value = Protobuf_TupleTypeWrapper.OneOf_Value.some(value)
		case .none:
			self.value = Protobuf_TupleTypeWrapper.OneOf_Value.none(.init())
		}
	}
}


extension Protobuf_ArrayTypeWrapper: ProtobufNullable {
	
	var toValue: Protobuf_ArrayType? {
		switch self.value ?? .none(.init()) {
		case .none:
			return nil
		case .some(let value):
			return value
		}
	}
	
	init(value: Protobuf_ArrayType?) {
		switch value {
		case .some(let value):
			self.value = Protobuf_ArrayTypeWrapper.OneOf_Value.some(value)
		case .none:
			self.value = Protobuf_ArrayTypeWrapper.OneOf_Value.none(.init())
		}
	}
}


extension Protobuf_DictionaryTypeWrapper: ProtobufNullable {
	
	var toValue: Protobuf_DictionaryType? {
		switch self.value ?? .none(.init()) {
		case .none:
			return nil
		case .some(let value):
			return value
		}
	}
	
	init(value: Protobuf_DictionaryType?) {
		switch value {
		case .some(let value):
			self.value = Protobuf_DictionaryTypeWrapper.OneOf_Value.some(value)
		case .none:
			self.value = Protobuf_DictionaryTypeWrapper.OneOf_Value.none(.init())
		}
	}
}



extension Protobuf_ClosureTypeWrapper: ProtobufNullable {
	
	var toValue: Protobuf_ClosureType? {
		switch self.value ?? .none(.init()) {
		case .none:
			return nil
		case .some(let value):
			return value
		}
	}
	
	init(value: Protobuf_ClosureType?) {
		switch value {
		case .some(let value):
			self.value = Protobuf_ClosureTypeWrapper.OneOf_Value.some(value)
		case .none:
			self.value = Protobuf_ClosureTypeWrapper.OneOf_Value.none(.init())
		}
	}
}



extension Protobuf_StringWrapper: ProtobufNullable {
	
	var toValue: String? {
		switch self.value ?? .none(.init()) {
		case .none:
			return nil
		case .some(let value):
			return value
		}
	}
	
	init(value: String?) {
		switch value {
		case .some(let value):
			self.value = Protobuf_StringWrapper.OneOf_Value.some(value)
		case .none:
			self.value = Protobuf_StringWrapper.OneOf_Value.none(.init())
		}
	}
}
