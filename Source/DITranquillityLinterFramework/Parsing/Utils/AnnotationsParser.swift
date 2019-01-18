//
// Created by Krzysztof Zablocki on 31/12/2016.
// Copyright (c) 2016 Pixle. All rights reserved.
//

import Foundation
import SourceKittenFramework

enum TypedCodableValue: Codable, Equatable {
	
	case floatValue(Float)
	case boolValue(Bool)
	case stringValue(String)
	case int64Value(Int64)
	indirect case arrayValue([TypedCodableValue])
	indirect case dictionaryValue([String: TypedCodableValue])
	
	var sourceKitValue: SourceKitRepresentable {
		switch self {
		case .floatValue(let value):
			return Int64(exactly: value) ?? 0
		case .boolValue(let value):
			return value
		case .int64Value(let value):
			return value
		case .stringValue(let value):
			return value
		case .arrayValue(let value):
			return value.map({ $0.sourceKitValue })
		case .dictionaryValue(let value):
			return value.mapValues({ $0.sourceKitValue })
		}
	}
	
	init(sourceKitRepresentable: SourceKitRepresentable) {
		switch sourceKitRepresentable {
		case let value as [SourceKitRepresentable]:
			self = .arrayValue(value.map(TypedCodableValue.init(sourceKitRepresentable:)))
		case let value as [String: SourceKitRepresentable]:
			self = .dictionaryValue(value.mapValues({ TypedCodableValue(sourceKitRepresentable: $0) }))
		case let value as String:
			self = .stringValue(value)
		case let value as Int64:
			self = .int64Value(value)
		case let value as Bool:
			self = .boolValue(value)
		default:
			fatalError("Unknown SourceKitRepresentable object")
		}
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		if let leftValue = try? container.decode(String.self, forKey: .stringValue) {
			self = .stringValue(leftValue)
		} else if let rightValue = try? container.decode(Bool.self, forKey: .boolValue) {
			self = .boolValue(rightValue)
		} else if let rightValue = try? container.decode(Float.self, forKey: .floatValue) {
			self = .floatValue(rightValue)
		} else if let rightValue = try? container.decode([TypedCodableValue].self, forKey: .arrayValue) {
			self = .arrayValue(rightValue)
		} else if let rightValue = try? container.decode(Int64.self, forKey: .int64Value) {
			self = .int64Value(rightValue)
		} else if let rightValue = try? container.decode([String: TypedCodableValue].self, forKey: .dictionaryValue) {
			self = .dictionaryValue(rightValue)
		} else {
			throw DecodingError.keyNotFound(CodingKeys.stringValue, DecodingError.Context(codingPath: container.codingPath, debugDescription: ""))
		}
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case .stringValue(let value):
			try container.encode(value, forKey: .stringValue)
		case .boolValue(let value):
			try container.encode(value, forKey: .boolValue)
		case .floatValue(let value):
			try container.encode(value, forKey: .floatValue)
		case .arrayValue(let value):
			try container.encode(value, forKey: .arrayValue)
		case .dictionaryValue(let value):
			try container.encode(value, forKey: .dictionaryValue)
		case .int64Value(let value):
			try container.encode(value, forKey: .int64Value)
		}
	}
	
	enum CodingKeys: String, CodingKey {
		case stringValue
		case boolValue
		case floatValue
		case arrayValue
		case dictionaryValue
		case int64Value
	}
	
}
typealias AnnotationValue = TypedCodableValue
internal typealias Annotations = [String: AnnotationValue]

/// Parser for annotations
internal struct AnnotationsParser {

    private enum AnnotationType {
        case begin(Annotations)
        case annotations(Annotations)
        case end
        case inlineStart
        case file(Annotations)
    }

    private struct Line {
        enum LineType {
            case comment
            case blockStart
            case blockEnd
            case other
            case inlineStart
            case inlineEnd
            case file
        }
        let content: String
        let type: LineType
        let annotations: Annotations
        let blockAnnotations: Annotations
    }

    private let lines: [Line]
    private let contents: String

    /// Initializes parser
    ///
    /// - Parameter contents: Contents to parse
    init(contents: String) {
        self.lines = AnnotationsParser.parse(contents: contents)
        self.contents = contents
    }

    /// returns all annotations in the contents
    var all: Annotations {
        var all = Annotations()
        lines.forEach {
            $0.annotations.forEach {
                AnnotationsParser.append(key: $0.key, value: $0.value, to: &all)
            }
        }
        return all
    }

