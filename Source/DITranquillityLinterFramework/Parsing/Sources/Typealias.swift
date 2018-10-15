import Foundation
import SourceKittenFramework

// sourcery: skipJSExport
/// :nodoc:
@objcMembers final class Typealias: NSObject, Typed, SourceryModel {
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

    // sourcery:inline:Typealias.AutoCoding
        /// :nodoc:
        required init?(coder aDecoder: NSCoder) {
            guard let aliasName: String = aDecoder.decode(forKey: "aliasName") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["aliasName"])); fatalError() }; self.aliasName = aliasName
            guard let typeName: TypeName = aDecoder.decode(forKey: "typeName") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["typeName"])); fatalError() }; self.typeName = typeName
			guard let file: File = aDecoder.decode(forKey: "file") else { NSException.raise(NSExceptionName.parseErrorException, format: "Key '%@' not found.", arguments: getVaList(["file"])); fatalError() }; self.file = file
            self.type = aDecoder.decode(forKey: "type")
            self.parent = aDecoder.decode(forKey: "parent")
            self.parentName = aDecoder.decode(forKey: "parentName")
        }

        /// :nodoc:
        func encode(with aCoder: NSCoder) {
            aCoder.encode(self.aliasName, forKey: "aliasName")
            aCoder.encode(self.typeName, forKey: "typeName")
            aCoder.encode(self.type, forKey: "type")
            aCoder.encode(self.parent, forKey: "parent")
            aCoder.encode(self.parentName, forKey: "parentName")
        }
        // sourcery:end
}
