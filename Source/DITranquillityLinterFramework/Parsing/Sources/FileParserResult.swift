//
//  FileParserResult.swift
//  Sourcery
//
//  Created by Krzysztof Zablocki on 11/01/2017.
//  Copyright © 2017 Pixle. All rights reserved.
//

import Foundation

// sourcery: skipJSExport
/// :nodoc:
final class FileParserResult: NSObject {
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
    var typealiases = [Typealias]()
    var inlineRanges = [String: NSRange]()

    var contentSha: String?
    var sourceryVersion: String

    init(path: String?, module: String?, types: [Type], typealiases: [Typealias] = [], inlineRanges: [String: NSRange] = [:], contentSha: String = "", sourceryVersion: String = "") {
        self.path = path
        self.module = module
        self.types = types
        self.typealiases = typealiases
        self.inlineRanges = inlineRanges
        self.contentSha = contentSha
        self.sourceryVersion = sourceryVersion

        types.forEach { type in type.module = module }
    }

}
