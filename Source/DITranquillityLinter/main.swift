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
	
	let srcRoot = "/Users/nikita/development/DITranquillityLinter/LintableProject/"
	let project = try! XcodeProj(pathString: srcRoot + "LintableProject.xcodeproj")
	let podsProject = try! XcodeProj(pathString: srcRoot + "Pods/Pods.xcodeproj")
	let paths = projectFiles(project: project, srcRoot: srcRoot) + projectFiles(project: podsProject, srcRoot: srcRoot)
	tokenizer.process(files: paths)
	print("end")
	exit(EXIT_SUCCESS)
}

dispatchMain()