    /// Extracts annotations from given source
    ///
    /// - Parameter source: Source to extract annotations for.
    /// - Returns: All annotations associated with given source.
    func from(_ source: [String: SourceKitRepresentable]) -> Annotations {
        guard let range = Substring.key.range(for: source),
            let location = contents.location(fromByteOffset: Int(range.offset)),
            let lineInfo = contents.lineAndCharacter(forCharacterOffset: location)
            else { return [:] }

        var stop = false
        var annotations = inlineFrom(line: lineInfo, stop: &stop)
        guard !stop else { return annotations }

        for line in lines[0..<lineInfo.line-1].reversed() {
            line.annotations.forEach { annotation in
                AnnotationsParser.append(key: annotation.key, value: annotation.value, to: &annotations)
            }
            if line.type != .comment {
                break
            }
        }

        return annotations
    }

    func inlineFrom(line lineInfo: (line: Int, character: Int), stop: inout Bool) -> Annotations {
        let sourceLine = lines[lineInfo.line - 1]
        var prefix = sourceLine.content.bridge()
            .substring(to: max(0, lineInfo.character - 1))
            .trimmingCharacters(in: .whitespaces)

        guard !prefix.isEmpty else { return [:] }
        var annotations = sourceLine.blockAnnotations //get block annotations for this line

        // `case` is not included in the key of enum case definition, so we strip it manually
        prefix = prefix.trimmingSuffix("case").trimmingCharacters(in: .whitespaces)

        var inlineCommentFound = false

        while !prefix.isEmpty {
            guard prefix.hasSuffix("*/"), let commentStart = prefix.range(of: "/*", options: [.backwards]) else {
                break
            }

            inlineCommentFound = true

            let comment = String(prefix[commentStart.lowerBound...])
            for annotation in AnnotationsParser.parse(contents: comment)[0].annotations {
                AnnotationsParser.append(key: annotation.key, value: annotation.value, to: &annotations)
            }
            prefix = prefix[..<commentStart.lowerBound].trimmingCharacters(in: .whitespaces)
        }

        if inlineCommentFound && !prefix.isEmpty {
            stop = true
            return annotations
        }

        // if previous line is not comment or has some trailing non-comment blocks
        // we return currently agregated annotations
        // as annotations on previous line belong to previous declaration
        if lineInfo.line - 2 > 0 {
            let previousLine = lines[lineInfo.line - 2]
            let content = previousLine.content.trimmingCharacters(in: .whitespaces)

            guard previousLine.type == .comment, content.hasPrefix("//") || content.hasSuffix("*/") else {
                stop = true
                return annotations
            }
        }

        return annotations
    }

    private static func parse(contents: String) -> [Line] {
        var annotationsBlock: Annotations?
        var fileAnnotationsBlock = Annotations()
        return contents.lines()
                .map { line in
                    let content = line.content.trimmingCharacters(in: .whitespaces)
                    var annotations = Annotations()
                    let isComment = content.hasPrefix("//") || content.hasPrefix("/*") || content.hasPrefix("*")
                    var type: Line.LineType = isComment ? .comment : .other
                    if isComment {
                        switch searchForAnnotations(commentLine: content) {
                        case let .begin(items):
                            type = .blockStart
                            annotationsBlock = Annotations()
                            items.forEach { annotationsBlock?[$0.key] = $0.value }
                        case let .annotations(items):
                            items.forEach { annotations[$0.key] = $0.value }
                        case .end:
                            if annotationsBlock != nil {
                                type = .blockEnd
                                annotationsBlock?.removeAll()
                            } else {
                                type = .inlineEnd
                            }
                        case .inlineStart:
                            type = .inlineStart
                        case let .file(items):
                            type = .file
                            items.forEach {
                                fileAnnotationsBlock[$0.key] = $0.value
                            }
                        }
                    }

                    annotationsBlock?.forEach { annotation in
                        annotations[annotation.key] = annotation.value
                    }

                    fileAnnotationsBlock.forEach { annotation in
                        annotations[annotation.key] = annotation.value
                    }

                    return Line(content: line.content,
                                type: type,
                                annotations: annotations,
                                blockAnnotations: annotationsBlock ?? [:])
                }
    }

