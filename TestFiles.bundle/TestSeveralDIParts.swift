//
//  TestSeveralDIParts.swift
//  LintableProject
//
//  Created by Nikita Patskov on 02/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

private class MyClass {
	var ss: String!
}
private class MySecondClass {}
private class MyThirdClass {}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let container = DIContainer()
		container
			.append(part: ParsablePart.self)
			.append(part: SecondParsablePart.self)
		return container
	}()
	
	static func load(container: DIContainer) {
		container.register(MyClass.self)
		container.append(framework: ThirdParsablePart.self)
	}
	
}


private class SecondParsablePart: DIPart {
	static func load(container: DIContainer) {
		container.register(MySecondClass.self)
	}
}

private class ThirdParsablePart: DIFramework {
	static func load(container: DIContainer) {
		container.register(MyThirdClass.self)
	}
}
