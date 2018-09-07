import Dispatch
import Foundation
import DITranquillityLinterFramework

DispatchQueue.global().async {
	let tokenizer = Tokenizer()
	let url = URL(fileURLWithPath: "/Users/nikita/development/DITranquillityLinter/LintableProject")
	let enumerator = FileManager.default.enumerator(at: url,
													includingPropertiesForKeys: [],
													options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
														print("directoryEnumerator error at \(url): ", error)
														return true
	})!
	
	var urls: [URL] = []
	for case let fileURL as URL in enumerator where fileURL.pathExtension == "swift" {
		urls.append(fileURL)
	}
	tokenizer.process(files: urls)
	print("end")
}

dispatchMain()
