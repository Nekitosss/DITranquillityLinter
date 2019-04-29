//
//  TestFullTypealiasedAliasingSuccess.swift
//  LintableProject
//
//  Created by Nikita on 07/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//


import DITranquillity

public protocol MyProtocol {}
private typealias MyTypealias = MyProtocol
private class MyClass: MyTypealias {
}

public class ParsablePart: DIPart {
	
	public func load(container: DIContainer) {
		container.register(MyClass.self)
			.as(MyTypealias.self)
	}
	
}
