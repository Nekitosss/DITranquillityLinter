//
//  TestTypealiasedVariableRegistration.swift
//  LintableProject
//
//  Created by Nikita on 06/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

private class AnotherClass {}
private typealias MyTypealias = AnotherClass
private class MyClass {
	func injectSs(ss: MyTypealias) {}
}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		return container
	}()
	
	static func load(container: DIContainer) {
		container.register(MyClass.self)
			.injection { $0.injectSs(ss: $1) }
	}
	
}
