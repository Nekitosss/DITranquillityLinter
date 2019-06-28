



import SourceKittenFramework
import Foundation
import ASTVisitor

struct TokenBuilderInfo {
	let functionName: String
	let tokenList: [DITokenConvertible]
	let node: ASTNode
	let currentPartName: String?
	let parsingContext: GlobalParsingContext
	let containerParsingContext: ContainerParsingContext
	let diPartNameStack: [String]
}


protocol TokenBuilder: class {
	
	func build(using info: TokenBuilderInfo) -> DITokenConvertible?
	
}
