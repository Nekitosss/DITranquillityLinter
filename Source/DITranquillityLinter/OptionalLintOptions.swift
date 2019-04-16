
import Foundation
import Commandant
import DITranquillityLinterFramework
import Yams

struct OptionalLintOptions: Codable {
	var logLevel: String?
	var commonCachePath: String?
	var localCachePath: String?
	var shouldRecordTime: Bool?
	var yml: String?
	var outputPath: String?
	
	func extractOptionsFromYMLIfProvided() -> LintOptions {
		var options = self
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
			Log.info(error)
		}
		return LintOptions(logLevel: options.logLevel, commonCachePath: options.commonCachePath, localCachePath: options.localCachePath, shouldRecordTime: options.shouldRecordTime ?? false, outputPath: options.outputPath)
	}
}


extension OptionalLintOptions: OptionsProtocol {
	
	public static func create(_ logLevel: String?) -> (_ commonCachePath: String?) -> (_ localCachePath: String?) -> (_ shouldRecordTime: Bool?) -> (_ yml: String?) -> (_ outputPath: String?) -> OptionalLintOptions {
		return { commonCachePath in { localCachePath in { shouldRecordTime in { yml in { outputPath in
			//			let level = Log.Level(rawValue: logLevel) ?? Log.Level.warnings
			return OptionalLintOptions(logLevel: logLevel, commonCachePath: commonCachePath, localCachePath: localCachePath, shouldRecordTime: shouldRecordTime, yml: yml, outputPath: outputPath)
			} } } } }
	}
	
	public static func evaluate(_ m: CommandMode) -> Result<OptionalLintOptions, CommandantError<CommandantError<()>>> {
		return create
			<*> m <| Option<String?>(key: "log-level", defaultValue: nil, usage: "level for log printing")
			<*> m <| Option<String?>(key: "common-cache-path", defaultValue: nil, usage: "path to common binary (UIKit, Cocoa, Foundation) parsing cache")
			<*> m <| Option<String?>(key: "local-cache-path", defaultValue: nil, usage: "path to project-related binary parsing cache")
			<*> m <| Option<Bool>(key: "record-time", defaultValue: false, usage: "log elapsed time")
			<*> m <| Option<String?>(key: "yml", defaultValue: ".dilint.yml", usage: "path to yml configuration file")
			<*> m <| Option<String?>(key: "o", defaultValue: "", usage: "path to output file")
		
	}
	
}
