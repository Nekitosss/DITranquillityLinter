



import SourceKittenFramework
import Foundation


struct TokenBuilderInfo {
	let functionName: String
	let invocationBody: String
	let tokenList: [DITokenConvertible]
	let substructureList: [SourceKitStructure]
	let bodyOffset: Int64
	let currentPartName: String?
	let argumentStack: [ArgumentInfo]
	let location: Location
	let parsingContext: GlobalParsingContext
	let containerParsingContext: ContainerParsingContext
	let content: NSString
	let file: File
	let diPartNameStack: [String]
}


protocol TokenBuilder: class {
	
	func build(using info: TokenBuilderInfo) -> DITokenConvertible?
	
}
