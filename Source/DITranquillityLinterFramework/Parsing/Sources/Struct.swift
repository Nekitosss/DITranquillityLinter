//
//  Struct.swift
//  Sourcery
//
//  Created by Krzysztof Zablocki on 13/09/2016.
//  Copyright © 2016 Pixle. All rights reserved.
//

import Foundation
import SourceKittenFramework

// sourcery: skipDescription
/// Describes Swift struct
final class Struct: Type {

	override func isEqual(_ object: Any?) -> Bool {
		guard let rhs = object as? Struct else { return false }
		return super.isEqual(rhs)
	}
	
    /// Returns "struct"
    override var kind: String { return "struct" }

    /// :nodoc:
    override init(name: String = "",
                         parent: Type? = nil,
                         accessLevel: AccessLevel = .internal,
                         isExtension: Bool = false,
                         variables: [Variable] = [],
                         methods: [Method] = [],
                         subscripts: [Subscript] = [],
                         inheritedTypes: [String] = [],
                         containedTypes: [Type] = [],
                         typealiases: [Typealias] = [],
                         attributes: [String: Attribute] = [:],
                         annotations: Annotations = [:],
                         isGeneric: Bool = false,
						 genericTypeParameters: [GenericTypeParameter] = [],
						 filePath: String) {
        super.init(
            name: name,
            parent: parent,
            accessLevel: accessLevel,
            isExtension: isExtension,
            variables: variables,
            methods: methods,
            subscripts: subscripts,
            inheritedTypes: inheritedTypes,
            containedTypes: containedTypes,
            typealiases: typealiases,
            annotations: annotations,
            isGeneric: isGeneric,
			genericTypeParameters: genericTypeParameters,
			filePath: filePath
        )
    }
	
	required init(from decoder: Decoder) throws {
		try super.init(from: decoder)
	}
	
	override func encode(to encoder: Encoder) throws {
		try super.encode(to: encoder)
	}
}
