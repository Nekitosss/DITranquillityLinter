//
//  Protocol.swift
//  Sourcery
//
//  Created by Krzysztof Zablocki on 09/12/2016.
//  Copyright © 2016 Pixle. All rights reserved.
//

import Foundation
import SourceKittenFramework

/// Describes Swift protocol
final class Protocol: Type {

	override func isEqual(_ object: Any?) -> Bool {
		guard let rhs = object as? Protocol else { return false }
		return super.isEqual(rhs)
	}
	
    /// Returns "protocol"
    override var kind: String { return "protocol" }
	
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

    /// :nodoc:
    override func extend(_ type: Type) {
        type.variables = type.variables.filter({ variable in
			!variables.contains(where: { $0.name == variable.name && $0.isStatic == variable.isStatic })
		})
        type.methods = type.methods.filter({ !methods.contains($0) })
        super.extend(type)
    }

}
