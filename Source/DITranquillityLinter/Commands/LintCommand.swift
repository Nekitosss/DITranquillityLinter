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
	
	private let projectFileExtractor = ProjectFileExtractor()
	
	func run(_ options: OptionalLintOptions) -> Result<(), CommandantError<()>> {
		LintOptions.shared = extractOptionsFromYMLIfProvided(options: options)
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
	
	
	private func extractOptionsFromYMLIfProvided(options: OptionalLintOptions) -> LintOptions {
		var options = options
		do {
			if let ymlPath = options.yml.map(URL.init(fileURLWithPath:)) {
				let data = try Data(contentsOf: ymlPath)
				let encodedYaml = String(data: data, encoding: .utf8) ?? ""
				let decoder = YAMLDecoder()
				let decodedOptions: OptionalLintOptions = try decoder.decode(from: encodedYaml)
				options.logLevel = options.logLevel ?? decodedOptions.logLevel
				options.commonCachePath = options.commonCachePath ?? decodedOptions.commonCachePath
				options.localCachePath = options.localCachePath ?? decodedOptions.localCachePath
				options.shouldRecordTime = (options.shouldRecordTime ?? false) || (decodedOptions.shouldRecordTime ?? false)
			}
		} catch {
			Log.error(error)
		}
		return LintOptions(logLevel: options.logLevel, commonCachePath: options.commonCachePath, localCachePath: options.localCachePath, shouldRecordTime: options.shouldRecordTime ?? false)
	}
	
}


struct OptionalLintOptions: Codable {
	var logLevel: String?
	var commonCachePath: String?
	var localCachePath: String?
	var shouldRecordTime: Bool?
	var yml: String?
}


extension OptionalLintOptions: OptionsProtocol {
	
	public static func create(_ logLevel: String?) -> (_ commonCachePath: String?) -> (_ localCachePath: String?) -> (_ shouldRecordTime: Bool?) -> (_ yml: String?) -> OptionalLintOptions {
		return { commonCachePath in { localCachePath in { shouldRecordTime in { yml in
//			let level = Log.Level(rawValue: logLevel) ?? Log.Level.warnings
			return OptionalLintOptions(logLevel: logLevel, commonCachePath: commonCachePath, localCachePath: localCachePath, shouldRecordTime: shouldRecordTime, yml: yml)
			} } } }
	}
	
	public static func evaluate(_ m: CommandMode) -> Result<OptionalLintOptions, CommandantError<CommandantError<()>>> {
		return create
			<*> m <| Option<String?>(key: "log-level", defaultValue: nil, usage: "level for log printing")
			<*> m <| Option<String?>(key: "common-cache-path", defaultValue: nil, usage: "path to common binary (UIKit, Cocoa, Foundation) parsing cache")
			<*> m <| Option<String?>(key: "local-cache-path", defaultValue: nil, usage: "path to project-related binary parsing cache")
			<*> m <| Option<Bool>(key: "record-time", defaultValue: false, usage: "log elapsed time")
			<*> m <| Option<String?>(key: "yml", defaultValue: ".dilint.yml", usage: "path to yml configuration file")
		
	}
	
}
