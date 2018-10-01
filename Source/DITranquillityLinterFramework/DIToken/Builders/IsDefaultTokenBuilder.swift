//
//  IsDefaultTokenBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 01/10/2018.
//

import Foundation
import SourceKittenFramework

final class IsDefaultTokenBuilder {
	
	static func build(functionName: String, invocationBody: String, bodyOffset: Int64, file: File) -> IsDefaultToken? {
		guard functionName == DIKeywords.default.rawValue else { return nil }
		return IsDefaultToken()
	}
	
}
