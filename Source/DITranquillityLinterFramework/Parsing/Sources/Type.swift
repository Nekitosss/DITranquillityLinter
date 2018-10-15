//
// Created by Krzysztof Zablocki on 11/09/2016.
// Copyright (c) 2016 Pixle. All rights reserved.
//

import Foundation
import SourceKittenFramework

/// Defines Swift type
@objcMembers class Type: NSObject, SourceryModel, Annotated {

    /// :nodoc:
    var module: String?

    // All local typealiases
    // sourcery: skipJSExport
    /// :nodoc:
    var typealiases: [String: Typealias] {
        didSet {
            typealiases.values.forEach { $0.parent = self }
        }
    }

    // sourcery: skipJSExport
    /// Whether declaration is an extension of some type
    var isExtension: Bool

    // sourcery: forceEquality
    /// Kind of type declaration, i.e. `enum`, `struct`, `class`, `protocol` or `extension`
    var kind: String { return isExtension ? "extension" : "unknown" }

    /// Type access level, i.e. `internal`, `private`, `fileprivate`, `public`, `open`
    let accessLevel: String
	
	let file: File

    /// Type name in global scope. For inner types includes the name of its containing type, i.e. `Type.Inner`
    var name: String {
        guard let parentName = parent?.name else { return localName }
        return "\(parentName).\(localName)"
    }

    // sourcery: skipDescription
    var globalName: String {
        guard let module = module else { return name }
        return "\(module).\(name)"
    }

    /// Whether type is generic
    var isGeneric: Bool

	var genericTypeParameters: [GenericTypeParameter]
	
    /// Type name in its own scope.
    var localName: String

    /// Variables defined in this type only, inluding variables defined in its extensions,
    /// but not including variables inherited from superclasses (for classes only) and protocols
    var variables: [Variable]

    // sourcery: skipEquality, skipDescription
    /// All variables defined for this type, including variables defined in extensions,
    /// in superclasses (for classes only) and protocols
    var allVariables: [Variable] {
        return flattenAll({
            return $0.variables
        }, filter: { all, extracted in
            !all.contains(where: { $0.name == extracted.name && $0.isStatic == extracted.isStatic })
        })
    }

    /// Methods defined in this type only, inluding methods defined in its extensions,
    /// but not including methods inherited from superclasses (for classes only) and protocols
    var methods: [Method]

    // sourcery: skipEquality, skipDescription
    /// All methods defined for this type, including methods defined in extensions,
    /// in superclasses (for classes only) and protocols
    var allMethods: [Method] {
        return flattenAll({ $0.methods })
    }

    /// Subscripts defined in this type only, inluding subscripts defined in its extensions,
    /// but not including subscripts inherited from superclasses (for classes only) and protocols
    var subscripts: [Subscript]

    // sourcery: skipEquality, skipDescription
    /// All subscripts defined for this type, including subscripts defined in extensions,
    /// in superclasses (for classes only) and protocols
    var allSubscripts: [Subscript] {
        return flattenAll({ $0.subscripts })
    }

    // sourcery: skipEquality, skipDescription, skipJSExport
    /// Bytes position of the body of this type in its declaration file if available.
    var bodyBytesRange: BytesRange?

    private func flattenAll<T>(_ extraction: @escaping (Type) -> [T], filter: (([T], T) -> Bool)? = nil) -> [T] {
        let all = NSMutableOrderedSet()
        all.addObjects(from: extraction(self))

        let filteredExtraction = { (target: Type) -> [T] in
            if let filter = filter {
                // swiftlint:disable:next force_cast
                let all = all.array as! [T]
                let extracted = extraction(target).filter({ filter(all, $0) })
                return extracted
            } else {
                return extraction(target)
            }
        }

        inherits.values.forEach { all.addObjects(from: filteredExtraction($0)) }
        implements.values.forEach { all.addObjects(from: filteredExtraction($0)) }

        return all.array.compactMap { $0 as? T }
    }

    /// All initializers defined in this type
    var initializers: [Method] {
        return methods.filter { $0.isInitializer }
    }

    /// All annotations for this type
    var annotations: Annotations = [:]

    /// Static variables defined in this type
    var staticVariables: [Variable] {
        return variables.filter { $0.isStatic }
    }

    /// Static methods defined in this type
    var staticMethods: [Method] {
        return methods.filter { $0.isStatic }
    }

    /// Class methods defined in this type
    var classMethods: [Method] {
        return methods.filter { $0.isClass }
    }

