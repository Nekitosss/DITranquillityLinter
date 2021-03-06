import Foundation
import SourceKittenFramework

/// :nodoc:
typealias SourceryMethod = Method

/// Describes method parameter
final class MethodParameter: NSObject, Typed, Annotated, Codable, ProtobufBridgable {
	
	typealias ProtoStructure = Protobuf_MethodParameter
	
	var toProtoMessage: MethodParameter.ProtoStructure {
		var res = ProtoStructure()
		res.argumentLabel = .init(value: self.argumentLabel)
		res.name = self.name
		res.typeName = self.typeName.toProtoMessage
		res.inout = self.inout
		res.type = .init(value: self.type?.toProtoMessage)
		res.defaultValue = .init(value: self.defaultValue)
		res.annotations = self.annotations.mapValues({ $0.toProtoMessage })
		res.parserData = .init(value: self.parserData?.toProtoMessage)
		return res
	}
	
	static func fromProtoMessage(_ message: MethodParameter.ProtoStructure) -> MethodParameter {
		let res = MethodParameter(argumentLabel: message.argumentLabel.toValue,
							   name: message.name,
							   typeName: .fromProtoMessage(message.typeName),
							   type: message.type.toValue.flatMap({ .fromProtoMessage($0) }),
							   defaultValue: message.defaultValue.toValue,
							   annotations: message.annotations.mapValues({ .fromProtoMessage($0) }),
							   isInout: message.inout)
		res.parserData = message.parserData.toValue.flatMap({ .fromProtoMessage($0) })
		return res
	}
	
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
    var parserData: Structure?

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

}

/// Describes method
final class Method: NSObject, Annotated, Definition, Codable, ProtobufBridgable {

	typealias ProtoStructure = Protobuf_Method
	
	var toProtoMessage: Method.ProtoStructure {
		var res = ProtoStructure()
		res.name = self.name
		res.selectorName = self.selectorName
		res.parameters = self.parameters.map({ $0.toProtoMessage })
		res.returnType = .init(value: self.returnType?.toProtoMessage)
		res.returnTypeName = self.returnTypeName.toProtoMessage
		res.throws = self.throws
		res.rethrows = self.rethrows
		res.accessLevel = self.accessLevel
		res.isStatic = self.isStatic
		res.isClass = self.isClass
		res.isFailableInitializer = self.isFailableInitializer
		res.annotations = self.annotations.mapValues({ $0.toProtoMessage })
		res.definedInType = .init(value: self.definedInType?.toProtoMessage)
		res.definedInTypeName = .init(value: self.definedInTypeName?.toProtoMessage)
		res.attributes = self.attributes.mapValues({ $0.toProtoMessage })
		res.parserData = .init(value: self.parserData?.toProtoMessage)
		return res
	}
	
	static func fromProtoMessage(_ message: Method.ProtoStructure) -> Method {
		let res = Method(name: message.name,
						 selectorName: message.selectorName,
						 parameters: message.parameters.map({ .fromProtoMessage($0) }),
						 returnTypeName: .fromProtoMessage(message.returnTypeName),
						 throws: message.throws,
						 rethrows: message.rethrows,
						 accessLevel: .init(value: message.accessLevel),
						 isStatic: message.isStatic,
						 isClass: message.isClass,
						 isFailableInitializer: message.isFailableInitializer,
						 attributes: message.attributes.mapValues({ .fromProtoMessage($0) }),
						 annotations: message.annotations.mapValues({ .fromProtoMessage($0) }),
						 definedInTypeName: message.definedInTypeName.toValue.flatMap({ .fromProtoMessage($0) }))
		return res
	}
	
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
    var parserData: Structure?

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
}
