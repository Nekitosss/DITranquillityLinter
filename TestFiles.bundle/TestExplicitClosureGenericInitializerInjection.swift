//
//  TestExplicitGenericInitializerInjection.swift
//  LintableProject
//
//  Created by Nikita Patskov on 04/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

private class MyClass<T> {
	init(ss: T) {}
}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		return container
	}()
	
	static func load(container: DIContainer) {
		container.register{ MyClass<String>.init(ss: $0) }
	}
	
}
