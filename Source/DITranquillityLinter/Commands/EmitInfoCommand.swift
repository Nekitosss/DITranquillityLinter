//
//  EmitInfoCommand.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 03/04/2019.
//

import Commandant
import Dispatch
import Foundation
import DITranquillityLinterFramework
import PathKit


struct EmitInfoCommand: CommandProtocol {
	
	let verb = "emit-info"
	
	let function = "Creates container info for further linting"
	
	private let fileCollector: FileCollector
	private let infoEmitter: ContainerInfoEmitter
	
	init(fileCollector: FileCollector, infoEmitter: ContainerInfoEmitter) {
		self.fileCollector = fileCollector
		self.infoEmitter = infoEmitter
	}
	
	func run(_ options: OptionalLintOptions) -> Result<(), CommandantError<()>> {
		LintOptions.shared = options.extractOptionsFromYMLIfProvided()
		guard let outputPath = options.outputPath else {
			return .failure(.usageError(description: "Output path for not provided. Please specify it using '-o' option."))
		}
		
		do {
			let files = try fileCollector.collectSourceFiles()
			
			let normalizedOutput = Path(outputPath).normalize().url
			let successed = try infoEmitter.process(files: files, outputFilePath: normalizedOutput)
			TimeRecorder.end(event: .total)
			if successed {
				return .success(())
			} else {
				return .failure(.usageError(description: "Dependency graph is incorrect!"))
			}
		} catch {
			Log.error("Error during file parsing \(error)")
			return .failure(.usageError(description: "Error occured during file creation: \(error)"))
		}
	}
	
}
