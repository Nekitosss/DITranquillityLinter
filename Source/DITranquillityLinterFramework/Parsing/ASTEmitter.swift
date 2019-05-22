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
  
  init(resultCacher: ResultCacher) {
    self.resultCacher = resultCacher
  }
  
  func emitAST(from swiftSourceFiles: [String]) throws -> [String] {
    let outputFileMap = swiftSourceFiles.reduce(into: [:]) { $0[$1] = OutputFileMapObject(astDump: self.createASTFileURL(filePath: $1)) }
    let outputFileMapPath = try resultCacher.cacheFiles(data: outputFileMap, fileName: "outputFileMap", isCommonCache: false)
    launchAstDump(outputFileMapPath: outputFileMapPath.path, swiftSourceFiles: swiftSourceFiles)
    return []
  }
  
  private func launchAstDump(outputFileMapPath: String, swiftSourceFiles: [String]) {
    let sourceFilesPaths = swiftSourceFiles.joined(separator: " ")
    shell(command: "swiftc -dump-ast -module-name Name -output-file-map \(outputFileMapPath) \(sourceFilesPaths)")
  }
  
  private func createASTFileURL(filePath: String) -> String {
    let cacheDirectory = resultCacher.cachePath(isCommonCache: false)
    let fileName = filePath.bridge().lastPathComponent.bridge().deletingPathExtension + ".ast"
    return cacheDirectory + "/" + fileName
  }
}
