//
//  IsDefaultTokenBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 01/10/2018.
//

import Foundation

/// Trying to create IsDefaultToken
final class IsDefaultTokenBuilder: TokenBuilder {
	
	func build(using info: TokenBuilderInfo) -> DITokenConvertible? {
		guard info.functionName == DIKeywords.default.rawValue else { return nil }
		return IsDefaultToken()
	}
	
}