    /// Instance variables defined in this type
    var instanceVariables: [Variable] {
        return variables.filter { !$0.isStatic }
    }

    /// Instance methods defined in this type
    var instanceMethods: [Method] {
        return methods.filter { !$0.isStatic && !$0.isClass }
    }

    /// Computed instance variables defined in this type
    var computedVariables: [Variable] {
        return variables.filter { $0.isComputed && !$0.isStatic }
    }

    /// Stored instance variables defined in this type
    var storedVariables: [Variable] {
        return variables.filter { !$0.isComputed && !$0.isStatic }
    }

    /// Names of types this type inherits from (for classes only) and protocols it implements, in order of definition
    var inheritedTypes: [String] {
        didSet {
            based.removeAll()
            inheritedTypes.forEach { name in
                self.based[name] = name
            }
        }
    }

    // sourcery: skipEquality, skipDescription
    /// Names of types or protocols this type inherits from, including unknown (not scanned) types
    var based = [String: String]()

    // sourcery: skipEquality, skipDescription
    /// Types this type inherits from (only for classes)
    var inherits = [String: Type]()

    // sourcery: skipEquality, skipDescription
    /// Protocols this type implements
    var implements = [String: Type]()

	var inheritanceAndImplementations: [String: Type] {
		var result: [String: Type] = [:]
		for (_, type) in inherits {
			result[type.name] = type
		}
		for (_, type) in implements {
			result[type.name] = type
		}
		return result
	}
	
    /// Contained types
    var containedTypes: [Type] {
        didSet {
            containedTypes.forEach {
                containedType[$0.localName] = $0
                $0.parent = self
            }
        }
    }

    // sourcery: skipEquality, skipDescription
    /// Contained types groupd by their names
    private(set) var containedType: [String: Type] = [:]

    /// Name of parent type (for contained types only)
    private(set) var parentName: String?

    // sourcery: skipEquality, skipDescription
    /// Parent type, if known (for contained types only)
    var parent: Type? {
        didSet {
            parentName = parent?.name
        }
    }

    // sourcery: skipJSExport
    /// :nodoc:
    var parentTypes: AnyIterator<Type> {
        var next: Type? = self
        return AnyIterator {
            next = next?.parent
            return next
        }
    }

    // sourcery: skipEquality, skipDescription
    /// Superclass type, if known (only for classes)
    var supertype: Type?

    /// Type attributes, i.e. `@objc`
    var attributes: [String: Attribute]

	var substructure: [SourceKitStructure] {
		guard let structure = __parserData?.dictionary.substructures else { return [] }
		return structure
	}
	
    // Underlying parser data, never to be used by anything else
    // sourcery: skipDescription, skipEquality, skipCoding, skipJSExport
    /// :nodoc:
    var __parserData: Structure?
    // Path to file where the type is defined
    // sourcery: skipDescription, skipEquality, skipJSExport
    /// :nodoc:
    var __path: String?

    /// :nodoc:
    init(name: String = "",
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

        self.localName = name
        self.accessLevel = accessLevel.rawValue
        self.isExtension = isExtension
        self.variables = variables
        self.methods = methods
        self.subscripts = subscripts
        self.inheritedTypes = inheritedTypes
        self.containedTypes = containedTypes
        self.typealiases = [:]
        self.parent = parent
        self.parentName = parent?.name
        self.attributes = attributes
        self.annotations = annotations
        self.isGeneric = isGeneric
		self.genericTypeParameters = genericTypeParameters
		self.file = file

        super.init()
        containedTypes.forEach {
            containedType[$0.localName] = $0
            $0.parent = self
        }
        inheritedTypes.forEach { name in
            self.based[name] = name
        }
        typealiases.forEach({
            $0.parent = self
            self.typealiases[$0.aliasName] = $0
        })
    }

    /// :nodoc:
    func extend(_ type: Type) {
        self.variables += type.variables
        self.methods += type.methods
        self.subscripts += type.subscripts
        self.inheritedTypes += type.inheritedTypes
        self.containedTypes += type.containedTypes

        type.annotations.forEach { self.annotations[$0.key] = $0.value }
        type.inherits.forEach { self.inherits[$0.key] = $0.value }
        type.implements.forEach { self.implements[$0.key] = $0.value }
    }

