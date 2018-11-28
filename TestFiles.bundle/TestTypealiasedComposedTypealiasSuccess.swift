//
//  TestTypealiasedComposedTypealiasSuccess.swift
//  LintableProject
//
//  Created by Nikita on 07/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

private protocol MyProtocol {}
private protocol MySecondProtocol {}
private typealias MyTypealias = MyProtocol & MySecondProtocol
private class MyClass: MyTypealias {
}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		return container
	}()
	
	static func load(container: DIContainer) {
		container.register(MyClass.self)
			.as((MyProtocol & MySecondProtocol).self)
	}
	
}
