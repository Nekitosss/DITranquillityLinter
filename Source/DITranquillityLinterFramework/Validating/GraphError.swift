



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
}
