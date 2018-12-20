//
//  TestNestedTypealiasedClassRegistration.swift
//  LintableProject
//
//  Created by Nikita Patskov on 18/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation

import DITranquillity

private class MyClass {}
private class AnotherClass {
	typealias MyClassTypealias = MyClass
}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		return container
	}()
	
	static func load(container: DIContainer) {
		container.register(AnotherClass.MyClassTypealias.self)
	}
	
}
