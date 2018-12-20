import Foundation
import SourceKittenFramework

extension Structure: Codable, ProtobufBridgable {
	
	typealias ProtoStructure = Protobuf_Structure
	
	static func fromProtoMessage(_ message: Structure.ProtoStructure) -> Structure {
		let codableInfo = CodableInfo(codableValues: message.dictionary.mapValue.mapValues({ TypedCodableValue.fromProtoMessage($0) }))
		return Structure(sourceKitResponse: codableInfo.sourceKitObjects)
	}
	
	var toProtoMessage: Structure.ProtoStructure {
		var structure = ProtoStructure()
		structure.dictionary.mapValue = CodableInfo(sourceKitObjects: self.dictionary).codableValues.mapValues({ $0.toProtoMessage })
		return structure
	}
	
	enum CodingKeys: String, CodingKey {
		case dictionary
	}
	
	struct CodableInfo: Codable {
		let codableValues: [String: TypedCodableValue]
		
		var sourceKitObjects: [String: SourceKitRepresentable] {
			return codableValues.mapValues { $0.sourceKitValue }
		}
		
		init(codableValues: [String: TypedCodableValue]) {
			self.codableValues = codableValues
		}
		
		init(sourceKitObjects: [String: SourceKitRepresentable]) {
			self.codableValues = sourceKitObjects.mapValues { TypedCodableValue(sourceKitRepresentable: $0) }
		}
	}
	
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		let res = try values.decode(CodableInfo.self, forKey: .dictionary)
		self.init(sourceKitResponse: res.sourceKitObjects)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		let codableInfo = CodableInfo(sourceKitObjects: dictionary)
		try container.encode(codableInfo, forKey: .dictionary)
	}
	
	static func == (lhs: Structure, rhs: Structure) -> Bool {
		return true
	}
}

typealias AttributeArguments = [String: TypedCodableValue]
/// Describes Swift attribute
struct Attribute: Codable, Equatable, ProtobufBridgable {

	typealias ProtoStructure = Protobuf_Attribute
	
	var toProtoMessage: Attribute.ProtoStructure {
		var structure = ProtoStructure()
		structure.name = self.name
		structure.arguments = self.arguments.mapValues({ $0.toProtoMessage })
		structure.description_p = description
		structure.parserData = .init(value: self.parserData?.toProtoMessage)
		return structure
	}
	
	static func fromProtoMessage(_ message: Attribute.ProtoStructure) -> Attribute {
		var res = Attribute(name: message.name,
						 arguments: message.arguments.mapValues({ TypedCodableValue.fromProtoMessage($0) }),
						 description: message.description_p)
		res.parserData = message.parserData.toValue.flatMap({ Structure.fromProtoMessage($0) })
		return res
	}
	
    /// Attribute name
    let name: String

    /// Attribute arguments
    let arguments: AttributeArguments

	/// Attribute description that can be used in a template.
    let description: String

    var parserData: Structure?

	/// :nodoc:
    init(name: String, arguments: AttributeArguments = [:], description: String? = nil) {
        self.name = name
        self.arguments = arguments
        self.description = description ?? "@\(name)"
    }

    /// :nodoc:
    enum Identifier: String, Codable {
        case convenience
        case required
        case available
        case discardableResult
        case GKInspectable = "gkinspectable"
        case objc
        case objcMembers
        case nonobjc
        case NSApplicationMain
        case NSCopying
        case NSManaged
        case UIApplicationMain
        case IBOutlet = "iboutlet"
        case IBInspectable = "ibinspectable"
        case IBDesignable = "ibdesignable"
        case autoclosure
        case convention
        case mutating
        case escaping
        case final
        case open
        case `public` = "public"
        case `internal` = "internal"
        case `private` = "private"
        case `fileprivate` = "fileprivate"
        case publicSetter = "setter_access.public"
        case internalSetter = "setter_access.internal"
        case privateSetter = "setter_access.private"
        case fileprivateSetter = "setter_access.fileprivate"

        init?(identifier: String) {
            let identifier = identifier.trimmingPrefix("source.decl.attribute.")
            if identifier == "objc.name" {
                self.init(rawValue: "objc")
            } else {
                self.init(rawValue: identifier)
            }
        }

        static func from(string: String) -> Identifier? {
            switch string {
            case "GKInspectable":
                return Identifier.GKInspectable
            case "objc":
                return .objc
            case "IBOutlet":
                return .IBOutlet
            case "IBInspectable":
                return .IBInspectable
            case "IBDesignable":
                return .IBDesignable
            default:
                return Identifier(rawValue: string)
            }
        }

        var name: String {
            switch self {
            case .GKInspectable:
                return "GKInspectable"
            case .objc:
                return "objc"
            case .IBOutlet:
                return "IBOutlet"
            case .IBInspectable:
                return "IBInspectable"
            case .IBDesignable:
                return "IBDesignable"
            case .fileprivateSetter:
                return "fileprivate"
            case .privateSetter:
                return "private"
            case .internalSetter:
                return "internal"
            case .publicSetter:
                return "public"
            default:
                return rawValue
            }
        }

        var description: String {
            return hasAtPrefix ? "@\(name)" : name
        }

        var hasAtPrefix: Bool {
            switch self {
            case .available,
                 .discardableResult,
                 .GKInspectable,
                 .objc,
                 .objcMembers,
                 .nonobjc,
                 .NSApplicationMain,
                 .NSCopying,
                 .NSManaged,
                 .UIApplicationMain,
                 .IBOutlet,
                 .IBInspectable,
                 .IBDesignable,
                 .autoclosure,
                 .convention,
                 .escaping:
                return true
            default:
                return false
            }
        }
    }
}
