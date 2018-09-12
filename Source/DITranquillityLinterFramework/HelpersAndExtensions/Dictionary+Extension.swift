//
//  Dictionary+Extension.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 12.09.2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework

typealias SourceKitObject = [String: SourceKitRepresentable]

extension Dictionary where Value == SourceKitRepresentable, Key == String  {
	
	func get<T>(_ key: SwiftDocKey, of type: T.Type = T.self) -> T? {
		return self[key.rawValue] as? T
	}
	
	var substructures: [SourceKitObject]? {
		return get(.substructure)
	}
	
}
