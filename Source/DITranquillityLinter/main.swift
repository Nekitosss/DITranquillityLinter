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
		if let podsRoot = enironment[XcodeEnvVariable.podsRoot.rawValue],
			let podsProject = try? XcodeProj(pathString: podsRoot + "/Pods.xcodeproj") {
			print("Found pods project.")
			TimeRecorder.common.start(event: .collectDependencies)
			files += projectFiles(project: podsProject, srcRoot: podsRoot)
			TimeRecorder.common.end(event: .collectDependencies)
		}
		
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
		let podsProject = try! XcodeProj(pathString: srcRoot + "Pods/Pods.xcodeproj")
		TimeRecorder.common.start(event: .collectSource)
		let source = projectFiles(project: project, srcRoot: srcRoot)
		TimeRecorder.common.end(event: .collectSource)
		TimeRecorder.common.start(event: .collectDependencies)
		let pods = projectFiles(project: podsProject, srcRoot: srcRoot + "/Pods")
		TimeRecorder.common.end(event: .collectDependencies)
		files = source + pods
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
