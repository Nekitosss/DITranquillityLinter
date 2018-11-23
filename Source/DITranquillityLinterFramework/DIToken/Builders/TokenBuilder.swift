



import SourceKittenFramework
import Foundation


struct TokenBuilderInfo {
	let functionName: String
	let invocationBody: String
	let tokenList: [DIToken]
	let substructureList: [[String : SourceKitRepresentable]]
	let bodyOffset: Int64
	let currentPartName: String?
	let argumentStack: [ArgumentInfo]
	let location: Location
	let parsingContext: ParsingContext
	let content: NSString
	let file: File
}


protocol TokenBuilder: class {
	
	func build(using info: TokenBuilderInfo) -> DIToken?
	
}
