//
//  TestVariableUsedRegistration.swift
//  LintableProject
//
//  Created by Nikita Patskov on 01/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

private protocol MyProtocol {}
private class MyClass {
}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		return container
	}()
	
	static func load(container: DIContainer) {
		let r = container.register(MyClass.self)
		r.as(MyProtocol.self)
	}
	
}
