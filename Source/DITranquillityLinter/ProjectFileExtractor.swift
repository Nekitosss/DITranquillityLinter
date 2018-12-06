import xcodeproj
import PathKit
import DITranquillityLinterFramework


final class ProjectFileExtractor {
	
	func extractProjectFiles(from project: XcodeProj, srcRoot: String) -> [String] {
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
}

