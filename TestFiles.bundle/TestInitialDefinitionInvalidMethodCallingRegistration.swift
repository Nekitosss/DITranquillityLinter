//
//  TestInitialDefinitionInvalidMethodCallingRegistration.swift
//  LintableProject
//
//  Created by Nikita Patskov on 16/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

private class MyClass {
}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let cont = DIContainer()
		invalidInjectionMethod(c: cont)
		return cont
	}()
	
	static func load(container: DIContainer) {
		
	}
	
	static func invalidInjectionMethod(c: DIContainer) {
		c.register(MyClass.init)
	}
}
