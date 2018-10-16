//
//  SHA256.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 16/10/2018.
//

import Foundation
import Basic

class SHA256 {
	
	static func get(from source: String) -> String {
		return Basic.SHA256(source).digestString()
	}
	
}
