import Dispatch
import Foundation
import DITranquillityLinterFramework
import xcodeproj
import Basic


func projectFiles(project: XcodeProj, srcRoot: String) -> [URL] {
	let srcAbsolute = AbsolutePath(srcRoot)
	let sourceFileReferences = project.pbxproj.sourcesBuildPhases.flatMap({ $0.files.compactMap({ $0.file }) })
	return sourceFileReferences.compactMap({ (element: PBXFileElement) -> URL? in
		guard let fullPath = (try? element.fullPath(sourceRoot: srcAbsolute))??.asString else { return nil }
		return URL(string: fullPath)
	})
}

DispatchQueue.global().async {
	let tokenizer = Tokenizer()
	var files: [URL] = []
	
	let enironment = ProcessInfo.processInfo.environment
	if let srcRoot = enironment[XcodeEnvVariable.srcRoot.rawValue] {
		print("Found $SRCROOT.")
		if let podsRoot = enironment[XcodeEnvVariable.podsRoot.rawValue],
			let podsProject = try? XcodeProj(pathString: podsRoot + "/Pods.xcodeproj") {
			print("Found pods project.")
			files += projectFiles(project: podsProject, srcRoot: podsRoot)
		}
		
		if let mainProjPath = enironment[XcodeEnvVariable.projectFilePath.rawValue],
			let mainProj = try? XcodeProj(pathString: mainProjPath) {
			print("Found main project.")
			files += projectFiles(project: mainProj, srcRoot: srcRoot)
		}
	} else {
		// TMP for debug
		print("Using tmp debug path")
		let srcRoot = "/Users/nikitapatskov/Develop/DITranquillityLinter/LintableProject/"
		let project = try! XcodeProj(pathString: srcRoot + "LintableProject.xcodeproj")
		let podsProject = try! XcodeProj(pathString: srcRoot + "Pods/Pods.xcodeproj")
		files = projectFiles(project: project, srcRoot: srcRoot) + projectFiles(project: podsProject, srcRoot: srcRoot + "/Pods")
	}
	
	if tokenizer.process(files: files) {
		exit(EXIT_SUCCESS)
	} else {
		exit(EXIT_FAILURE)
	}
}

dispatchMain()
