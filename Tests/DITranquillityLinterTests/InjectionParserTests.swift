

import XCTest
@testable import DITranquillityLinterFramework


class InjectionParserTests: XCTestCase {
	
	override func tearDown() {
		clearTestArtifacts()
	}
	
	// .injection(\MyClass.variable)
	func testExplicitKeyPathInjection() throws {
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
	
	// .injection { $0.ss = $1 }
	func testPlainVariableInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestPlainVariableInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// .register { MyChild(ss: $0) } where .init(ss:) contains in MyParent
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
	
	// .injection { $0.ss = $1 } where ss: MyGeneric<String>!
	func testGenericVariableInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestGenericVariableInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "MyGeneric<String>")
		XCTAssertEqual(injection.plainTypeName, "MyGeneric")
	}
	
	// .injection { $0.inject(ss: $1) } where func inject(ss: MyGeneric<String>!)
	func testGenericMethodInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestGenericMethodInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "MyGeneric<String>")
		XCTAssertEqual(injection.plainTypeName, "MyGeneric")
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
	
	// .injection { $0.ss = $1 } where ss: NestedClass, NestedClass contains in MyClass
	func testNestedClassVariableInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestNestedClassVariableInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "MyClass.NestedClass")
	}
	
	// .injection { $0.injectSS(ss: $1) } where ss: NestedClass, NestedClass contains in MyClass
	func testNestedClassMethodInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestNestedClassMethodInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "MyClass.NestedClass")
	}
	
}
