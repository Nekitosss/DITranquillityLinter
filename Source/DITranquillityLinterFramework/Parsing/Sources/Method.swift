import Foundation
import SourceKittenFramework

/// :nodoc:
typealias SourceryMethod = Method

/// Describes method parameter
@objcMembers final class MethodParameter: NSObject, SourceryModel, Typed, Annotated {
    /// Parameter external name
    var argumentLabel: String?

    /// Parameter internal name
    let name: String

    /// Parameter type name
    let typeName: TypeName

    /// Parameter flag whether it's inout or not
    let `inout`: Bool

    // sourcery: skipEquality, skipDescription
    /// Parameter type, if known
    var type: Type?

    /// Parameter type attributes, i.e. `@escaping`
    var typeAttributes: [String: Attribute] {
        return typeName.attributes
    }

    /// Method parameter default value expression
    var defaultValue: String?

    /// Annotations, that were created with // sourcery: annotation1, other = "annotation value", alterantive = 2
    var annotations: Annotations = [:]

    /// Underlying parser data, never to be used by anything else
    // sourcery: skipEquality, skipDescription, skipCoding, skipJSExport
    /// :nodoc:
    var __parserData: Structure?

    /// :nodoc:
    init(argumentLabel: String?, name: String = "", typeName: TypeName, type: Type? = nil, defaultValue: String? = nil, annotations: Annotations = [:], isInout: Bool = false) {
        self.typeName = typeName
        self.argumentLabel = argumentLabel
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.annotations = annotations
        self.`inout` = isInout
    }

    /// :nodoc:
    init(name: String = "", typeName: TypeName, type: Type? = nil, defaultValue: String? = nil, annotations: Annotations = [:], isInout: Bool = false) {
        self.typeName = typeName
        self.argumentLabel = name
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.annotations = annotations
        self.`inout` = isInout
    }

    // sourcery:inline:MethodParameter.AutoCoding
        /// :nodoc:
        required init?(coder aDecoder: NSCoder) {
            self.argumentLabel = aDecoder.decode(forKey: "argumentLabel")
            guard let name: String = aDecoder.decode(forKey: "name") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["name"])); fatalError() }; self.name = name
            guard let typeName: TypeName = aDecoder.decode(forKey: "typeName") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["typeName"])); fatalError() }; self.typeName = typeName
            self.`inout` = aDecoder.decode(forKey: "`inout`")
            self.type = aDecoder.decode(forKey: "type")
            self.defaultValue = aDecoder.decode(forKey: "defaultValue")
            guard let annotations: Annotations = aDecoder.decode(forKey: "annotations") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["annotations"])); fatalError() }; self.annotations = annotations
        }

        /// :nodoc:
        func encode(with aCoder: NSCoder) {
            aCoder.encode(self.argumentLabel, forKey: "argumentLabel")
            aCoder.encode(self.name, forKey: "name")
            aCoder.encode(self.typeName, forKey: "typeName")
            aCoder.encode(self.`inout`, forKey: "`inout`")
            aCoder.encode(self.type, forKey: "type")
            aCoder.encode(self.defaultValue, forKey: "defaultValue")
            aCoder.encode(self.annotations, forKey: "annotations")
        }
        // sourcery:end
}

/// Describes method
@objc(SwiftMethod) @objcMembers final class Method: NSObject, SourceryModel, Annotated, Definition {

    /// Full method name, including generic constraints, i.e. `foo<T>(bar: T)`
    let name: String

    /// Method name including arguments names, i.e. `foo(bar:)`
    var selectorName: String

    // sourcery: skipEquality, skipDescription
    /// Method name without arguments names and parenthesis, i.e. `foo<T>`
    var shortName: String {
        return name.range(of: "(").map({ String(name[..<$0.lowerBound]) }) ?? name
    }

    // sourcery: skipEquality, skipDescription
    /// Method name without arguments names, parenthesis and generic types, i.e. `foo` (can be used to generate code for method call)
    var callName: String {
        return shortName.range(of: "<").map({ String(shortName[..<$0.lowerBound]) }) ?? shortName
    }

