//
//  TestPlainInjectionValidation.swift
//  LintableProject
//
//  Created by Nikita on 07/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

private protocol MyProtocol {}
private protocol MyProtocol2 {}
private typealias MyProtocolComposition = (MyProtocol & MyProtocol2)
private class MyClass {
	var ss: MyProtocolComposition!
}
private class AnotherClass: MyProtocol, MyProtocol2 {}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		return container
	}()
	
	static func load(container: DIContainer) {
		container.register(AnotherClass.self)
			.as((MyProtocol & MyProtocol2).self)
		
		container.register(MyClass.self)
			.injection { $0.ss = $1 }
	}
	
}
