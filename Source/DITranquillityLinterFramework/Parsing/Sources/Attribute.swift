import Foundation
import SourceKittenFramework

enum AttributeArgumentValue: Equatable, Codable {
	case stringValue(String)
	case boolValue(Bool)
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		do {
			let leftValue = try container.decode(String.self, forKey: .stringValue)
			self = .stringValue(leftValue)
		} catch {
			let rightValue = try container.decode(Bool.self, forKey: .boolValue)
			self = .boolValue(rightValue)
		}
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case .stringValue(let value):
			try container.encode(value, forKey: .stringValue)
		case .boolValue(let value):
			try container.encode(value, forKey: .boolValue)
		}
	}
	
	enum CodingKeys: String, CodingKey {
		case stringValue
		case boolValue
	}
}

extension Structure: Codable {
	
	public init(from decoder: Decoder) throws {
		fatalError()
	}
	
	public func encode(to encoder: Encoder) throws {
		fatalError()
	}
	
	static func ==(lhs: Structure, rhs: Structure) -> Bool {
		return true
	}
}

extension File: Codable, Equatable {
	public static func == (lhs: File, rhs: File) -> Bool {
		return true
	}
	
	
	public convenience init(from decoder: Decoder) throws {
		fatalError()
	}
	
	public func encode(to encoder: Encoder) throws {
		fatalError()
	}
}

typealias AttributeArguments = [String: AttributeArgumentValue]
/// Describes Swift attribute
struct Attribute: Codable, Equatable {

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
