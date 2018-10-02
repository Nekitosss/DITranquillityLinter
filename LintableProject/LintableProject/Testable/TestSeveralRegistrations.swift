//
//  TestSeveralRegistrations.swift
//  LintableProject
//
//  Created by Nikita Patskov on 02/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

private class MyClass {
	var ss: String!
}
private class MySecondClass {}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		return container
	}()
	
	static func load(container: DIContainer) {
		container.register(MyClass.self)
			.injection(\.ss)
		
		container.register(MySecondClass.self)
	}
	
}
