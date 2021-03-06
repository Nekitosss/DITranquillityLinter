import Foundation
import SourceKittenFramework

/// Describes subscript
final class Subscript: NSObject, Annotated, Definition, Codable, ProtobufBridgable {

	typealias ProtoStructure = Protobuf_Subscript
	
	var toProtoMessage: Subscript.ProtoStructure {
		var res = ProtoStructure()
		res.parameters = self.parameters.map({ $0.toProtoMessage })
		res.returnTypeName = self.returnTypeName.toProtoMessage
		res.returnType = .init(value: self.returnType?.toProtoMessage)
		res.readAccess = self.readAccess
		res.writeAccess = self.writeAccess
		res.annotations = self.annotations.mapValues({ $0.toProtoMessage })
		res.definedInType = .init(value: self.definedInType?.toProtoMessage)
		res.definedInTypeName = .init(value: self.definedInTypeName?.toProtoMessage)
		res.attributes = self.attributes.mapValues({ $0.toProtoMessage })
		res.parserData = .init(value: self.parserData?.toProtoMessage)
		return res
	}
	
	static func fromProtoMessage(_ message: Subscript.ProtoStructure) -> Subscript {
		let res = Subscript(parameters: message.parameters.map({ .fromProtoMessage($0) }),
						 returnTypeName: .fromProtoMessage(message.returnTypeName),
						 accessLevel: (AccessLevel.init(value: message.readAccess), AccessLevel.init(value: message.writeAccess)),
						 attributes: message.attributes.mapValues({ .fromProtoMessage($0) }),
						 annotations: message.annotations.mapValues({ .fromProtoMessage($0) }),
						 definedInTypeName: message.definedInTypeName.toValue.flatMap({ .fromProtoMessage($0) }))
		res.returnType = message.returnType.toValue.flatMap({ .fromProtoMessage($0) })
		res.definedInType = message.definedInType.toValue.flatMap({ .fromProtoMessage($0) })
		res.parserData = message.parserData.toValue.flatMap({ .fromProtoMessage($0) })
		return res
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		guard let rhs = object as? Subscript else { return false }
		if self.parameters != rhs.parameters { return false }
		if self.returnTypeName != rhs.returnTypeName { return false }
		if self.readAccess != rhs.readAccess { return false }
		if self.writeAccess != rhs.writeAccess { return false }
		if self.annotations != rhs.annotations { return false }
		if self.definedInTypeName != rhs.definedInTypeName { return false }
		if self.attributes != rhs.attributes { return false }
		return true
	}
	
    /// Method parameters
    var parameters: [MethodParameter]

    /// Return value type name used in declaration, including generic constraints, i.e. `where T: Equatable`
    var returnTypeName: TypeName

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
        return returnTypeName.isOptional
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

    /// Whether method is final
    var isFinal: Bool {
        return attributes[Attribute.Identifier.final.name] != nil
    }

    /// Variable read access level, i.e. `internal`, `private`, `fileprivate`, `public`, `open`
    let readAccess: String

    /// Variable write access, i.e. `internal`, `private`, `fileprivate`, `public`, `open`.
    /// For immutable variables this value is empty string
    var writeAccess: String

    /// Whether variable is mutable or not
    var isMutable: Bool {
        return writeAccess != AccessLevel.none.rawValue
    }

    /// Annotations, that were created with // sourcery: annotation1, other = "annotation value", alterantive = 2
    let annotations: Annotations

    /// Reference to type name where the method is defined,
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

    /// Method attributes, i.e. `@discardableResult`
    let attributes: [String: Attribute]

    // Underlying parser data, never to be used by anything else
    // sourcery: skipEquality, skipDescription, skipCoding, skipJSExport
    /// :nodoc:
    var parserData: Structure?

    /// :nodoc:
    init(parameters: [MethodParameter] = [],
                returnTypeName: TypeName,
                accessLevel: (read: AccessLevel, write: AccessLevel) = (.internal, .internal),
                attributes: [String: Attribute] = [:],
                annotations: Annotations = [:],
                definedInTypeName: TypeName? = nil) {

        self.parameters = parameters
        self.returnTypeName = returnTypeName
        self.readAccess = accessLevel.read.rawValue
        self.writeAccess = accessLevel.write.rawValue
        self.attributes = attributes
        self.annotations = annotations
        self.definedInTypeName = definedInTypeName
    }

}
