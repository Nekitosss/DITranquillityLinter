//
//  TypeComposition.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 06/10/2018.
//

import Foundation
import SourceKittenFramework

// sourcery: skipDescription
/// Descibes Swift class
@objc(TypeComposition) @objcMembers final class TypeComposition: Type {
	/// Returns "class"
	override var kind: String { return "composed" }
	
	
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
	
	// sourcery:inline:Class.AutoCoding
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
