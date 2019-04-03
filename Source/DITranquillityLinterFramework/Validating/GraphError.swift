



import Foundation

struct GraphError: Error, Equatable {
	let infoString: String
	let location: Location
	
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