    /// Method parameters
    var parameters: [MethodParameter]

    /// Return value type name used in declaration, including generic constraints, i.e. `where T: Equatable`
    var returnTypeName: TypeName

    // sourcery: skipEquality, skipDescription
    /// Actual return value type name if declaration uses typealias, otherwise just a `returnTypeName`
    var actualReturnTypeName: TypeName {
        return returnTypeName.actualTypeName ?? returnTypeName
    }

    // sourcery: skipEquality, skipDescription
    /// Actual return value type, if known
    var returnType: Type?

    // sourcery: skipEquality, skipDescription
    /// Whether return value type is optional
    var isOptionalReturnType: Bool {
        return returnTypeName.isOptional || isFailableInitializer
    }

    // sourcery: skipEquality, skipDescription
    /// Whether return value type is implicitly unwrapped optional
    var isImplicitlyUnwrappedOptionalReturnType: Bool {
        return returnTypeName.isImplicitlyUnwrappedOptional
    }

    // sourcery: skipEquality, skipDescription
    /// Return value type name without attributes and optional type information
    var unwrappedReturnTypeName: String {
        return returnTypeName.unwrappedTypeName
    }

    /// Whether method throws
    let `throws`: Bool

    /// Whether method rethrows
    let `rethrows`: Bool

    /// Method access level, i.e. `internal`, `private`, `fileprivate`, `public`, `open`
    let accessLevel: String

    /// Whether method is a static method
    let isStatic: Bool

    /// Whether method is a class method
    let isClass: Bool

    // sourcery: skipEquality, skipDescription
    /// Whether method is an initializer
    var isInitializer: Bool {
        return selectorName.hasPrefix("init(") || selectorName == "init"
    }

    // sourcery: skipEquality, skipDescription
    /// Whether method is an deinitializer
    var isDeinitializer: Bool {
        return selectorName == "deinit"
    }

    /// Whether method is a failable initializer
    let isFailableInitializer: Bool

    // sourcery: skipEqaulitey, skipDescription, skipCoding, skipJSExport
    /// :nodoc:
    @available(*, deprecated: 0.7, message: "Use isConvenienceInitializer instead") var isConvenienceInitialiser: Bool {
        return attributes[Attribute.Identifier.convenience.name] != nil
    }

    // sourcery: skipEquality, skipDescription
    /// Whether method is a convenience initializer
    var isConvenienceInitializer: Bool {
        return attributes[Attribute.Identifier.convenience.name] != nil
    }

    // sourcery: skipEquality, skipDescription
    /// Whether method is required
    var isRequired: Bool {
        return attributes[Attribute.Identifier.required.name] != nil
    }

    // sourcery: skipEquality, skipDescription
    /// Whether method is final
    var isFinal: Bool {
        return attributes[Attribute.Identifier.final.name] != nil
    }

    // sourcery: skipEquality, skipDescription
    /// Whether method is mutating
    var isMutating: Bool {
        return attributes[Attribute.Identifier.mutating.name] != nil
    }

    // sourcery: skipEquality, skipDescription
    /// Whether method is generic
    var isGeneric: Bool {
        return shortName.hasSuffix(">")
    }

    /// Annotations, that were created with // sourcery: annotation1, other = "annotation value", alterantive = 2
    let annotations: Annotations

    /// Reference to type name where the method is defined,
    /// nil if defined outside of any `enum`, `struct`, `class` etc
    let definedInTypeName: TypeName?

    // sourcery: skipEquality, skipDescription
    /// Reference to actual type name where the method is defined if declaration uses typealias, otherwise just a `definedInTypeName`
    var actualDefinedInTypeName: TypeName? {
        return definedInTypeName?.actualTypeName ?? definedInTypeName
    }

    // sourcery: skipEquality, skipDescription
    /// Reference to actual type where the object is defined,
    /// nil if defined outside of any `enum`, `struct`, `class` etc or type is unknown
    var definedInType: Type?

    /// Method attributes, i.e. `@discardableResult`
    let attributes: [String: Attribute]

