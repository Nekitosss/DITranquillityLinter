//
//  TestNestedClassMethodInjection.swift
//  LintableProject
//
//  Created by Nikita Patskov on 18/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

private class MyClass {
	class NestedClass {
		
	}
	
	func injectSS(ss: NestedClass) {}
}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		return container
	}()
	
	static func load(container: DIContainer) {
		container.register(MyClass.self)
			.injection { $0.injectSS(ss: $1) }
	}
	
}
