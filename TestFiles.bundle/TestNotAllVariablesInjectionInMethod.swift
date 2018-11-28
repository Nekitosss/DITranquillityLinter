//
//  TestNotAllVariablesInjectionInMethod.swift
//  LintableProject
//
//  Created by Nikita Patskov on 01/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

private class MyClass {
	class Nested {
		init(string: String, int: Int) {}
	}
}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		return container
	}()
	
	static func load(container: DIContainer) {
		container.register1 { MyClass.Nested(string: $0, int: 55) }
	}
	
}
