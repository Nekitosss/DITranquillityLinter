import Result
import Commandant
import Dispatch
import Foundation
import DITranquillityLinterFramework
import xcodeproj
import PathKit
import Yams


struct LintCommand: CommandProtocol {
	
	let verb = "lint"
	
	let function = "Lint objects dependency graph in project"
	
	private let fileCollector: FileCollector
	private let tokenizer: Tokenizer
	
	init(fileCollector: FileCollector, tokenizer: Tokenizer) {
		self.fileCollector = fileCollector
		self.tokenizer = tokenizer
	}
	
	func run(_ options: OptionalLintOptions) -> Result<(), CommandantError<()>> {
		LintOptions.shared = options.extractOptionsFromYMLIfProvided()
		do {
			let files = try fileCollector.collectSourceFiles()
			
			let successed = try tokenizer.process(files: files)
			TimeRecorder.end(event: .total)
			if successed {
				return .success(())
			} else {
				return .failure(.usageError(description: "Dependency graph is incorrect!"))
			}
		} catch {
			Log.error("Error during file parsing \(error)")
			return .failure(.usageError(description: "Error occured during linting: \(error)"))
		}
	}
	
	
	
}

