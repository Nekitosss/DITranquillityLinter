//
//  FileParserResult.swift
//  Sourcery
//
//  Created by Krzysztof Zablocki on 11/01/2017.
//  Copyright © 2017 Pixle. All rights reserved.
//

import Foundation

final class FileParserResult: Codable {
	
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

    var contentSha: String?
    var linterVersion: String
	
	static func ==(lhs: FileParserResult, rhs: FileParserResult) -> Bool {
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
