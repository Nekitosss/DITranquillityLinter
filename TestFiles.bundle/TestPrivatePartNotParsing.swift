//
//  TestFullTypealiasedAliasingSuccess.swift
//  LintableProject
//
//  Created by Nikita on 07/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//


import DITranquillity

private protocol MyProtocol {}
private typealias MyTypealias = MyProtocol
private class MyClass: MyTypealias {
}

class ParsablePart: DIPart {
	
	func load(container: DIContainer) {
		container.register(MyClass.self)
			.as(MyTypealias.self)
	}
	
}
