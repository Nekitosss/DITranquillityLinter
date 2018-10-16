import Foundation
import SourceKittenFramework

// sourcery: skipDescription
/// Descibes Swift class
final class Class: Type {
    /// Returns "class"
    override var kind: String { return "class" }
	
	override func isEqual(_ object: Any?) -> Bool {
		guard let rhs = object as? Class else { return false }
		return super.isEqual(rhs)
	}
	
    /// Whether type is final 
    var isFinal: Bool {
        return attributes[Attribute.Identifier.final.name] != nil
    }

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
						 filePath: String) {
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
			filePath: filePath
        )
    }
	
	required init(from decoder: Decoder) throws {
		try super.init(from: decoder)
	}
	
	override func encode(to encoder: Encoder) throws {
		try super.encode(to: encoder)
	}
}
