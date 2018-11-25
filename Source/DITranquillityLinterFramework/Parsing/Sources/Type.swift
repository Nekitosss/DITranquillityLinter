//
// Created by Krzysztof Zablocki on 11/09/2016.
// Copyright (c) 2016 Pixle. All rights reserved.
//

import Foundation
import SourceKittenFramework

/// Defines Swift type
class Type: Annotated, Codable, Equatable {

	typealias ProtoStructure = Protobuf_Type
	
	static func fromProtoMessage(_ message: Type.ProtoStructure) -> Type {
		var res: Type
		
		if self == Class.self {
			res = Class(filePath: message.filePath)
		} else if self == Enum.self {
			res =
				Enum(file: message.filePath)
			
		} else if self == Protocol.self {
			res = Protocol(filePath: message.filePath)
			
		} else if self == Struct.self {
			res = Struct(filePath: message.filePath)
			
		} else if self == TypeComposition.self {
			res = TypeComposition(filePath: message.filePath)
		} else if self == Type.self {
			res = Type(filePath: message.filePath)
		} else {
			fatalError()
		}
		
		res.module = message.module
		res.typealiases = message.typealiases.mapValues({ .fromProtoMessage($0) })
		res.isExtension = message.isExtension
		res.accessLevel = message.accessLevel
		res.isGeneric = message.isGeneric
		res.genericTypeParameters = message.genericTypeParameters.map({ .fromProtoMessage($0) })
		res.localName = message.localName
		res.variables = message.variables.map({ .fromProtoMessage($0) })
		res.methods = message.methods.map({ .fromProtoMessage($0) })
		res.subscripts = message.subscripts.map({ .fromProtoMessage($0) })
		res.bodyBytesRange = .fromProtoMessage(message.bodyBytesRange)
		res.annotations = message.annotations.mapValues({ .fromProtoMessage($0) })
		res.inheritedTypes = message.inheritedTypes
		res.based = message.based
		res.inherits = message.inherits.value.mapValues({ .fromProtoMessage($0) })
		res.implements = message.implements.value.mapValues({ .fromProtoMessage($0) })
		res.containedTypes = message.containedTypes.value.map({ .fromProtoMessage($0) })
		res.containedType = message.containedType.value.mapValues({ .fromProtoMessage($0) })
		res.supertype = message.supertype.toValue.flatMap({ .fromProtoMessage($0) })
		res.attributes = message.attributes.mapValues({ .fromProtoMessage($0) })
		res.parserData = message.parserData.toValue.flatMap({ .fromProtoMessage($0) })
		res.path = message._Path
		
		return res
	}
	
	var toProtoMessage: Type.ProtoStructure {
		var res = ProtoStructure()
		res.module = self.module ?? ""
		res.typealiases = self.typealiases.mapValues({ $0.toProtoMessage })
		res.isExtension = self.isExtension
		res.accessLevel = self.accessLevel
		res.filePath = self.filePath
		res.isGeneric = self.isGeneric
		res.genericTypeParameters = self.genericTypeParameters.map({ $0.toProtoMessage })
		res.localName = self.localName
		res.variables = self.variables.map({ $0.toProtoMessage })
		res.methods = self.methods.map({ $0.toProtoMessage })
		res.subscripts = self.subscripts.map({ $0.toProtoMessage })
		res.bodyBytesRange = self.bodyBytesRange?.toProtoMessage ?? .init()
		res.annotations = self.annotations.mapValues({ $0.toProtoMessage })
		res.inheritedTypes = self.inheritedTypes
		res.based = self.based
		var inh = Protobuf_TypeMap()
		inh.value = self.inherits.mapValues({ $0.toProtoMessage })
		res.inherits = inh
		var impl = Protobuf_TypeMap()
		impl.value = self.implements.mapValues({ $0.toProtoMessage })
		var contained = Protobuf_TypeList()
		contained.value = self.containedTypes.map({ $0.toProtoMessage })
		res.containedTypes = contained
		var contained2 = Protobuf_TypeMap()
		contained2.value = self.containedType.mapValues({ $0.toProtoMessage })
		res.containedType = contained2
		res.supertype = .init(value: supertype?.toProtoMessage)
		res.attributes = self.attributes.mapValues({ $0.toProtoMessage })
		res.parserData = .init(value: parserData?.toProtoMessage)
		res._Path = self.path ?? ""
		return res
	}
	
	static func ==(lhs: Type, rhs: Type) -> Bool {
		return lhs.isEqual(rhs)
	}
	
	func isEqual(_ object: Any?) -> Bool {
		guard let rhs = object as? Type else { return false }
		if self.module != rhs.module { return false }
		if self.typealiases != rhs.typealiases { return false }
		if self.isExtension != rhs.isExtension { return false }
		if self.accessLevel != rhs.accessLevel { return false }
		if self.isGeneric != rhs.isGeneric { return false }
		if self.localName != rhs.localName { return false }
		if self.variables != rhs.variables { return false }
		if self.methods != rhs.methods { return false }
		if self.subscripts != rhs.subscripts { return false }
		if self.annotations != rhs.annotations { return false }
		if self.inheritedTypes != rhs.inheritedTypes { return false }
		if self.containedTypes != rhs.containedTypes { return false }
		if self.parentName != rhs.parentName { return false }
		if self.attributes != rhs.attributes { return false }
		if self.kind != rhs.kind { return false }
		return true
	}
	
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
    var accessLevel: String
	
	let filePath: String

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
		guard let structure = parserData?.dictionary.substructures else { return [] }
		return structure
	}
	
    // Underlying parser data, never to be used by anything else
    // sourcery: skipDescription, skipEquality, skipCoding, skipJSExport
    /// :nodoc:
    var parserData: Structure?
    // Path to file where the type is defined
    // sourcery: skipDescription, skipEquality, skipJSExport
    /// :nodoc:
    var path: String?

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
		 filePath: String) {
		
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
		self.filePath = filePath
		
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
	
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(module, forKey: .module)
		try container.encode(typealiases, forKey: .typealiases)
		try container.encode(isExtension, forKey: .isExtension)
		try container.encode(accessLevel, forKey: .accessLevel)
		try container.encode(isGeneric, forKey: .isGeneric)
		try container.encode(localName, forKey: .localName)
		try container.encode(variables, forKey: .variables)
		try container.encode(methods, forKey: .methods)
		try container.encode(subscripts, forKey: .subscripts)
		try container.encode(bodyBytesRange, forKey: .bodyBytesRange)
		try container.encode(annotations, forKey: .annotations)
		try container.encode(inheritedTypes, forKey: .inheritedTypes)
		try container.encode(based, forKey: .based)
		try container.encode(inherits, forKey: .inherits)
		try container.encode(implements, forKey: .implements)
		try container.encode(containedTypes, forKey: .containedTypes)
		try container.encode(containedType, forKey: .containedType)
		// parent should not be encoded
//		try container.encode(parentName, forKey: .parentName)
//		try container.encode(parent, forKey: .parent)
		try container.encode(supertype, forKey: .supertype)
		try container.encode(attributes, forKey: .attributes)
		try container.encode(path, forKey: .path)
		try container.encode(filePath, forKey: .filePath)
		try container.encode(parserData, forKey: .parserData)
		try container.encode(genericTypeParameters, forKey: .genericTypeParameters)
	}
	

}

extension Type {

    // sourcery: skipDescription, skipJSExport
    var isClass: Bool {
        let isNotClass = self is Struct || self is Enum || self is Protocol
        return !isNotClass && !isExtension
    }
}
