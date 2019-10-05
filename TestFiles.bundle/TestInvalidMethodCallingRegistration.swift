//
//  TestInvalidMethodCallingRegistration.swift
//  LintableProject
//
//  Created by Nikita Patskov on 16/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

private class MyClass2 {
}

private class ParsablePart2: DIPart {
	
	static let container: DIContainer = {
		let cont = DIContainer()
		cont.append(part: ParsablePart2.self)
		return cont
	}()
	
	static func load(container: DIContainer) {
    invalidInjectionMethod(container, str: "")
	}
	
  static func invalidInjectionMethod(_ c: DIContainer, str: String) {
		c.register(MyClass2.init)
	}
}
