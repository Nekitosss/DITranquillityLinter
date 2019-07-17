//
//  TestImplicitInitRegistration.swift
//  LintableProject
//
//  Created by Nikita Patskov on 01/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

private class MyClass {
	init(string: String) {
		
	}
}

private class ParsablePart: DIPart {
	
	static func load(container: DIContainer) {
		container.register(MyClass.init)
	}
	
	static let container: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		return container
	}()
	
}

