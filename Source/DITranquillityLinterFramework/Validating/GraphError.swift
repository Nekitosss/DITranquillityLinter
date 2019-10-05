



import Foundation

protocol XCodePrintable {
	var xcodeMessage: String { get }
}

/// Prints all founded errors to XCode
func print(xcodePrintable: [XCodePrintable]) {
	xcodePrintable.forEach {
		print($0.xcodeMessage)
	}
}

struct GraphError: Error, Equatable, XCodePrintable {
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
}

struct GraphWarning: Equatable, XCodePrintable {
	let infoString: String
	let location: Location
	
	var xcodeMessage: String {
		return [
			"\(location): ",
			"warning: ",
			infoString
			].joined()
	}
}
