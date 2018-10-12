import XCTest
@testable import DITranquillityLinterFramework

final class ParserTests: XCTestCase {
	
	
	static var allTests = [
		("testDefaultMakingRegistration", testDefaultMakingRegistration),
		]
	
	// .default()
	func testDefaultMakingRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestDefaultMakingRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let containsDefault = registration.tokenList.contains(where: { $0 is IsDefaultToken })
		XCTAssertTrue(containsDefault, "Could not parse '.default()' token")
	}

	// register{ MyClass<Float>() }
	func testExplicitGenericInitRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestExplicitGenericInitRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass<Float>")
		XCTAssertEqual(registration.plainTypeName, "MyClass")
	}
	
	// register{ MyClass.init() }
	func testExplicitInitRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestExplicitInitRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass")
	}
	
	// .injection(\MyClass.variable)
	func testExplicitKeyPathRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestExplicitKeyPathInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// func injectArgument(arg: T) where T is class generic, not method
	func testGenericArgumentMethodInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestGenericArgumentMethodInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// class MyClass<T> { var ss: T! }
	func testGenericArgumentVariableInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestGenericArgumentVariableInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// register{ MyClass() }
	func testImplicitDroppedInitRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestImplicitDroppedInitRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass")
	}
	
	// register(MyClass.init)
	func testImplicitInitRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestImplicitInitRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(registration.typeName, "MyClass")
		XCTAssertEqual(injection.name, "string")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// .injection(\.variable)
	func testImplicitKeyPathInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestImplicitKeyPathInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// .inject { $0.injectSs(ss: $1) }
	func testMethodInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestMethodInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// register(MyClass.NestedClass.self)
	func testNestedClassPlainRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestNestedClassPlainRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass.NestedClass")
	}
	
	// register { MyClass.Nested<Float>() }
	func testNestedExplicitGenericInitRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestNestedExplicitGenericInitRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass.Nested<Float>")
		XCTAssertEqual(registration.plainTypeName, "MyClass.Nested")
	}
	
	// .register(MyClass.NestedClass<String>.self)
	func testNestedGenericClassRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestNestedGenericClassRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass.NestedClass<String>")
		XCTAssertEqual(registration.plainTypeName, "MyClass.NestedClass")
	}
	
	// .register1 { MyClass.Nested(string: $0, int: 55) }
	func testNotAllVariablesInjectionInMethod() throws {
		let containerInfo = try findContainerStructure(fileName: "TestNotAllVariablesInjectionInMethod")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(registration.typeName, "MyClass.Nested")
		XCTAssertEqual(injection.name, "string")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// .as(MyProtocol.self)
	func testPlainAliasing() throws {
		let containerInfo = try findContainerStructure(fileName: "TestPlainAliasing")
		// maximumRegistrationCount = 2 cause for extra alias
		let registration = try extractRegistrationInfo(containerInfo: containerInfo, maximumRegistrationCount: 2)
		let alias = try extractAliasInfo(registrationToken: registration)
		XCTAssertEqual(alias.typeName, "MyProtocol")
	}
	
	// .register(MyClass<Float>.self)
	func testPlainGenericRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestPlainGenericRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass<Float>")
		XCTAssertEqual(registration.plainTypeName, "MyClass")
	}
	
	// .register(MyClass.self)
	func testPlainRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestPlainRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass")
	}
	
	// .injection { $0.ss = $1 }2
	func testPlainVariableInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestPlainVariableInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// .as(MyProtocol.self, tag: MyTag.self)
	func testTaggedAliasing() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTaggedAliasing")
		// maximumRegistrationCount = 2 cause for extra alias
		let registration = try extractRegistrationInfo(containerInfo: containerInfo, maximumRegistrationCount: 2)
		let alias = try extractAliasInfo(registrationToken: registration)
		XCTAssertEqual(alias.typeName, "MyProtocol")
		XCTAssertEqual(alias.tag, "MyTag")
	}
	
	// .injection(\.ss) { by(tag: MyTag.self, on: $0) }
	func testTaggedModificatorKeyPathInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTaggedModificatorKeyPathInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.tag, "MyTag")
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "MyProtocol")
	}
	
	// .injection { $0.ss = by(tag: MyTag.self, on: $1) as String }
	func testTypedAndTaggedVariableInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTypedAndTaggedVariableInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
		XCTAssertEqual(injection.tag, "MyTag")
	}
	
	// .injection { $0.ss = $1 as String }
	func testTypedVariableInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTypedVariableInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// let r = container.register(MyClass.self)
	// r.as(MyProtocol.self)
	func testVariableUsedRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestVariableUsedRegistration")
		// maximumRegistrationCount = 2 cause for extra alias
		let registration = try extractRegistrationInfo(containerInfo: containerInfo, maximumRegistrationCount: 2)
		let alias = try extractAliasInfo(registrationToken: registration)
		XCTAssertEqual(alias.typeName, "MyProtocol")
	}
	
	// .injection(cycle: true, \MyClass.ss)
	func testCycleRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestCycleRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertTrue(injection.cycle)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// container.register(MyClass.self)
	// container.register(MySecondClass.self)
	func testSeveralRegistrations() throws {
		let containerInfo = try findContainerStructure(fileName: "TestSeveralRegistrations")
		XCTAssertEqual(containerInfo.tokenInfo.count, 2)
		let registrations = containerInfo.tokenInfo.values.flatMap({ $0 })
		XCTAssertEqual(registrations.count, 2)
		
		// Important to have two different registrations
		let firstTypeName = registrations[0].typeName
		let secondTypeName = registrations[1].typeName
		XCTAssertNotEqual(firstTypeName, secondTypeName)
		let testRegistrationName: (String) -> Bool = {
			$0 == "MyClass" || $0 == "MySecondClass"
		}
		XCTAssertTrue(testRegistrationName(firstTypeName))
		XCTAssertTrue(testRegistrationName(secondTypeName))
	}
	
	// class ParsablePart: DIPart
	// class SecondParsablePart: DIPart
	// class ThirdParsablePart: DIFramework
	func testSeveralDIParts() throws {
		let containerInfo = try findContainerStructure(fileName: "TestSeveralDIParts")
		XCTAssertEqual(containerInfo.tokenInfo.count, 3)
		let registrations = containerInfo.tokenInfo.values.flatMap({ $0 })
		XCTAssertEqual(registrations.count, 3)
		let nameSet = Set(registrations.map({ $0.typeName }))
		XCTAssertEqual(nameSet.count, 3, "We should have 3 different registrations")
	}
	
	// .register1{ MyClass<String>.init(ss: $0) }
	func testExplicitClosureGenericInitializerInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestExplicitClosureGenericInitializerInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(registration.typeName, "MyClass<String>")
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// .register1{ MyClass<String>(ss: $0) }
	func testImplicitClosureGenericInitializerInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestImplicitClosureGenericInitializerInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(registration.typeName, "MyClass<String>")
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// .register1(MyClass<String>.init)
	func testImplicitPlainGenericInitializerInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestImplicitPlainGenericInitializerInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(registration.typeName, "MyClass<String>")
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// .register1 { MyClass<String>.init(ss: by(tag: MyTag.self, on: $0)) }
	func testTaggedInitializerInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTaggedInitializerInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.tag, "MyTag")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// .register1 { MyClass(ss: $0 as MyAnotherClass) }
	func testTypedInitializerInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTypedInitializerInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.typeName, "MyAnotherClass")
		XCTAssertEqual(registration.typeName, "MyClass")
	}
	
	// .register1 { MyChild(ss: $0) } where .init(ss:) contains in MyParent
	func testInheritedInitializerInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestInheritedInitializerInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(registration.typeName, "MyChild")
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "MyProtocol")
	}
	
	// .injection { $0.ss = $1 } where ss contains in MyParent
	func testInheritedVariableInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestInheritedVariableInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// .injection { $0.inject(ss: $1) } where .inject(ss:) contains in MyParent
	func testInheritedMethodInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestInheritedMethodInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertTrue(injection.methodInjection)
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// .as((MyProtocol & MyProtocol2).self)
	func testProtocolCompositionAliasing() throws {
		let containerInfo = try findContainerStructure(fileName: "TestProtocolCompositionAliasing")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo, maximumRegistrationCount: 2)
		let alias = try extractAliasInfo(registrationToken: registration)
		XCTAssertEqual(alias.typeName, "MyProtocol & MyProtocol2")
	}
	
	// .as(MyProtocolComposition.self) where MyProtocolComposition = (MyProtocol & MyProtocol2)
	func testWrappedProtocolCompositionAliasing() throws {
		let containerInfo = try findContainerStructure(fileName: "TestWrappedProtocolCompositionAliasing")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo, maximumRegistrationCount: 2)
		let alias = try extractAliasInfo(registrationToken: registration)
		XCTAssertEqual(alias.typeName, "MyProtocol & MyProtocol2")
	}
	
	// .as(MyProtocolTypealias.self) where MyProtocolTypealias = MyProtocol
	func testTypealiasedRegistrationAliasing() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTypealiasedRegistrationAliasing")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo, maximumRegistrationCount: 2)
		let alias = try extractAliasInfo(registrationToken: registration)
		XCTAssertEqual(alias.typeName, "MyProtocol")
	}
	
	// .register(MyClassTypealias.self) where MyClassTypealias = MyClass
	func testTypealiasedClassRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTypealiasedClassRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass")
	}
	
	// .injection { $0.ss = $1 } where ss: MyTypealias, MyTypealias = AnotherClass
	func testTypealiasedVariableInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTypealiasedVariableInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "AnotherClass")
	}
	
	// .injection { $0.injectSs(ss: $1) } where ss: MyTypealias, MyTypealias = AnotherClass
	func testTypealiasedMethodInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTypealiasedMethodInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "AnotherClass")
	}
	
	// .injection { $0.injectSs(ss: $1) } where ss: MyTypealias, MyTypealias = (MyProtocol & MyProtocol2)
	func testTypealiasedCompositionedMethodInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTypealiasedCompositionedMethodInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "MyProtocol & MyProtocol2")
	}
	
	// .injection { $0.ss = $1 } where ss: MyTypealias, MyTypealias = (MyProtocol & MyProtocol2)
	func testTypealiasedCompositionedVariableInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTypealiasedCompositionedVariableInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "MyProtocol & MyProtocol2")
	}
	
	func testGenericVariableInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestGenericVariableInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "MyGeneric<String>")
		XCTAssertEqual(injection.plainTypeName, "MyGeneric")
	}
	
	func testGenericMethodInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestGenericMethodInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "MyGeneric<String>")
		XCTAssertEqual(injection.plainTypeName, "MyGeneric")
	}
	
	func testStaticVariableRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestStaticVariableRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass")
	}
	
}
