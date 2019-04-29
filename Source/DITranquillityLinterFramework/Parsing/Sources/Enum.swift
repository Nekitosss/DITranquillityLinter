//
// Created by Krzysztof Zablocki on 13/09/2016.
// Copyright (c) 2016 Pixle. All rights reserved.
//

import Foundation
import SourceKittenFramework

/// Defines enum case associated value
final class AssociatedValue: NSObject, Typed, Annotated, Codable {

    /// Associated value local name.
    /// This is a name to be used to construct enum case value
    let localName: String?

    /// Associated value external name.
    /// This is a name to be used to access value in value-bindig
    let externalName: String?

    /// Associated value type name
    let typeName: TypeName

    // sourcery: skipEquality, skipDescription
    /// Associated value type, if known
    var type: Type?

    /// Annotations, that were created with // sourcery: annotation1, other = "annotation value", alterantive = 2
    var annotations: Annotations = [:]

    /// :nodoc:
    init(localName: String?, externalName: String?, typeName: TypeName, type: Type? = nil, annotations: Annotations = [:]) {
        self.localName = localName
        self.externalName = externalName
        self.typeName = typeName
        self.type = type
        self.annotations = annotations
    }

    convenience init(name: String? = nil, typeName: TypeName, type: Type? = nil, annotations: Annotations = [:]) {
        self.init(localName: name, externalName: name, typeName: typeName, type: type, annotations: annotations)
    }

}

/// Defines enum case
final class EnumCase: NSObject, Annotated, Codable {

    /// Enum case name
    let name: String

    /// Enum case raw value, if any
    let rawValue: String?

    /// Enum case associated values
    let associatedValues: [AssociatedValue]

    /// Enum case annotations
    var annotations: Annotations = [:]

    /// Whether enum case has associated value
    var hasAssociatedValue: Bool {
        return !associatedValues.isEmpty
    }

    // Underlying parser data, never to be used by anything else
    // sourcery: skipEquality, skipDescription, skipCoding, skipJSExport
    /// :nodoc:
    var parserData: Structure?

    /// :nodoc:
    init(name: String, rawValue: String? = nil, associatedValues: [AssociatedValue] = [], annotations: Annotations = [:]) {
        self.name = name
        self.rawValue = rawValue
        self.associatedValues = associatedValues
        self.annotations = annotations
    }

}

/// Defines Swift enum
final class Enum: Type {

	override func isEqual(_ object: Any?) -> Bool {
		guard let rhs = object as? Enum else { return false }
		if self.cases != rhs.cases { return false }
		if self.rawTypeName != rhs.rawTypeName { return false }
		return super.isEqual(rhs)
	}
	
    // sourcery: skipDescription
    /// Returns "enum"
    override var kind: String { return "enum" }

    /// Enum cases
    var cases: [EnumCase]

    /// Enum raw value type name, if any
    var rawTypeName: TypeName? {
        didSet {
            if let rawTypeName = rawTypeName {
                hasRawType = true
                if let index = inheritedTypes.firstIndex(of: rawTypeName.name) {
                    inheritedTypes.remove(at: index)
                }
                if based[rawTypeName.name] != nil {
                    based[rawTypeName.name] = nil
                }
            }
        }
    }

    // sourcery: skipDescription, skipEquality
    /// :nodoc:
    private(set) var hasRawType: Bool

    // sourcery: skipDescription, skipEquality
    /// Enum raw value type, if known
    var rawType: Type?

    // sourcery: skipEquality, skipDescription, skipCoding
    /// Names of types or protocols this type inherits from, including unknown (not scanned) types
    override var based: [String: String] {
        didSet {
            if let rawTypeName = rawTypeName, based[rawTypeName.name] != nil {
                based[rawTypeName.name] = nil
            }
        }
    }

    /// Whether enum contains any associated values
    var hasAssociatedValues: Bool {
        return cases.contains(where: { $0.hasAssociatedValue })
    }

    /// :nodoc:
    init(name: String = "",
                parent: Type? = nil,
                accessLevel: AccessLevel = .internal,
                isExtension: Bool = false,
                inheritedTypes: [String] = [],
                rawTypeName: TypeName? = nil,
                cases: [EnumCase] = [],
                variables: [Variable] = [],
                methods: [Method] = [],
                containedTypes: [Type] = [],
                typealiases: [Typealias] = [],
                attributes: [String: Attribute] = [:],
                annotations: Annotations = [:],
                isGeneric: Bool = false,
				file: String) {

        self.cases = cases
        self.rawTypeName = rawTypeName
        self.hasRawType = rawTypeName != nil || !inheritedTypes.isEmpty

		super.init(name: name, parent: parent, accessLevel: accessLevel, isExtension: isExtension, variables: variables, methods: methods, inheritedTypes: inheritedTypes, containedTypes: containedTypes, typealiases: typealiases, attributes: attributes, annotations: annotations, isGeneric: isGeneric, filePath: file)

        if let rawTypeName = rawTypeName?.name, let index = self.inheritedTypes.firstIndex(of: rawTypeName) {
            self.inheritedTypes.remove(at: index)
        }
    }
	
	required init(from decoder: Decoder) throws {
		self.cases = []
		self.hasRawType = false
		try super.init(from: decoder)
	}
	
	override func encode(to encoder: Encoder) throws {
		try super.encode(to: encoder)
	}

}
