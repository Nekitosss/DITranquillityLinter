



import Foundation

struct GraphError: Error, Equatable {
	let infoString: String
	let location: Location
	let kind: Kind
	
	enum Kind {
		case parsing
		case circularPartAppending
		case validation
	}
	
	var xcodeMessage: String {
		return [
			"\(location): ",
			"error: ",
			infoString
			].joined()
	}
	
	/// Prints all founded errors to XCode
	static func display(errorList: [GraphError]) {
		errorList.forEach {
			print($0.xcodeMessage)
		}
	}
}
