//
//  IsDefaultTokenBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 01/10/2018.
//

import Foundation
import SourceKittenFramework

/// Trying to create IsDefaultToken
final class IsDefaultTokenBuilder: TokenBuilder {
	
	func build(using info: TokenBuilderInfo) -> DIToken? {
		guard info.functionName == DIKeywords.default.rawValue else { return nil }
		return IsDefaultToken()
	}
	
}
