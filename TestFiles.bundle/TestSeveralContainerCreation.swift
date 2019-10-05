import DITranquillity

private class MyClass {
}

private class ParsablePart: DIPart {
	
	static let container1: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		return container
	}()
	
	static let container2: DIContainer = {
		let container = DIContainer()
		container.append(part: ParsablePart.self)
		return container
	}()
	
	static func load(container: DIContainer) {
		container.register(MyClass.self)
			.default()
		container.register(MyClass.self)
			.default()
	}
	
}
