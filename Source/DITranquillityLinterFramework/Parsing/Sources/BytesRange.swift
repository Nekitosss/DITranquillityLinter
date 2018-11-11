


import Foundation

struct BytesRange: Codable, Equatable, ProtobufBridgable {

    let offset: Int64
    let length: Int64

	typealias ProtoStructure = Protobuf_BytesRange
	
	var toProtoMessage: BytesRange.ProtoStructure {
		var res = ProtoStructure()
		res.offset = offset
		res.length = length
		return res
	}
	
	static func fromProtoMessage(_ message: Protobuf_BytesRange) -> BytesRange {
		return .init(offset: message.offset, length: message.length)
	}
	
}

extension BytesRange {
	
	init(range: (offset: Int64, length: Int64)) {
		self.init(offset: range.offset, length: range.length)
	}
}
