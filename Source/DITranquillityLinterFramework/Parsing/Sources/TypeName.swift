//
// Created by Krzysztof Zabłocki on 25/12/2016.
// Copyright (c) 2016 Pixle. All rights reserved.
//

import Foundation

/// Describes name of the type used in typed declaration (variable, method parameter or return value etc.)
final class TypeName: Codable {
  
    /// Type name used in declaration
    let name: String

    /// The generics of this TypeName
    var generic: GenericType?

    /// Whether this TypeName is generic
    let isGeneric: Bool

    // sourcery: skipEquality
    /// Actual type name if given type name is a typealias
    var actualTypeName: TypeName?

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
     generic: GenericType? = nil) {
    
    var name = name
    self.generic = generic
    
    if let genericConstraint = name.range(of: "where") {
      name = String(name.prefix(upTo: genericConstraint.lowerBound))
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    self.name = name
    (self.unwrappedTypeName, self.isImplicitlyUnwrappedOptional, self.isOptional, self.isGeneric) = TypeName.unwrapTypeName(name: name)
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
				unwrappedTypeName = String(unwrappedTypeName.prefix(upTo: unwrappedTypeName.firstIndex(of: "<") ?? unwrappedTypeName.endIndex))
			}
		}
		return (unwrappedTypeName, isImplicitlyUnwrappedOptional, isOptional, isGeneric)
	}
}
