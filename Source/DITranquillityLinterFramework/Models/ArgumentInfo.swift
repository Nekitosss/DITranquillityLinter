//
//  ArgumentInfo.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 03/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework

struct ArgumentInfo {
	let name: String
	let value: String
	let structure: [String: SourceKitRepresentable]
}
