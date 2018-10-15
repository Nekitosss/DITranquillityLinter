//
// Created by Krzysztof Zablocki on 13/09/2016.
// Copyright (c) 2016 Pixle. All rights reserved.
//

import Foundation
import SourceKittenFramework

/// :nodoc:
typealias SourceryVariable = Variable

/// Defines variable
@objcMembers final class Variable: NSObject, SourceryModel, Typed, Annotated, Definition {
    /// Variable name
    let name: String

    /// Variable type name
    let typeName: TypeName

    // sourcery: skipEquality, skipDescription
    /// Variable type, if known, i.e. if the type is declared in the scanned sources.
    /// For explanation, see <https://cdn.rawgit.com/krzysztofzablocki/Sourcery/master/docs/writing-templates.html#what-are-em-known-em-and-em-unknown-em-types>
    var type: Type?

    /// Whether variable is computed and not stored
    let isComputed: Bool

    /// Whether variable is static
    let isStatic: Bool

    /// Variable read access level, i.e. `internal`, `private`, `fileprivate`, `public`, `open`
    let readAccess: String

    /// Variable write access, i.e. `internal`, `private`, `fileprivate`, `public`, `open`.
    /// For immutable variables this value is empty string
    let writeAccess: String

    /// Whether variable is mutable or not
    var isMutable: Bool {
        return writeAccess != AccessLevel.none.rawValue
    }

    /// Variable default value expression
    var defaultValue: String?

    /// Annotations, that were created with // sourcery: annotation1, other = "annotation value", alterantive = 2
    var annotations: [String: NSObject] = [:]

    /// Variable attributes, i.e. `@IBOutlet`, `@IBInspectable`
    var attributes: [String: Attribute]

    /// Whether variable is final or not
    var isFinal: Bool {
        return attributes[Attribute.Identifier.final.name] != nil
    }

    /// Reference to type name where the variable is defined,
    /// nil if defined outside of any `enum`, `struct`, `class` etc
    let definedInTypeName: TypeName?

    /// Reference to actual type name where the method is defined if declaration uses typealias, otherwise just a `definedInTypeName`
    var actualDefinedInTypeName: TypeName? {
        return definedInTypeName?.actualTypeName ?? definedInTypeName
    }

    // sourcery: skipEquality, skipDescription
    /// Reference to actual type where the object is defined,
    /// nil if defined outside of any `enum`, `struct`, `class` etc or type is unknown
    var definedInType: Type?

    // Underlying parser data, never to be used by anything else
    // sourcery: skipEquality, skipDescription, skipCoding, skipJSExport
    /// :nodoc:
    var __parserData: Structure?

    /// :nodoc:
    init(name: String = "",
                typeName: TypeName,
                type: Type? = nil,
                accessLevel: (read: AccessLevel, write: AccessLevel) = (.internal, .internal),
                isComputed: Bool = false,
                isStatic: Bool = false,
                defaultValue: String? = nil,
                attributes: [String: Attribute] = [:],
                annotations: [String: NSObject] = [:],
                definedInTypeName: TypeName? = nil) {

        self.name = name
        self.typeName = typeName
        self.type = type
        self.isComputed = isComputed
        self.isStatic = isStatic
        self.defaultValue = defaultValue
        self.readAccess = accessLevel.read.rawValue
        self.writeAccess = accessLevel.write.rawValue
        self.attributes = attributes
        self.annotations = annotations
        self.definedInTypeName = definedInTypeName
    }

    // sourcery:inline:Variable.AutoCoding
        /// :nodoc:
        required init?(coder aDecoder: NSCoder) {
            guard let name: String = aDecoder.decode(forKey: "name") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["name"])); fatalError() }; self.name = name
            guard let typeName: TypeName = aDecoder.decode(forKey: "typeName") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["typeName"])); fatalError() }; self.typeName = typeName
            self.type = aDecoder.decode(forKey: "type")
            self.isComputed = aDecoder.decode(forKey: "isComputed")
            self.isStatic = aDecoder.decode(forKey: "isStatic")
            guard let readAccess: String = aDecoder.decode(forKey: "readAccess") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["readAccess"])); fatalError() }; self.readAccess = readAccess
            guard let writeAccess: String = aDecoder.decode(forKey: "writeAccess") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["writeAccess"])); fatalError() }; self.writeAccess = writeAccess
            self.defaultValue = aDecoder.decode(forKey: "defaultValue")
            guard let annotations: [String: NSObject] = aDecoder.decode(forKey: "annotations") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["annotations"])); fatalError() }; self.annotations = annotations
            guard let attributes: [String: Attribute] = aDecoder.decode(forKey: "attributes") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["attributes"])); fatalError() }; self.attributes = attributes
            self.definedInTypeName = aDecoder.decode(forKey: "definedInTypeName")
            self.definedInType = aDecoder.decode(forKey: "definedInType")
        }

        /// :nodoc:
        func encode(with aCoder: NSCoder) {
            aCoder.encode(self.name, forKey: "name")
            aCoder.encode(self.typeName, forKey: "typeName")
            aCoder.encode(self.type, forKey: "type")
            aCoder.encode(self.isComputed, forKey: "isComputed")
            aCoder.encode(self.isStatic, forKey: "isStatic")
            aCoder.encode(self.readAccess, forKey: "readAccess")
            aCoder.encode(self.writeAccess, forKey: "writeAccess")
            aCoder.encode(self.defaultValue, forKey: "defaultValue")
            aCoder.encode(self.annotations, forKey: "annotations")
            aCoder.encode(self.attributes, forKey: "attributes")
            aCoder.encode(self.definedInTypeName, forKey: "definedInTypeName")
            aCoder.encode(self.definedInType, forKey: "definedInType")
        }
        // sourcery:end
}
