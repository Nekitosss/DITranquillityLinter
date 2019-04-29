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

public class ParsablePart: DIPart {
	
	public func load(container: DIContainer) {
		container.register(MyClass.self)
			.as(MyTypealias.self)
		container.append(part: SecondPart.self)
	}
	
}

class SecondPart: DIPart {
	func load(container: DIContainer) {
		container.append(part: ThirdPart.self)
	}
}


class ThirdPart: DIPart {
	func load(container: DIContainer) {
		container.append(part: ParsablePart.self)
	}
}
