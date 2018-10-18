import Dispatch
import Foundation
import DITranquillityLinterFramework
import xcodeproj
import Basic


func projectFiles(project: XcodeProj, srcRoot: String) -> [String] {
	let srcAbsolute = AbsolutePath(srcRoot)
	let sourceFileReferences = project.pbxproj.sourcesBuildPhases.flatMap({ $0.files.compactMap({ $0.file }) })
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
		let srcRoot = "/Users/nikita/development/fooddly/Fooddly/"
		let project = try! XcodeProj(pathString: srcRoot + "Fooddly.xcodeproj")
		TimeRecorder.common.start(event: .collectSource)
		let source = projectFiles(project: project, srcRoot: srcRoot)
		TimeRecorder.common.end(event: .collectSource)
		files = source
	}
	
	let result = tokenizer.process(files: files)
	TimeRecorder.common.end(event: .total)
	if result {
		exit(EXIT_SUCCESS)
	} else {
		exit(EXIT_FAILURE)
	}
}

dispatchMain()
