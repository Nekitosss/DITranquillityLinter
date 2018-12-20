//
//  TestStaticVariableInitialization.swift
//  LintableProject
//
//  Created by Nikita on 12/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

private class MyClass {
	static let staticLet: MyClass = .init()
}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		return container
	}()
	
	static func load(container: DIContainer) {
		container.register { MyClass.staticLet }
	}
	
}
