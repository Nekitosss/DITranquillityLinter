//
//  TestExplicitInitRegistration.swift
//  LintableProject
//
//  Created by Nikita Patskov on 01/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

private class MyClass: MyAlias {
}
protocol MyAlias {}

private class MyClass2 {
	init(myClass: MyAlias) {
		
	}
}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		return container
	}()
	
	static func load(container: DIContainer) {
		container.register(MyClass.init)
			.as(check: MyAlias.self) {$0}
		container.register(MyClass2.init)
	}
	
}
