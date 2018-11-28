//
//  TestNSObjectProtocolAliasing.swift
//  LintableProject
//
//  Created by Nikita Patskov on 16/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

private protocol MyProtocol {}
private class MyClass: NSObject, MyProtocol {
}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		return container
	}()
	
	static func load(container: DIContainer) {
		container.register(MyClass.self)
			.as(NSObjectProtocol.self)
	}
	
}
