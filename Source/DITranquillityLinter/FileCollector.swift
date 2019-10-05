
import Foundation
import DITranquillityLinterFramework
import XcodeProj

final class FileCollector {
	
	private let projectFileExtractor: ProjectFileExtractor
	
	init(projectFileExtractor: ProjectFileExtractor) {
		self.projectFileExtractor = projectFileExtractor
	}
	
	func collectSourceFiles() throws -> [String] {
		
		let srcRoot = XcodeEnvVariable.srcRoot.value() ?? XcodeEnvVariable.srcRoot.defaultValue
		let defaultProjectFile = EnvVariable.testableProjectFolder.value() + EnvVariable.testableProjectName.value()
		let mainProjectPath = XcodeEnvVariable.projectFilePath.value() ?? defaultProjectFile
		let project = try XcodeProj(pathString: mainProjectPath)
		
		TimeRecorder.start(event: .collectSource)
		let files = projectFileExtractor.extractProjectFiles(from: project, srcRoot: srcRoot)
		TimeRecorder.end(event: .collectSource)
		
		return Array(Set(files))
	}
}
