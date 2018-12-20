import Dispatch
import Foundation
import DITranquillityLinterFramework
import xcodeproj
import PathKit


private func projectFiles(project: XcodeProj, srcRoot: String) -> [String] {
	let srcAbsolute = Path(srcRoot)
	let sourceFileReferences: [PBXFileElement]
	if let productName = XcodeEnvVariable.productName.value(),
		let target = project.pbxproj.targets(named: productName).first,
		let sourceFiles = try? target.sourceFiles() {
		sourceFileReferences = sourceFiles
		print("Get source files from target")
	} else {
		print("Get all source files")
		sourceFileReferences = project.pbxproj.sourcesBuildPhases.flatMap({ $0.files.compactMap({ $0.file }) })
	}
	return sourceFileReferences.compactMap({
		// Warning: URL with spaces not allowed, file will be excluded if we will use Foundation.URL, so we use strings
		(try? $0.fullPath(sourceRoot: srcAbsolute))??.string
	})
}

func executeScript() {
	do {
		let tokenizer = Tokenizer(isTestEnvironment: false)
		let srcRoot = XcodeEnvVariable.srcRoot.value() ?? XcodeEnvVariable.srcRoot.defaultValue
		let defaultProjectFile = EnvVariable.testableProjectFolder.value() + EnvVariable.testableProjectName.value()
		let mainProjectPath = XcodeEnvVariable.projectFilePath.value() ?? defaultProjectFile
		let project = try XcodeProj(pathString: mainProjectPath)
		
		TimeRecorder.start(event: .collectSource)
		let files = projectFiles(project: project, srcRoot: srcRoot)
		TimeRecorder.end(event: .collectSource)
		
		let successed = try tokenizer.process(files: Array(Set(files)))
		TimeRecorder.end(event: .total)
		if successed {
			exit(EXIT_SUCCESS)
		} else {
			exit(EXIT_FAILURE)
		}
	} catch {
		Log.error("Error during file parsing \(error)")
		exit(EXIT_FAILURE)
	}
}

DispatchQueue.global().async(execute: executeScript)
dispatchMain()
