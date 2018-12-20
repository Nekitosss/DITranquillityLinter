//
//  RegExp.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 12.09.2018.
//  Copyright © 2018 Nikita. All rights reserved.
//


enum RegExp: String {
	case implicitClosureArgument = "\\$[0-9][0-9]?" // $0, $1, $2...
	case forcedType = "\\s[a-zA-Z]+\\s*[}]?$" // as SomeClass
	case trailingTypeInfo = "[a-zA-Z<>\\.]+\\.self\\s*$" // MyType.self
	case nameFromParameterInjection = "\\$0\\.[a-z0-9\\.]+[^= ]" // "$0.name" = $1
	case implicitKeyPath = "\\." // "\."presenter
	case explicitKeyPath = "\\\\[^.]" // "\MyClass".presenter
}
