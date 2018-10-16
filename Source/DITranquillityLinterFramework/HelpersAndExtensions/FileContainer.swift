
import Foundation
import SourceKittenFramework

final class FileContainer {
	
	var value: [String: File] = [:]
	
	subscript(key: String) -> File? {
		get {
			if let file = value[key] {
				return file
			} else if let file = File(path: key) {
				self[key] = file
				return file
			} else {
				return nil
			}
		}
		set { value[key] = newValue }
	}
	
}
