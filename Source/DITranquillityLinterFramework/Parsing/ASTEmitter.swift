import Foundation

typealias OutputFileMap = [String: OutputFileMapObject]

struct OutputFileMapObject: Codable {
  let astDump: String
  
  private enum CodingKeys: String, CodingKey {
    case astDump = "ast-dump"
  }
}

protocol ASTEmitterProtocol: class {
  
}

final class ASTEmitter: ASTEmitterProtocol {
  
  private let resultCacher: ResultCacher
  private let binaryFrameworkParser: BinaryFrameworkParser
  
  init(resultCacher: ResultCacher, binaryFrameworkParser: BinaryFrameworkParser) {
    self.resultCacher = resultCacher
    self.binaryFrameworkParser = binaryFrameworkParser
  }
  
  func emitAST(from swiftSourceFiles: [String]) throws -> [String] {
    let outputFileMap = swiftSourceFiles.reduce(into: [:]) { $0[$1] = OutputFileMapObject(astDump: self.createASTFileURL(filePath: $1)) }
    let outputFileMapPath = try resultCacher.saveFiles(data: outputFileMap, fileName: "outputFileMap", isCommonCache: false)
    try launchAstDump(outputFileMapPath: outputFileMapPath.path, swiftSourceFiles: swiftSourceFiles)
		return outputFileMap.map { $1.astDump }
  }
  
  private func launchAstDump(outputFileMapPath: String, swiftSourceFiles: [String]) throws {
    let sourceFilesPaths = swiftSourceFiles.joined(separator: " ")
    let frameworkPaths = try binaryFrameworkParser.getUserDefinedBinaryFrameworkNames()
    let frameworksString = frameworkPaths.reduce("") { $0 + " -F " + $1.path } + " -F \(EnvVariable.frameworkSearchPath.value())"
    let (target, sdk) = binaryFrameworkParser.createCommandLineArgumentInfoForSourceParsing()
    let command = "swiftc -dump-ast -module-name Name -target \(target) -sdk \(sdk) -output-file-map=\(outputFileMapPath) \(frameworksString) \(sourceFilesPaths)"
    shell(command: command)
  }
  
  private func createASTFileURL(filePath: String) -> String {
    let cacheDirectory = resultCacher.cachePath(isCommonCache: false)
    let fileName = filePath.bridge().lastPathComponent.bridge().deletingPathExtension + ".ast"
    return cacheDirectory + fileName
  }
}
