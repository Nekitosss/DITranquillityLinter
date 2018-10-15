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
@objcMembers final class Struct: Type {

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
						 file: File) {
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
			file: file
        )
    }

    // sourcery:inline:Struct.AutoCoding
        /// :nodoc:
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }

        /// :nodoc:
        override func encode(with aCoder: NSCoder) {
            super.encode(with: aCoder)
        }
        // sourcery:end
}
