
import Foundation
import SourceKittenFramework

final class FileContainer {
	
	private var value: [String: File] = [:]
	private let mutex = PThreadMutex(normal: ())
	
	func getOrCreateFile(by key: String) -> File? {
		return mutex.sync {
			if let file = value[key] {
				return file
			} else if let file = File(path: key) {
				value[key] = file
				return file
			} else {
				return nil
			}
		}
	}
	
	func set(value newValue: File?, for key: String) {
		mutex.sync {
			value[key] = newValue
		}
	}
	
}
