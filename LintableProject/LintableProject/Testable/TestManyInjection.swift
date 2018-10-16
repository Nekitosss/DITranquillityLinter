//
//  TestManyInjection.swift
//  LintableProject
//
//  Created by Nikita Patskov on 16/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

private protocol MyProtocol {}
extension String: MyProtocol {}
private class MyTag {}
private class MyClass {
	var ss: [MyProtocol]!
}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let container = DIContainer()
		container.register(MyClass.self)
			.injection(\.ss) { many($0) }
		return container
	}()
	
	static func load(container: DIContainer) {
	}
	
}
