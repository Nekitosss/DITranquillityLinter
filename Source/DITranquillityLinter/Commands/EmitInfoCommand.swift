//
//  EmitInfoCommand.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 03/04/2019.
//

import Result
import Commandant
import Dispatch
import Foundation
import DITranquillityLinterFramework
import xcodeproj
import PathKit
import Yams


struct EmitInfoCommand: CommandProtocol {
	
	let verb = "emit-info"
	
	let function = "Creates container info for further linting"
	
	private let projectFileExtractor = ProjectFileExtractor()
	
	func run(_ options: OptionalLintOptions) -> Result<(), CommandantError<()>> {
		LintOptions.shared = extractOptionsFromYMLIfProvided(options: options)
		do {
			let infoEmitter = ContainerInfoEmitter(isTestEnvironment: true)
			let srcRoot = XcodeEnvVariable.srcRoot.value() ?? XcodeEnvVariable.srcRoot.defaultValue
			let defaultProjectFile = EnvVariable.testableProjectFolder.value() + EnvVariable.testableProjectName.value()
			let mainProjectPath = XcodeEnvVariable.projectFilePath.value() ?? defaultProjectFile
			let project = try XcodeProj(pathString: mainProjectPath)
			
			TimeRecorder.start(event: .collectSource)
			let files = projectFileExtractor.extractProjectFiles(from: project, srcRoot: srcRoot)
			TimeRecorder.end(event: .collectSource)
			
			let outputPath = FileManager.default.currentDirectoryPath + "/\(XcodeEnvVariable.productName.value() ?? "module")_di_graph_info"
			let successed = try infoEmitter.process(files: Array(Set(files)), outputFilePath: URL(string: outputPath)!)
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
