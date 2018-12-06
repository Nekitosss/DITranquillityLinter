//
//  Location.swift
//  DITranquillityLinter
//
//  Created by Nikita Patskov on 12.09.2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct Location: CustomStringConvertible, Equatable {
	public let file: String?
	public let line: Int?
	public let character: Int?
	public var description: String {
		// Xcode likes warnings and errors in the following format:
		// {full_path_to_file}{:line}{:character}: {error,warning}: {content}
		let fileString: String = file ?? "<nopath>"
		let lineString: String = ":\(line ?? 1)"
		let charString: String = character.map({ ":\($0)" }) ?? ""
		return [fileString, lineString, charString].joined()
	}
	
	public init(file: String?, line: Int? = nil, character: Int? = nil) {
		self.file = file
		self.line = line
		self.character = character
	}
	
	public init(file: File, byteOffset offset: Int64) {
		self.file = file.path
		if let lineAndCharacter = file.contents.bridge().lineAndCharacter(forByteOffset: Int(offset)) {
			line = lineAndCharacter.line
			character = lineAndCharacter.character
		} else {
			line = nil
			character = nil
		}
	}
}

public func == (lhs: Location, rhs: Location) -> Bool {
	return lhs.file == rhs.file &&
		lhs.line == rhs.line &&
		lhs.character == rhs.character
}
