//
//  TestGenericMethodInjection.swift
//  LintableProject
//
//  Created by Nikita on 12/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

private class MyGeneric<T> {}
private class MyClass {
	func inject(ss: MyGeneric<String>!) {}
}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		return container
	}()
	
	static func load(container: DIContainer) {
		container.register(MyClass.self)
			.injection { $0.inject(ss: $1) }
	}
	
}
