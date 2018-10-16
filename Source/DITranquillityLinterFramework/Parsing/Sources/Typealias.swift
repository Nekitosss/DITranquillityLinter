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
}
