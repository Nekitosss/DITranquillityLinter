
import Foundation
import SourceKittenFramework

final class FileContainer {
	
	private var value: [String: File] = [:]
	private let monitor = NSObject()
	
	func getOrCreateFile(by key: String) -> File? {
		objc_sync_enter(monitor)
		defer { objc_sync_exit(monitor) }
		
		if let file = value[key] {
			return file
		} else if let file = File(path: key) {
			set(value: file, for: key)
			return file
		} else {
			return nil
		}
	}
	
	func set(value newValue: File?, for key: String) {
		objc_sync_enter(monitor)
		defer { objc_sync_exit(monitor) }
		value[key] = newValue
	}
	
}
