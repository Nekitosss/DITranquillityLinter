//
//  TestFullTypealiasedAliasingSuccess.swift
//  LintableProject
//
//  Created by Nikita on 07/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//


import DITranquillity

private class MyUsingClass {
	let otherModuleProtocolInject: MyProtocol
	
	init(otherModuleProtocolInject: MyProtocol) {
		self.otherModuleProtocolInject = otherModuleProtocolInject
	}
}

class ParsableUsagePart: DIPart {
	
	let container: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		container.append(part: ParsableUsagePart.self)
		return container
	}()
	
	func load(container: DIContainer) {
		container.register1(MyUsingClass.init)
	}
	
}