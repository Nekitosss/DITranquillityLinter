//
// Created by Krzysztof Zabłocki on 25/12/2016.
// Copyright (c) 2016 Pixle. All rights reserved.
//

import Foundation

/// Descibes typed declaration, i.e. variable, method parameter, tuple element, enum case associated value
protocol Typed {

    // sourcery: skipEquality, skipDescription
    /// Type, if known
    var type: Type? { get }

    // sourcery: skipEquality, skipDescription
    /// Type name
    var typeName: TypeName { get }

    // sourcery: skipEquality, skipDescription
    /// Whether type is optional
    var isOptional: Bool { get }

    // sourcery: skipEquality, skipDescription
    /// Whether type is implicitly unwrapped optional
    var isImplicitlyUnwrappedOptional: Bool { get }

    // sourcery: skipEquality, skipDescription
    /// Type name without attributes and optional type information
    var unwrappedTypeName: String { get }
}

/// Describes name of the type used in typed declaration (variable, method parameter or return value etc.)
final class TypeName: NSObject, LosslessStringConvertible, Codable {


    /// Type name used in declaration
    let name: String

    /// The generics of this TypeName
    var generic: GenericType?

    /// Whether this TypeName is generic
    let isGeneric: Bool

    // sourcery: skipEquality
    /// Actual type name if given type name is a typealias
    var actualTypeName: TypeName?

    /// Type name attributes, i.e. `@escaping`
    let attributes: [String: Attribute]

    // sourcery: skipEquality
    /// Whether type is optional
    let isOptional: Bool

    // sourcery: skipEquality
    /// Whether type is implicitly unwrapped optional
    let isImplicitlyUnwrappedOptional: Bool

    // sourcery: skipEquality
    /// Type name without attributes and optional type information
    let unwrappedTypeName: String

	/// :nodoc:
	init(_ name: String,
		 actualTypeName: TypeName? = nil,
		 attributes: [String: Attribute] = [:],
		 tuple: TupleType? = nil,
		 array: ArrayType? = nil,
		 dictionary: DictionaryType? = nil,
		 closure: ClosureType? = nil,
		 generic: GenericType? = nil) {
		
		self.name = name
		self.actualTypeName = actualTypeName
		self.attributes = attributes
		self.tuple = tuple
		self.array = array
		self.dictionary = dictionary
		self.closure = closure
		self.generic = generic
		
		var name = name
		attributes.forEach {
			name = name.trimmingPrefix($0.value.description)
				.trimmingCharacters(in: .whitespacesAndNewlines)
		}
		
		if let genericConstraint = name.range(of: "where") {
			name = String(name.prefix(upTo: genericConstraint.lowerBound))
				.trimmingCharacters(in: .whitespacesAndNewlines)
		}
		
		(self.unwrappedTypeName, self.isImplicitlyUnwrappedOptional, self.isOptional, self.isGeneric) = TypeName.unwrapTypeName(name: name)
	}
    // sourcery: skipEquality
    /// Whether type is void (`Void` or `()`)
    var isVoid: Bool {
        return name == "Void" || name == "()" || unwrappedTypeName == "Void"
    }

    /// Whether type is a tuple
    var isTuple: Bool {
        if let actualTypeName = actualTypeName?.unwrappedTypeName {
            return actualTypeName.isValidTupleName()
        } else {
            return unwrappedTypeName.isValidTupleName()
        }
    }

    /// Tuple type data
    var tuple: TupleType?

    /// Whether type is an array
    var isArray: Bool {
        if let actualTypeName = actualTypeName?.unwrappedTypeName {
            return actualTypeName.isValidArrayName()
        } else {
            return unwrappedTypeName.isValidArrayName()
        }
    }

    /// Array type data
    var array: ArrayType?

    /// Whether type is a dictionary
    var isDictionary: Bool {
        if let actualTypeName = actualTypeName?.unwrappedTypeName {
            return actualTypeName.isValidDictionaryName()
        } else {
            return unwrappedTypeName.isValidDictionaryName()
        }
    }

