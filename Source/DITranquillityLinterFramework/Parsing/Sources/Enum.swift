//
// Created by Krzysztof Zablocki on 13/09/2016.
// Copyright (c) 2016 Pixle. All rights reserved.
//

import Foundation
import SourceKittenFramework

/// Defines enum case associated value
@objcMembers final class AssociatedValue: NSObject, SourceryModel, AutoDescription, Typed, Annotated, Codable {

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

    // sourcery:inline:AssociatedValue.AutoCoding
        /// :nodoc:
        required init?(coder aDecoder: NSCoder) {
            self.localName = aDecoder.decode(forKey: "localName")
            self.externalName = aDecoder.decode(forKey: "externalName")
            guard let typeName: TypeName = aDecoder.decode(forKey: "typeName") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["typeName"])); fatalError() }; self.typeName = typeName
            self.type = aDecoder.decode(forKey: "type")
            guard let annotations: Annotations = aDecoder.decode(forKey: "annotations") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["annotations"])); fatalError() }; self.annotations = annotations
        }

        /// :nodoc:
        func encode(with aCoder: NSCoder) {
            aCoder.encode(self.localName, forKey: "localName")
            aCoder.encode(self.externalName, forKey: "externalName")
            aCoder.encode(self.typeName, forKey: "typeName")
            aCoder.encode(self.type, forKey: "type")
            aCoder.encode(self.annotations, forKey: "annotations")
        }
        // sourcery:end

}

/// Defines enum case
@objcMembers final class EnumCase: NSObject, SourceryModel, AutoDescription, Annotated, Codable {

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

    // sourcery:inline:EnumCase.AutoCoding
        /// :nodoc:
        required init?(coder aDecoder: NSCoder) {
            guard let name: String = aDecoder.decode(forKey: "name") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["name"])); fatalError() }; self.name = name
            self.rawValue = aDecoder.decode(forKey: "rawValue")
            guard let associatedValues: [AssociatedValue] = aDecoder.decode(forKey: "associatedValues") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["associatedValues"])); fatalError() }; self.associatedValues = associatedValues
            guard let annotations: Annotations = aDecoder.decode(forKey: "annotations") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["annotations"])); fatalError() }; self.annotations = annotations
        }

        /// :nodoc:
        func encode(with aCoder: NSCoder) {
            aCoder.encode(self.name, forKey: "name")
            aCoder.encode(self.rawValue, forKey: "rawValue")
            aCoder.encode(self.associatedValues, forKey: "associatedValues")
            aCoder.encode(self.annotations, forKey: "annotations")
        }
        // sourcery:end
}

/// Defines Swift enum
@objcMembers final class Enum: Type {

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
                if let index = inheritedTypes.index(of: rawTypeName.name) {
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
				file: File) {

        self.cases = cases
        self.rawTypeName = rawTypeName
        self.hasRawType = rawTypeName != nil || !inheritedTypes.isEmpty

		super.init(name: name, parent: parent, accessLevel: accessLevel, isExtension: isExtension, variables: variables, methods: methods, inheritedTypes: inheritedTypes, containedTypes: containedTypes, typealiases: typealiases, attributes: attributes, annotations: annotations, isGeneric: isGeneric, file: file)

        if let rawTypeName = rawTypeName?.name, let index = self.inheritedTypes.index(of: rawTypeName) {
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
