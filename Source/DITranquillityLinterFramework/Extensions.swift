//
//  Extensions.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 03/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension NSString {
	func substringUsingByteRange(start: Int64, length: Int64) -> String? {
		return self.substringWithByteRange(start: Int(start), length: Int(length))
	}
}