    /// Dictionary type data
    var dictionary: DictionaryType?

    /// Whether type is a closure
    var isClosure: Bool {
        if let actualTypeName = actualTypeName?.unwrappedTypeName {
            return actualTypeName.isValidClosureName()
        } else {
            return unwrappedTypeName.isValidClosureName()
        }
    }

    /// Closure type data
    var closure: ClosureType?

    /// Returns value of `name` property.
    override var description: String {
        return name
    }

    // MARK: - LosslessStringConvertible

    /// :nodoc:
    convenience init(_ description: String) {
        self.init(description, actualTypeName: nil)
    }

    // sourcery: skipEquality, skipDescription
    /// :nodoc:
    override var debugDescription: String {
        return name
    }
	
	static func onlyUnwrappedName(name: String) -> String {
		return unwrapTypeName(name: name).unwrappedTypeName
	}
	
	static func onlyDroppedOptional(name: String) -> String {
		let isImplicitlyUnwrappedOptional = name.hasSuffix("!") || name.hasPrefix("ImplicitlyUnwrappedOptional<")
		let isOptional = name.hasSuffix("?") || name.hasPrefix("Optional<") || isImplicitlyUnwrappedOptional
		var unwrappedTypeName = name
		if isOptional {
			if name.hasSuffix("?") || name.hasSuffix("!") {
				unwrappedTypeName = String(name.dropLast())
			} else if name.hasPrefix("Optional<") {
				unwrappedTypeName = name.drop(first: "Optional<".count, last: 1)
			} else {
				unwrappedTypeName = name.drop(first: "ImplicitlyUnwrappedOptional<".count, last: 1)
			}
			unwrappedTypeName = unwrappedTypeName.bracketsBalancing()
		} else {
			unwrappedTypeName = name
		}
		return unwrappedTypeName
	}
	
	static func unwrapTypeName(name: String) -> (unwrappedTypeName: String, isImplicitlyUnwrappedOptional: Bool, isOptional: Bool, isGeneric: Bool) {
		var name = name
		var unwrappedTypeName: String
		var isImplicitlyUnwrappedOptional: Bool
		var isOptional: Bool
		var isGeneric: Bool
		if name.isEmpty {
			unwrappedTypeName = "Void"
			isImplicitlyUnwrappedOptional = false
			isOptional = false
			isGeneric = false
		} else {
			name = name.bracketsBalancing()
			name = name.trimmingPrefix("inout ").trimmingCharacters(in: .whitespacesAndNewlines)
			isImplicitlyUnwrappedOptional = name.hasSuffix("!") || name.hasPrefix("ImplicitlyUnwrappedOptional<")
			isOptional = name.hasSuffix("?") || name.hasPrefix("Optional<") || isImplicitlyUnwrappedOptional
			
			if isOptional {
				if name.hasSuffix("?") || name.hasSuffix("!") {
					unwrappedTypeName = String(name.dropLast())
				} else if name.hasPrefix("Optional<") {
					unwrappedTypeName = name.drop(first: "Optional<".count, last: 1)
				} else {
					unwrappedTypeName = name.drop(first: "ImplicitlyUnwrappedOptional<".count, last: 1)
				}
				unwrappedTypeName = unwrappedTypeName.bracketsBalancing()
			} else {
				unwrappedTypeName = name
			}
			
			isGeneric = (unwrappedTypeName.contains("<") && unwrappedTypeName.last == ">")
				|| unwrappedTypeName.isValidArrayName()
				|| unwrappedTypeName.isValidDictionaryName()
			
			if isGeneric {
				unwrappedTypeName = String(unwrappedTypeName.prefix(upTo: unwrappedTypeName.index(of: "<") ?? unwrappedTypeName.endIndex))
			}
		}
		return (unwrappedTypeName, isImplicitlyUnwrappedOptional, isOptional, isGeneric)
	}
}

/// Descibes Swift generic type parameter
final class GenericTypeParameter: NSObject, Codable {

    /// Generic parameter type name
    let typeName: TypeName

    // sourcery: skipEquality, skipDescription
    /// Generic parameter type, if known
    var type: Type?

