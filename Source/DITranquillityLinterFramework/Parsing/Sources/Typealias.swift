import Foundation
import SourceKittenFramework

// sourcery: skipJSExport
/// :nodoc:
final class Typealias: NSObject, Typed, Codable {
	
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