    private static func searchForAnnotations(commentLine: String) -> AnnotationType {
        let comment = commentLine.trimmingPrefix("///").trimmingPrefix("//").trimmingPrefix("/**").trimmingPrefix("/*").trimmingPrefix("*").stripped()

        guard comment.hasPrefix("sourcery:") else { return .annotations([:]) }

        if comment.hasPrefix("sourcery:inline:") {
            return .inlineStart
        }

        let lowerBound: String.Index?
        let upperBound: String.Index?
        var insideBlock: Bool = false
        var insideFileBlock: Bool = false

        if comment.hasPrefix("sourcery:begin:") {
            lowerBound = commentLine.range(of: "sourcery:begin:")?.upperBound
            upperBound = commentLine.indices.endIndex
            insideBlock = true
        } else if comment.hasPrefix("sourcery:end") {
            return .end
        } else if comment.hasPrefix("sourcery:file") {
            lowerBound = commentLine.range(of: "sourcery:file:")?.upperBound
            upperBound = commentLine.indices.endIndex
            insideFileBlock = true
        } else {
            lowerBound = commentLine.range(of: "sourcery:")?.upperBound
            if commentLine.hasPrefix("//") || commentLine.hasPrefix("*") {
                upperBound = commentLine.indices.endIndex
            } else {
                upperBound = commentLine.range(of: "*/")?.lowerBound
            }
        }

        if let lowerBound = lowerBound, let upperBound = upperBound {
            let annotations = AnnotationsParser.parse(line: String(commentLine[lowerBound..<upperBound]))
            if insideBlock {
                return .begin(annotations)
            } else if insideFileBlock {
                return .file(annotations)
            } else {
                return .annotations(annotations)
            }
        } else {
            return .annotations([:])
        }
    }

    /// Parses annotations from the given line
    ///
    /// - Parameter line: Line to parse.
    /// - Returns: Dictionary containing all annotations.
    static func parse(line: String) -> Annotations {
        var annotationDefinitions = line.trimmingCharacters(in: .whitespaces)
            .commaSeparated()
            .map { $0.trimmingCharacters(in: .whitespaces) }

        var namespaces = annotationDefinitions[0].components(separatedBy: ":", excludingDelimiterBetween: (open: "\"'", close: "\"'"))
        annotationDefinitions[0] = namespaces.removeLast()

        var annotations = Annotations()
        annotationDefinitions.forEach { annotation in
            let parts = annotation
                .components(separatedBy: "=", excludingDelimiterBetween: ("", ""))
                .map({ $0.trimmingCharacters(in: .whitespaces) })

            if let name = parts.first, !name.isEmpty {

                guard parts.count > 1, var value = parts.last, value.isEmpty == false else {
                    append(key: name, value: .boolValue(true), to: &annotations)
                    return
                }

                if let number = Float(value) {
                    append(key: name, value: .floatValue(number), to: &annotations)
                } else {
                    if (value.hasPrefix("'") && value.hasSuffix("'")) || (value.hasPrefix("\"") && value.hasSuffix("\"")) {
                        value = String(value[value.index(after: value.startIndex) ..< value.index(before: value.endIndex)])
                        value = value.trimmingCharacters(in: .whitespaces)
                    }
					append(key: name, value: .stringValue(value), to: &annotations)
                }
            }
        }

        if namespaces.isEmpty {
            return annotations
        } else {
            var namespaced = Annotations()
            for namespace in namespaces.reversed() {
                namespaced[namespace] = .dictionaryValue(annotations)
                annotations = namespaced
                namespaced = Annotations()
            }
            return annotations
        }
    }

    static func append(key: String, value: AnnotationValue, to annotations: inout Annotations) {
        if let oldValue = annotations[key] {
			switch oldValue {
			case .arrayValue(var current):
				current.append(value)
				annotations[key] = .arrayValue(current)
			case .dictionaryValue(var current):
				switch value {
				case .dictionaryValue(let new):
					new.forEach {
						append(key: $0, value: $1, to: &current)
					}
				default:
					break
				}
				annotations[key] = .dictionaryValue(current)
			default:
				if oldValue != value {
					annotations[key] = .arrayValue([oldValue, value])
				}
			}
        } else {
            annotations[key] = value
        }
    }

}

extension String {

    //! this isn't exposed in SourceKitten so we create our own variant
    func location(fromByteOffset byteOffset: Int) -> Int? {
        let lines = self.lines()
        if lines.isEmpty {
            return 0
        }
        let index = lines.index(where: { NSLocationInRange(byteOffset, $0.byteRange) })
        // byteOffset may be out of bounds when sourcekitd points end of string.
        guard let line = (index.map { lines[$0] } ?? lines.last) else {
            fatalError()
        }
        let diff = byteOffset - line.byteRange.location
        if diff == 0 {
            return line.range.location
        } else if line.byteRange.length == diff {
            return NSMaxRange(line.range)
        }
        let utf8View = line.content.utf8
        guard let endUTF16index = utf8View.index(utf8View.startIndex, offsetBy: diff, limitedBy: utf8View.endIndex)?.samePosition(in: line.content.utf16) else { return nil }
        let utf16Diff = line.content.utf16.distance(from: line.content.utf16.startIndex, to: endUTF16index)
        return line.range.location + utf16Diff
    }

}
