import Foundation
import SourceKittenFramework

// sourcery: skipJSExport
/// :nodoc:
final class Typealias: NSObject, Typed, Codable, ProtobufBridgable {
	
	typealias ProtoStructure = Protobuf_Typealias
	
	var toProtoMessage: Typealias.ProtoStructure {
		var res = ProtoStructure()
		res.aliasName = aliasName
		res.typeName = typeName.toProtoMessage
		res.type = .init(value: type?.toProtoMessage)
		res.filePath = filePath
		res.parent = .init(value: nil)
		res.parentName = ""
		return res
	}
	
	static func fromProtoMessage(_ message: Protobuf_Typealias) -> Typealias {
		let res = Typealias(aliasName: message.aliasName,
							typeName: .fromProtoMessage(message.typeName),
							parent: message.parent.toValue.flatMap({ .fromProtoMessage($0) }),
							filePath: message.filePath)
		res.type = message.type.toValue.flatMap({ .fromProtoMessage($0) })
		return res
	}
	
    // New typealias name
    let aliasName: String

    // Target name
    let typeName: TypeName

    // sourcery: skipEquality, skipDescription
    var type: Type?
	
	var filePath: String

    // sourcery: skipEquality, skipDescription
    var parent: Type? {
        didSet {
            parentName = parent?.name
        }
    }

    var parentName: String?

    var name: String {
        if let parentName = parent?.name {
            return "\(parentName).\(aliasName)"
        } else {
            return aliasName
        }
    }

    init(aliasName: String = "", typeName: TypeName, parent: Type? = nil, filePath: String) {
        self.aliasName = aliasName
        self.typeName = typeName
        self.parent = parent
        self.parentName = parent?.name
		self.filePath = filePath
    }
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(aliasName, forKey: .aliasName)
		try container.encode(typeName, forKey: .typeName)
		try container.encode(type, forKey: .type)
		try container.encode(filePath, forKey: .filePath)
		try container.encode(parentName, forKey: .parentName)
		// DO NOT ENCODE PARENT
		
	}
}
