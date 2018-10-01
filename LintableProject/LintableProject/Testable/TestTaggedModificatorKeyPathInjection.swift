//
//  TestTaggedModificatorKeyPathInjection.swift
//  LintableProject
//
//  Created by Nikita Patskov on 01/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

private protocol MyProtocol {}
extension String: MyProtocol {}
private class MyTag {}
private class MyClass {
	var ss: MyProtocol!
}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		return container
	}()
	
	static func load(container: DIContainer) {
		container.register(MyClass.self)
			.injection(\.ss) { by(tag: MyTag.self, on: $0) }
	}
	
}
