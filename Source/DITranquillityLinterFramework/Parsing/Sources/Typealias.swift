import Foundation
import SourceKittenFramework

// sourcery: skipJSExport
/// :nodoc:
@objcMembers final class Typealias: NSObject, Typed, SourceryModel, Codable {
    // New typealias name
    let aliasName: String

    // Target name
    let typeName: TypeName

    // sourcery: skipEquality, skipDescription
    var type: Type?
	
	var file: File

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

    // TODO: access level

    init(aliasName: String = "", typeName: TypeName, parent: Type? = nil, file: File) {
        self.aliasName = aliasName
        self.typeName = typeName
        self.parent = parent
        self.parentName = parent?.name
		self.file = file
    }
}
