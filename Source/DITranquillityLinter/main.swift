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
	return sourceFileReferences.compactMap({ (element: PBXFileElement) -> String? in
		guard let fullPath = (try? element.fullPath(sourceRoot: srcAbsolute))??.string else { return nil }
		// Warning: URL with spaces not allowed, file will be excluded if we will use Foundation.URL, so we use strings
		return fullPath
	})
}

func executeScript() {
	let tokenizer = Tokenizer(isTestEnvironment: false)
	var files: [String] = []
	
	if let srcRoot = XcodeEnvVariable.srcRoot.value() {
		print("Found $SRCROOT.")
		if let mainProjPath = XcodeEnvVariable.projectFilePath.value(),
			let mainProj = try? XcodeProj(pathString: mainProjPath) {
			print("Found main project.")
			TimeRecorder.start(event: .collectSource)
			files += projectFiles(project: mainProj, srcRoot: srcRoot)
			TimeRecorder.end(event: .collectSource)
		}
	} else {
		// TMP for debug
		print("Using tmp debug path")
		let srcRoot = EnvVariable.testableProjectFolder.value()
		let testableProjectName = EnvVariable.testableProjectName.value()
		do {
			let project = try XcodeProj(pathString: srcRoot + testableProjectName)
			TimeRecorder.start(event: .collectSource)
			let source = projectFiles(project: project, srcRoot: srcRoot)
			TimeRecorder.end(event: .collectSource)
			files = source
		} catch {
			print("XCode project could not be parsed")
		}
	}
	
	let result = tokenizer.process(files: Array(Set(files)))
	TimeRecorder.end(event: .total)
	if result {
		exit(EXIT_SUCCESS)
	} else {
		exit(EXIT_FAILURE)
	}
}

DispatchQueue.global().async(execute: executeScript)
dispatchMain()