    // sourcery:inline:Type.AutoCoding
        /// :nodoc:
        required init?(coder aDecoder: NSCoder) {
            self.module = aDecoder.decode(forKey: "module")
            guard let typealiases: [String: Typealias] = aDecoder.decode(forKey: "typealiases") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["typealiases"])); fatalError() }; self.typealiases = typealiases
            self.isExtension = aDecoder.decode(forKey: "isExtension")
            guard let accessLevel: String = aDecoder.decode(forKey: "accessLevel") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["accessLevel"])); fatalError() }; self.accessLevel = accessLevel
            self.isGeneric = aDecoder.decode(forKey: "isGeneric")
            guard let localName: String = aDecoder.decode(forKey: "localName") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["localName"])); fatalError() }; self.localName = localName
            guard let variables: [Variable] = aDecoder.decode(forKey: "variables") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["variables"])); fatalError() }; self.variables = variables
            guard let methods: [Method] = aDecoder.decode(forKey: "methods") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["methods"])); fatalError() }; self.methods = methods
            guard let subscripts: [Subscript] = aDecoder.decode(forKey: "subscripts") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["subscripts"])); fatalError() }; self.subscripts = subscripts
            self.bodyBytesRange = aDecoder.decode(forKey: "bodyBytesRange")
            guard let annotations: Annotations = aDecoder.decode(forKey: "annotations") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["annotations"])); fatalError() }; self.annotations = annotations
            guard let inheritedTypes: [String] = aDecoder.decode(forKey: "inheritedTypes") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["inheritedTypes"])); fatalError() }; self.inheritedTypes = inheritedTypes
            guard let based: [String: String] = aDecoder.decode(forKey: "based") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["based"])); fatalError() }; self.based = based
            guard let inherits: [String: Type] = aDecoder.decode(forKey: "inherits") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["inherits"])); fatalError() }; self.inherits = inherits
            guard let implements: [String: Type] = aDecoder.decode(forKey: "implements") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["implements"])); fatalError() }; self.implements = implements
            guard let containedTypes: [Type] = aDecoder.decode(forKey: "containedTypes") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["containedTypes"])); fatalError() }; self.containedTypes = containedTypes
            guard let containedType: [String: Type] = aDecoder.decode(forKey: "containedType") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["containedType"])); fatalError() }; self.containedType = containedType
            self.parentName = aDecoder.decode(forKey: "parentName")
            self.parent = aDecoder.decode(forKey: "parent")
            self.supertype = aDecoder.decode(forKey: "supertype")
            guard let attributes: [String: Attribute] = aDecoder.decode(forKey: "attributes") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["attributes"])); fatalError() }; self.attributes = attributes
            self.__path = aDecoder.decode(forKey: "__path")
			guard let file: File = aDecoder.decode(forKey: "file") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["file"])); fatalError() }; self.file = file
			guard let genericTypeParameters: [GenericTypeParameter] = aDecoder.decode(forKey: "genericTypeParameters") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["genericTypeParameters"])); fatalError() }; self.genericTypeParameters = genericTypeParameters
        }

        /// :nodoc:
        func encode(with aCoder: NSCoder) {
            aCoder.encode(self.module, forKey: "module")
            aCoder.encode(self.typealiases, forKey: "typealiases")
            aCoder.encode(self.isExtension, forKey: "isExtension")
            aCoder.encode(self.accessLevel, forKey: "accessLevel")
            aCoder.encode(self.isGeneric, forKey: "isGeneric")
            aCoder.encode(self.localName, forKey: "localName")
            aCoder.encode(self.variables, forKey: "variables")
            aCoder.encode(self.methods, forKey: "methods")
            aCoder.encode(self.subscripts, forKey: "subscripts")
            aCoder.encode(self.bodyBytesRange, forKey: "bodyBytesRange")
            aCoder.encode(self.annotations, forKey: "annotations")
            aCoder.encode(self.inheritedTypes, forKey: "inheritedTypes")
            aCoder.encode(self.based, forKey: "based")
            aCoder.encode(self.inherits, forKey: "inherits")
            aCoder.encode(self.implements, forKey: "implements")
            aCoder.encode(self.containedTypes, forKey: "containedTypes")
            aCoder.encode(self.containedType, forKey: "containedType")
            aCoder.encode(self.parentName, forKey: "parentName")
            aCoder.encode(self.parent, forKey: "parent")
            aCoder.encode(self.supertype, forKey: "supertype")
            aCoder.encode(self.attributes, forKey: "attributes")
            aCoder.encode(self.__path, forKey: "__path")
        }
    // sourcery:end
}

extension Type {

    // sourcery: skipDescription, skipJSExport
    var isClass: Bool {
        let isNotClass = self is Struct || self is Enum || self is Protocol
        return !isNotClass && !isExtension
    }
}
