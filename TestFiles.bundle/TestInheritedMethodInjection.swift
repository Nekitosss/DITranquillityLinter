//
//  TestInheritedMethodInjection.swift
//  LintableProject
//
//  Created by Nikita Patskov on 04/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import DITranquillity

private class MyChild: MyClass {}
private class MyClass {
	func inject(ss: String) {}
}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		return container
	}()
	
	static func load(container: DIContainer) {
		container.register(MyChild.self)
			.injection { $0.inject(ss: $1) }
	}
	
}
