import Dispatch
import Foundation
import DITranquillityLinterFramework
import xcodeproj
import Basic


func projectFiles(project: XcodeProj, srcRoot: String) -> [String] {
	let srcAbsolute = AbsolutePath(srcRoot)
	let sourceFileReferences: [PBXFileElement]
	if let productName = ProcessInfo.processInfo.environment[XcodeEnvVariable.productName.rawValue],
		let target = project.pbxproj.targets(named: productName).first,
		let sourceFiles = try? target.sourceFiles() {
		sourceFileReferences = sourceFiles
		print("Get source files from target")
	} else {
		print("Get all source files")
		sourceFileReferences = project.pbxproj.sourcesBuildPhases.flatMap({ $0.files.compactMap({ $0.file }) })
	}
	return sourceFileReferences.compactMap({ (element: PBXFileElement) -> String? in
		guard let fullPath = (try? element.fullPath(sourceRoot: srcAbsolute))??.asString else { return nil }
		// Warning: URL with spaces not allowed, file will be excluded if we will use Foundation.URL, so we use strings
		return fullPath
	})
}

DispatchQueue.global().async {
	let tokenizer = Tokenizer()
	var files: [String] = []
	
	let enironment = ProcessInfo.processInfo.environment
	if let srcRoot = enironment[XcodeEnvVariable.srcRoot.rawValue] {
		print("Found $SRCROOT.")
		if let mainProjPath = enironment[XcodeEnvVariable.projectFilePath.rawValue],
			let mainProj = try? XcodeProj(pathString: mainProjPath) {
			print("Found main project.")
			TimeRecorder.common.start(event: .collectSource)
			files += projectFiles(project: mainProj, srcRoot: srcRoot)
			TimeRecorder.common.end(event: .collectSource)
		}
	} else {
		// TMP for debug
		print("Using tmp debug path")
		let srcRoot = "/Users/nikitapatskov/Develop/ios.client.fork2/"
		let project = try! XcodeProj(pathString: srcRoot + "AtiClient.xcodeproj")
		TimeRecorder.common.start(event: .collectSource)
		let source = projectFiles(project: project, srcRoot: srcRoot)
		TimeRecorder.common.end(event: .collectSource)
		files = source
	}
	
	let result = tokenizer.process(files: Array(Set(files)))
	TimeRecorder.common.end(event: .total)
	if result {
		exit(EXIT_SUCCESS)
	} else {
		exit(EXIT_FAILURE)
	}
}

dispatchMain()
