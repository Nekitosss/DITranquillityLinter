
import Foundation
import SourceKittenFramework

final class FileContainer {
	
	var value: [String: File] = [:]
	private let monitor = NSObject()
	
	subscript(key: String) -> File? {
		get {
			objc_sync_enter(monitor)
			defer { objc_sync_exit(monitor) }
			if let file = value[key] {
				return file
			} else if let file = File(path: key) {
				self[key] = file
				return file
			} else {
				return nil
			}
		}
		set {
			
			objc_sync_enter(monitor)
			defer { objc_sync_exit(monitor) }
			value[key] = newValue
		}
	}
	
}
