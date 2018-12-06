import Result
import Commandant
import Dispatch
import Foundation
import DITranquillityLinterFramework
import xcodeproj
import PathKit


struct LintCommand: CommandProtocol {
	
	let verb = "lint"
	
	let function = "Lint objects dependency graph in project"
	
	private let projectFileExtractor = ProjectFileExtractor()
	
	func run(_ options: LintOptions) -> Result<(), CommandantError<()>> {
		
		do {
			let tokenizer = Tokenizer(isTestEnvironment: false)
			let srcRoot = XcodeEnvVariable.srcRoot.value() ?? XcodeEnvVariable.srcRoot.defaultValue
			let defaultProjectFile = EnvVariable.testableProjectFolder.value() + EnvVariable.testableProjectName.value()
			let mainProjectPath = XcodeEnvVariable.projectFilePath.value() ?? defaultProjectFile
			let project = try XcodeProj(pathString: mainProjectPath)
			
			TimeRecorder.start(event: .collectSource)
			let files = projectFileExtractor.extractProjectFiles(from: project, srcRoot: srcRoot)
			TimeRecorder.end(event: .collectSource)
			
			let successed = try tokenizer.process(files: Array(Set(files)))
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


struct LintOptions: OptionsProtocol {
	
	let yml: String
	
	
	static func create(_ yml: String) -> LintOptions {
		return LintOptions(yml: yml)
	}
	
	static func evaluate(_ m: CommandMode) -> Result<LintOptions, CommandantError<CommandantError<()>>> {
		return create
			<*> m <| Option(key: "yml",
							defaultValue: "",
							usage: "path to yml configuration file")
	}
	
}
