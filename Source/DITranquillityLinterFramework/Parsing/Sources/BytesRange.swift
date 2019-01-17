


import Foundation

struct BytesRange: Codable, Equatable {

    let offset: Int64
    let length: Int64
}

extension BytesRange {
	
	init(range: (offset: Int64, length: Int64)) {
		self.init(offset: range.offset, length: range.length)
	}
}
