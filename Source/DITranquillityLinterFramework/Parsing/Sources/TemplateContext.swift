//
// Created by Krzysztof Zablocki on 31/12/2016.
// Copyright (c) 2016 Pixle. All rights reserved.
//

import Foundation

/// :nodoc:
@objcMembers final class TemplateContext: NSObject, SourceryModel {
    let types: Types
    let arguments: [String: NSObject]

    // sourcery: skipDescription
    var type: [String: Type] {
        return types.typesByName
    }

    init(types: Types, arguments: [String: NSObject]) {
        self.types = types
        self.arguments = arguments
    }

    // sourcery:inline:TemplateContext.AutoCoding
        /// :nodoc:
        required init?(coder aDecoder: NSCoder) {
            guard let types: Types = aDecoder.decode(forKey: "types") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["types"])); fatalError() }; self.types = types
            guard let arguments: [String: NSObject] = aDecoder.decode(forKey: "arguments") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["arguments"])); fatalError() }; self.arguments = arguments
        }

        /// :nodoc:
        func encode(with aCoder: NSCoder) {
            aCoder.encode(self.types, forKey: "types")
            aCoder.encode(self.arguments, forKey: "arguments")
        }
    // sourcery:end

    var stencilContext: [String: Any] {
        return [
            "types": types,
            "type": types.typesByName,
            "argument": arguments
        ]
    }

    // sourcery: skipDescription, skipEquality
    var jsContext: [String: Any] {
        return [
            "types": [
                "all": types.all,
                "protocols": types.protocols,
                "classes": types.classes,
                "structs": types.structs,
                "enums": types.enums,
                "extensions": types.extensions,
                "based": types.based,
                "inheriting": types.inheriting,
                "implementing": types.implementing
            ],
            "type": types.typesByName,
            "argument": arguments
        ]
    }

}

extension ProcessInfo {
    /// :nodoc:
    var context: TemplateContext! {
        return NSKeyedUnarchiver.unarchiveObject(withFile: arguments[1]) as? TemplateContext
    }
}

// sourcery: skipJSExport
/// Collection of scanned types for accessing in templates
@objcMembers final class Types: NSObject, SourceryModel {

    /// :nodoc:
    let types: [Type]

    /// :nodoc:
    init(types: [Type]) {
        self.types = types
    }

    // sourcery:inline:Types.AutoCoding
        /// :nodoc:
        required init?(coder aDecoder: NSCoder) {
            guard let types: [Type] = aDecoder.decode(forKey: "types") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["types"])); fatalError() }; self.types = types
        }

        /// :nodoc:
        func encode(with aCoder: NSCoder) {
            aCoder.encode(self.types, forKey: "types")
        }
    // sourcery:end

    // sourcery: skipDescription, skipEquality, skipCoding
    /// :nodoc:
    lazy internal(set) var typesByName: [String: Type] = {
        var typesByName = [String: Type]()
        self.types.forEach { typesByName[$0.name] = $0 }
        return typesByName
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// All known types, excluding protocols
    lazy internal(set) var all: [Type] = {
        return self.types.filter { !($0 is Protocol) }
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// All known protocols
    lazy internal(set) var protocols: [Protocol] = {
        return self.types.compactMap { $0 as? Protocol }
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// All known classes
    lazy internal(set) var classes: [Class] = {
        return self.all.compactMap { $0 as? Class }
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// All known structs
    lazy internal(set) var structs: [Struct] = {
        return self.all.compactMap { $0 as? Struct }
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// All known enums
    lazy internal(set) var enums: [Enum] = {
        return self.all.compactMap { $0 as? Enum }
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// All known extensions
    lazy internal(set) var extensions: [Type] = {
        return self.all.compactMap { $0.isExtension ? $0 : nil }
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// Types based on any other type, grouped by its name, even if they are not known.
    /// `types.based.MyType` returns list of types based on `MyType`
    lazy internal(set) var based: TypesCollection = {
        TypesCollection(
            types: self.types,
            collection: { Array($0.based.keys) }
        )
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// Classes inheriting from any known class, grouped by its name.
    /// `types.inheriting.MyClass` returns list of types inheriting from `MyClass`
    lazy internal(set) var inheriting: TypesCollection = {
        TypesCollection(
            types: self.types,
            collection: { Array($0.inherits.keys) },
            validate: { type in
                guard type is Class else {
                    throw "\(type.name) is a not a class and should be used with `implementing` or `based`"
                }
            })
    }()

    // sourcery: skipDescription, skipEquality, skipCoding
    /// Types implementing known protocol, grouped by its name.
    /// `types.implementing.MyProtocol` returns list of types implementing `MyProtocol`
    lazy internal(set) var implementing: TypesCollection = {
        TypesCollection(
            types: self.types,
            collection: { Array($0.implements.keys) },
            validate: { type in
                guard type is Protocol else {
                    throw "\(type.name) is a class and should be used with `inheriting` or `based`"
                }
        })
    }()
}

/// :nodoc:
@objcMembers class TypesCollection: NSObject, AutoJSExport {

    // sourcery:begin: skipJSExport
    let all: [Type]
    let types: [String: [Type]]
    let validate: ((Type) throws -> Void)?
    // sourcery:end

    init(types: [Type], collection: (Type) -> [String], validate: ((Type) throws -> Void)? = nil) {
        self.all = types
        var content = [String: [Type]]()
        self.all.forEach { type in
            collection(type).forEach { name in
                var list = content[name] ?? [Type]()
                list.append(type)
                content[name] = list
            }
        }
        self.types = content
        self.validate = validate
    }

    func types(forKey key: String) throws -> [Type] {
        if let validate = validate {
            guard let type = all.first(where: { $0.name == key }) else {
                throw "Unknown type \(key), should be used with `based`"
            }
            try validate(type)
        }
        return types[key] ?? []
    }

    /// :nodoc:
    override func value(forKey key: String) -> Any? {
        do {
            return try types(forKey: key)
        } catch {
            Log.error(error)
            return nil
        }
    }

    /// :nodoc:
    subscript(_ key: String) -> [Type] {
        do {
            return try types(forKey: key)
        } catch {
            Log.error(error)
            return []
        }
    }

}