    /// :nodoc:
    init(typeName: TypeName, type: Type? = nil) {
        self.typeName = typeName
        self.type = type
    }
}

/// Descibes Swift generic type
struct GenericType: Codable, Equatable {
    /// The name of the base type, i.e. `Array` for `Array<Int>`
    let name: String

    /// This generic type parameters
    let typeParameters: [GenericTypeParameter]
}

/// Describes tuple type element
final class TupleElement: NSObject, Typed, Codable {

    /// Tuple element name
    let name: String

    /// Tuple element type name
    let typeName: TypeName

    // sourcery: skipEquality, skipDescription
    /// Tuple element type, if known
    var type: Type?

    /// :nodoc:
    init(name: String = "", typeName: TypeName, type: Type? = nil) {
        self.name = name
        self.typeName = typeName
        self.type = type
    }
}

/// Describes tuple type
struct TupleType: Codable, Equatable {

    /// Type name used in declaration
    let name: String

    /// Tuple elements
    let elements: [TupleElement]
}

/// Describes array type
class ArrayType: Codable, Equatable {

    /// Type name used in declaration
    let name: String

    /// Array element type name
    let elementTypeName: TypeName
	
	/// Array element type, if known
	var elementType: Type?
	
	static func ==(lhs: ArrayType, rhs: ArrayType) -> Bool {
		return lhs.name == rhs.name && lhs.elementTypeName == rhs.elementTypeName
	}

    /// :nodoc:
    init(name: String, elementTypeName: TypeName, elementType: Type? = nil) {
        self.name = name
        self.elementTypeName = elementTypeName
        self.elementType = elementType
    }
}

/// Describes dictionary type
final class DictionaryType: NSObject, Codable {

    /// Type name used in declaration
    let name: String

    /// Dictionary value type name
    let valueTypeName: TypeName

    // sourcery: skipEquality, skipDescription
    /// Dictionary value type, if known
    var valueType: Type?

    /// Dictionary key type name
    let keyTypeName: TypeName

    // sourcery: skipEquality, skipDescription
    /// Dictionary key type, if known
    var keyType: Type?

    /// :nodoc:
    init(name: String, valueTypeName: TypeName, valueType: Type? = nil, keyTypeName: TypeName, keyType: Type? = nil) {
        self.name = name
        self.valueTypeName = valueTypeName
        self.valueType = valueType
        self.keyTypeName = keyTypeName
        self.keyType = keyType
    }
}

/// Describes closure type
final class ClosureType: NSObject, Codable {

    /// Type name used in declaration with stripped whitespaces and new lines
    let name: String

    /// List of closure parameters
    let parameters: [MethodParameter]

    /// Return value type name
    let returnTypeName: TypeName

    /// Actual return value type name if declaration uses typealias, otherwise just a `returnTypeName`
    var actualReturnTypeName: TypeName {
        return returnTypeName.actualTypeName ?? returnTypeName
    }

    // sourcery: skipEquality, skipDescription
    /// Actual return value type, if known
    var returnType: Type?

    // sourcery: skipEquality, skipDescription
    /// Whether return value type is optional
    var isOptionalReturnType: Bool {
        return returnTypeName.isOptional
    }

    // sourcery: skipEquality, skipDescription
    /// Whether return value type is implicitly unwrapped optional
    var isImplicitlyUnwrappedOptionalReturnType: Bool {
        return returnTypeName.isImplicitlyUnwrappedOptional
    }

    // sourcery: skipEquality, skipDescription
    /// Return value type name without attributes and optional type information
    var unwrappedReturnTypeName: String {
        return returnTypeName.unwrappedTypeName
    }

    /// Whether closure throws
    let `throws`: Bool

    /// :nodoc:
    init(name: String, parameters: [MethodParameter], returnTypeName: TypeName, returnType: Type? = nil, `throws`: Bool = false) {
        self.name = name
        self.parameters = parameters
        self.returnTypeName = returnTypeName
        self.returnType = returnType
        self.`throws` = `throws`
    }
}
