import Foundation
import SourceKittenFramework

// sourcery: skipDescription
/// Descibes Swift class
@objc(SwiftClass) @objcMembers final class Class: Type {
    /// Returns "class"
    override var kind: String { return "class" }

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
						 file: File) {
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
			file: file
        )
    }
	
	required init(from decoder: Decoder) throws {
		try super.init(from: decoder)
	}
	
	override func encode(to encoder: Encoder) throws {
		try super.encode(to: encoder)
	}

    // sourcery:inline:Class.AutoCoding
        /// :nodoc:
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }

        /// :nodoc:
        override func encode(with aCoder: NSCoder) {
            super.encode(with: aCoder)
        }
        // sourcery:end
}