    // Underlying parser data, never to be used by anything else
    // sourcery: skipEquality, skipDescription, skipCoding, skipJSExport
    /// :nodoc:
    var __parserData: Structure?

    /// :nodoc:
    init(name: String,
                selectorName: String? = nil,
                parameters: [MethodParameter] = [],
                returnTypeName: TypeName = TypeName("Void"),
                throws: Bool = false,
                rethrows: Bool = false,
                accessLevel: AccessLevel = .internal,
                isStatic: Bool = false,
                isClass: Bool = false,
                isFailableInitializer: Bool = false,
                attributes: [String: Attribute] = [:],
                annotations: Annotations = [:],
                definedInTypeName: TypeName? = nil) {

        self.name = name
        self.selectorName = selectorName ?? name
        self.parameters = parameters
        self.returnTypeName = returnTypeName
        self.throws = `throws`
        self.rethrows = `rethrows`
        self.accessLevel = accessLevel.rawValue
        self.isStatic = isStatic
        self.isClass = isClass
        self.isFailableInitializer = isFailableInitializer
        self.attributes = attributes
        self.annotations = annotations
        self.definedInTypeName = definedInTypeName
    }

    // sourcery:inline:Method.AutoCoding
        /// :nodoc:
        required init?(coder aDecoder: NSCoder) {
            guard let name: String = aDecoder.decode(forKey: "name") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["name"])); fatalError() }; self.name = name
            guard let selectorName: String = aDecoder.decode(forKey: "selectorName") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["selectorName"])); fatalError() }; self.selectorName = selectorName
            guard let parameters: [MethodParameter] = aDecoder.decode(forKey: "parameters") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["parameters"])); fatalError() }; self.parameters = parameters
            guard let returnTypeName: TypeName = aDecoder.decode(forKey: "returnTypeName") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["returnTypeName"])); fatalError() }; self.returnTypeName = returnTypeName
            self.returnType = aDecoder.decode(forKey: "returnType")
            self.`throws` = aDecoder.decode(forKey: "`throws`")
            self.`rethrows` = aDecoder.decode(forKey: "`rethrows`")
            guard let accessLevel: String = aDecoder.decode(forKey: "accessLevel") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["accessLevel"])); fatalError() }; self.accessLevel = accessLevel
            self.isStatic = aDecoder.decode(forKey: "isStatic")
            self.isClass = aDecoder.decode(forKey: "isClass")
            self.isFailableInitializer = aDecoder.decode(forKey: "isFailableInitializer")
            guard let annotations: Annotations = aDecoder.decode(forKey: "annotations") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["annotations"])); fatalError() }; self.annotations = annotations
            self.definedInTypeName = aDecoder.decode(forKey: "definedInTypeName")
            self.definedInType = aDecoder.decode(forKey: "definedInType")
            guard let attributes: [String: Attribute] = aDecoder.decode(forKey: "attributes") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["attributes"])); fatalError() }; self.attributes = attributes
        }

        /// :nodoc:
        func encode(with aCoder: NSCoder) {
            aCoder.encode(self.name, forKey: "name")
            aCoder.encode(self.selectorName, forKey: "selectorName")
            aCoder.encode(self.parameters, forKey: "parameters")
            aCoder.encode(self.returnTypeName, forKey: "returnTypeName")
            aCoder.encode(self.returnType, forKey: "returnType")
            aCoder.encode(self.`throws`, forKey: "`throws`")
            aCoder.encode(self.`rethrows`, forKey: "`rethrows`")
            aCoder.encode(self.accessLevel, forKey: "accessLevel")
            aCoder.encode(self.isStatic, forKey: "isStatic")
            aCoder.encode(self.isClass, forKey: "isClass")
            aCoder.encode(self.isFailableInitializer, forKey: "isFailableInitializer")
            aCoder.encode(self.annotations, forKey: "annotations")
            aCoder.encode(self.definedInTypeName, forKey: "definedInTypeName")
            aCoder.encode(self.definedInType, forKey: "definedInType")
            aCoder.encode(self.attributes, forKey: "attributes")
        }
     // sourcery:end
}
