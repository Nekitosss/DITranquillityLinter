//
//  FileParserResult.swift
//  Sourcery
//
//  Created by Krzysztof Zablocki on 11/01/2017.
//  Copyright © 2017 Pixle. All rights reserved.
//

import Foundation

final class FileParserResult: Codable, ProtobufBridgable {
	
	typealias ProtoStructure = Protobuf_FileParserResult
	
	var toProtoMessage: FileParserResult.ProtoStructure {
		var res = ProtoStructure()
		res.path = .init(value: self.path)
		res.module = .init(value: self.module)
		res.types = self.types.map({ $0.toProtoMessage })
		res.typealiases = self.typealiases.map({ $0.toProtoMessage })
		res.inlineRanges = self.inlineRanges.mapValues({ BytesRange(offset: Int64($0.location), length: Int64($0.length)).toProtoMessage })
		res.contentSha = .init(value: self.contentSha)
		res.linterVersion = self.linterVersion
		return res
	}
	
	static func fromProtoMessage(_ message: FileParserResult.ProtoStructure) -> FileParserResult {
		return FileParserResult(path: message.path.toValue,
								module: message.module.toValue,
								types: message.types.map({ .fromProtoMessage($0) }),
								typealiases: message.typealiases.map({ .fromProtoMessage($0) }),
								inlineRanges: message.inlineRanges.mapValues({
									let res = BytesRange.fromProtoMessage($0)
									return NSRange(location: Int(res.offset), length: Int(res.length))
								}),
								contentSha: message.contentSha.toValue!,
								linterVersion: message.linterVersion)
	}
	
    let path: String?
    let module: String?
    var types = [Type]() {
        didSet {
            types.forEach { type in
                guard type.module == nil, type.kind != "extensions" else { return }
                type.module = module
            }
        }
    }
	
	func updateRelationshipAfterDecoding() {
		func fillParent(child: Type, parent: Type) {
			child.parent = parent
			for childChildren in child.containedTypes {
				fillParent(child: childChildren, parent: child)
			}
		}
		
		for type in types {
			for child in type.containedTypes {
				fillParent(child: child, parent: type)
			}
			for typeali in type.typealiases {
				typeali.value.parent = type
			}
		}
	}
	
    var typealiases = [Typealias]()
    var inlineRanges = [String: NSRange]()

    var contentSha: String
    var linterVersion: String
	
	static func == (lhs: FileParserResult, rhs: FileParserResult) -> Bool {
		if lhs.path != rhs.path { return false }
		if lhs.module != rhs.module { return false }
		if lhs.types != rhs.types { return false }
		if lhs.typealiases != rhs.typealiases { return false }
		if lhs.inlineRanges != rhs.inlineRanges { return false }
		if lhs.contentSha != rhs.contentSha { return false }
		if lhs.linterVersion != rhs.linterVersion { return false }
		return true
	}

    init(path: String?, module: String?, types: [Type], typealiases: [Typealias] = [], inlineRanges: [String: NSRange] = [:], contentSha: String = "", linterVersion: String) {
        self.path = path
        self.module = module
        self.types = types
        self.typealiases = typealiases
        self.inlineRanges = inlineRanges
        self.contentSha = contentSha
        self.linterVersion = linterVersion

        types.forEach { type in type.module = module }
    }

}
